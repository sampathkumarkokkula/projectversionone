-- =============================================================================
-- BVM v4: per-account rate limits. Apply after v1-v3 (SQL editor: paste and
-- run). Safe to re-run.
--
-- Slows down username enumeration, one-time-key exhaustion, relay flooding,
-- report abuse and backup churn. The limits are far above normal use; a
-- client over a limit gets SQLSTATE BVM05 and retries later (queued messages
-- stay in the phone's outbox).
--
--   action             limit         used by
--   lookup             200 / hour    lookup_user, username_available
--   claim              200 / hour    claim_one_time_key (all targets)
--   claim:<user id>     20 / hour    claim_one_time_key (one target)
--   send              3000 / hour    relay_send (a photo is ~10 parts)
--   report              20 / day     report_spam
--   backup              60 / hour    put_account_backup
--
-- The counters hold only a user id, an action name and a count; rows older
-- than two days are purged daily and all rows go with the account.
-- =============================================================================

create table if not exists private.rate_limits (
  user_id      uuid not null references auth.users (id) on delete cascade,
  action       text not null,
  window_start timestamptz not null default now(),
  hits         integer not null default 0,
  primary key (user_id, action)
);
alter table private.rate_limits enable row level security;

-- Fixed-window counter. Raises BVM05 once p_limit calls were made within
-- p_window. The failed call's increment is rolled back with it, so a client
-- that keeps retrying does not extend its own block.
create or replace function private.hit_rate_limit(p_uid uuid, p_action text, p_limit integer, p_window interval)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_hits integer;
begin
  if p_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  insert into private.rate_limits as r (user_id, action, window_start, hits)
  values (p_uid, p_action, now(), 1)
  on conflict (user_id, action) do update
    set hits = case when r.window_start < now() - p_window then 1 else r.hits + 1 end,
        window_start = case when r.window_start < now() - p_window then now() else r.window_start end
  returning r.hits into v_hits;
  if v_hits > p_limit then
    raise exception 'too many requests, try again later' using errcode = 'BVM05';
  end if;
end
$$;
revoke all on function private.hit_rate_limit(uuid, text, integer, interval) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Directory lookups (now volatile: they write the counter).
-- ---------------------------------------------------------------------------
create or replace function public.username_available(p_username text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  perform private.hit_rate_limit(auth.uid(), 'lookup', 200, interval '1 hour');
  if p_username is null or p_username !~ '^[a-z0-9_]{3,24}$' then
    return false;
  end if;
  return not exists (select 1 from public.users u where u.username = p_username);
end
$$;

create or replace function public.lookup_user(p_username text)
returns table (id uuid, username text, identity_key text, signing_key text)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  perform private.hit_rate_limit(auth.uid(), 'lookup', 200, interval '1 hour');
  return query
    select u.id, u.username, u.identity_key, u.signing_key
      from public.users u
     where u.username = lower(trim(p_username))
       and u.suspended_at is null;
end
$$;

-- ---------------------------------------------------------------------------
-- One-time keys: a total and a per-target limit, so one account cannot
-- drain someone's keys (the signed fallback key keeps sessions possible).
-- ---------------------------------------------------------------------------
create or replace function public.claim_one_time_key(p_user_id uuid)
returns table (key_id text, public_key text, signature text, is_fallback boolean)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_row public.one_time_keys%rowtype;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'cannot claim your own keys' using errcode = '22023';
  end if;
  perform private.assert_not_suspended(auth.uid());
  perform private.hit_rate_limit(auth.uid(), 'claim', 200, interval '1 hour');
  perform private.hit_rate_limit(auth.uid(), 'claim:' || p_user_id::text, 20, interval '1 hour');

  delete from public.one_time_keys k
   where k.id = (
     select k2.id from public.one_time_keys k2
      where k2.user_id = p_user_id
      order by k2.id
      limit 1
      for update skip locked
   )
  returning k.* into v_row;

  if v_row.id is not null then
    return query select v_row.key_id, v_row.public_key, v_row.signature, false;
    return;
  end if;

  return query
    select u.fallback_key->>'id', u.fallback_key->>'key', u.fallback_key->>'sig', true
      from public.users u
     where u.id = p_user_id and u.fallback_key is not null;
end
$$;

-- ---------------------------------------------------------------------------
-- Relay
-- ---------------------------------------------------------------------------
create or replace function public.relay_send(
  p_device_key text,
  p_id         uuid,
  p_recipient  uuid,
  p_type       text,
  p_ciphertext text,
  p_expires_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  perform private.assert_current_device(v_uid, p_device_key);
  perform private.assert_not_suspended(v_uid);
  if p_id is null or p_recipient is null then
    raise exception 'missing id or recipient' using errcode = '22023';
  end if;
  perform private.hit_rate_limit(v_uid, 'send', 3000, interval '1 hour');
  if exists (select 1 from private.blocks b where b.blocker_id = p_recipient and b.blocked_id = v_uid) then
    return;
  end if;
  insert into public.relay (id, recipient_id, sender_id, type, ciphertext, expires_at)
  values (p_id, p_recipient, v_uid, p_type, p_ciphertext, p_expires_at)
  on conflict (id) do nothing;
end
$$;

-- ---------------------------------------------------------------------------
-- Spam reports
-- ---------------------------------------------------------------------------
create or replace function public.report_spam(p_device_key text, p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid();
  v_reports integer;
begin
  perform private.assert_current_device(v_uid, p_device_key);
  perform private.hit_rate_limit(v_uid, 'report', 20, interval '1 day');
  perform public.block_user(p_device_key, p_user);
  insert into private.spam_reports (reporter_id, reported_id)
  select v_uid, p_user where exists (select 1 from auth.users au where au.id = p_user)
  on conflict (reporter_id, reported_id) do update set created_at = now();

  select count(*) into v_reports
    from private.spam_reports s
    join public.users reporter on reporter.id = s.reporter_id
   where s.reported_id = p_user
     and s.created_at > now() - interval '30 days'
     and reporter.created_at < now() - interval '1 day';

  if v_reports >= 5 then
    update public.users set suspended_at = now()
     where id = p_user and suspended_at is null;
    if found then
      perform private.block_email((select au.email from auth.users au where au.id = p_user), 'spam');
      delete from public.one_time_keys where user_id = p_user;
    end if;
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- Account backup
-- ---------------------------------------------------------------------------
create or replace function public.put_account_backup(p_device_key text, p_copy_a text, p_copy_b text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  perform private.assert_current_device(v_uid, p_device_key);
  perform private.hit_rate_limit(v_uid, 'backup', 60, interval '1 hour');
  if p_copy_a is null or p_copy_b is null or length(p_copy_a) < 64 or length(p_copy_b) < 64 then
    raise exception 'invalid backup' using errcode = '22023';
  end if;
  insert into private.account_backups (user_id, copy_a, copy_b)
  values (v_uid, p_copy_a, p_copy_b)
  on conflict (user_id) do update
    set copy_a = excluded.copy_a, copy_b = excluded.copy_b, updated_at = now();
end
$$;

-- ---------------------------------------------------------------------------
-- Daily purge of old counters.
-- ---------------------------------------------------------------------------
select cron.schedule(
  'bvm-rate-limit-purge',
  '17 3 * * *',
  $$delete from private.rate_limits where window_start < now() - interval '2 days'$$
);
