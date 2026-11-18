-- =============================================================================
-- BVM v5: bounded server storage for undelivered messages. Apply after v1-v4
-- (SQL editor: paste and run). Safe to re-run.
--
-- When a recipient does not open the app, envelopes wait on the server. To
-- keep that bounded:
--
--   * Inbox quota: at most 10 MB of waiting messages/photos per recipient and
--     3 MB from any one sender to one recipient. Over the quota relay_send
--     fails with SQLSTATE BVM06; the sender's phone keeps the message in its
--     own outbox and retries later, so nothing is lost and the waiting data
--     sits on the sender's phone instead of the server.
--   * Small control envelopes (receipts) expire after 3 days; text after
--     30 days and photo parts after 7 days as before (photos: set by the app).
--   * Envelopes for accounts whose phone has not fetched for 30 days are
--     purged, together with the TTL job.
--
-- Control envelopes ('delete', 'timer_change') are tiny and exempt from the
-- quota so a wipe or delete command always gets through (they are still rate
-- limited by v4).
-- =============================================================================

alter table public.users add column if not exists last_fetch_at timestamptz;

create or replace function private.assert_inbox_space(p_sender uuid, p_recipient uuid, p_bytes integer)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_total bigint;
  v_pair  bigint;
begin
  select coalesce(sum(octet_length(r.ciphertext)), 0),
         coalesce(sum(octet_length(r.ciphertext)) filter (where r.sender_id = p_sender), 0)
    into v_total, v_pair
    from public.relay r
   where r.recipient_id = p_recipient and r.type = 'message';
  if v_total + p_bytes > 10485760 or v_pair + p_bytes > 3145728 then
    raise exception 'the recipient''s inbox is full, try again later' using errcode = 'BVM06';
  end if;
end
$$;
revoke all on function private.assert_inbox_space(uuid, uuid, integer) from public, anon, authenticated;

-- Receipts live 3 days at most; everything else keeps the v1 clamp.
create or replace function private.relay_before_insert()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_max interval := case when new.type = 'receipt' then interval '3 days' else interval '30 days' end;
begin
  new.created_at := now();
  if new.expires_at is null or new.expires_at > now() + v_max then
    new.expires_at := now() + v_max;
  elsif new.expires_at < now() + interval '1 minute' then
    new.expires_at := now() + interval '1 minute';
  end if;
  return new;
end
$$;
revoke all on function private.relay_before_insert() from public, anon, authenticated;

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
  -- A retry of an envelope that is already stored is a no-op, not a quota hit.
  if exists (select 1 from public.relay r where r.id = p_id) then
    return;
  end if;
  if p_type = 'message' then
    perform private.assert_inbox_space(v_uid, p_recipient, octet_length(coalesce(p_ciphertext, '')));
  end if;
  insert into public.relay (id, recipient_id, sender_id, type, ciphertext, expires_at)
  values (p_id, p_recipient, v_uid, p_type, p_ciphertext, p_expires_at)
  on conflict (id) do nothing;
end
$$;

-- Same as v1, plus the last-fetch time used by the inactive-inbox purge.
create or replace function public.relay_fetch(p_device_key text, p_limit integer default 100)
returns table (id uuid, sender_id uuid, type text, ciphertext text)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid();
begin
  perform private.assert_current_device(v_uid, p_device_key);
  update public.users u set last_fetch_at = now()
   where u.id = v_uid and (u.last_fetch_at is null or u.last_fetch_at < now() - interval '1 hour');
  return query
    select r.id, r.sender_id, r.type, r.ciphertext
      from public.relay r
     where r.recipient_id = v_uid and r.expires_at > now()
     order by r.created_at, r.id
     limit least(greatest(coalesce(p_limit, 100), 1), 200);
end
$$;

-- TTL job: expired envelopes, plus everything waiting for a phone that has
-- not fetched for 30 days (accounts that registered before v5 count from
-- their first fetch afterwards).
select cron.schedule(
  'bvm-relay-ttl',
  '*/5 * * * *',
  $$delete from public.relay where expires_at < now()
      or recipient_id in (select u.id from public.users u where u.last_fetch_at < now() - interval '30 days')$$
);
