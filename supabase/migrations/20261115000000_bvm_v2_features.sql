-- =============================================================================
-- BVM v2: username changes, blocking, spam reports, e-mail blocklist and the
-- notification inbox check. Apply after 20261031000000_bvm_init.sql (SQL
-- editor: paste and run; CLI: `supabase db push`). Safe to re-run.
--
-- Nothing here stores message content. New metadata on the server:
--   * private.blocks         who blocked whom (needed to drop their envelopes)
--   * private.spam_reports   who reported whom (no content, E2E stays intact)
--   * private.blocked_emails SHA-256 hashes of banned e-mail addresses
--   * private.inbox_tokens   SHA-256 of a per-phone random token that lets the
--                            phone ask "do I have new messages?" without a
--                            login session (background notifications)
-- Images and profile pictures travel end-to-end encrypted through public.relay
-- like messages; this migration needs no storage bucket for them.
-- =============================================================================

alter table public.users add column if not exists username_changed_at timestamptz;
alter table public.users add column if not exists suspended_at timestamptz;

-- ---------------------------------------------------------------------------
-- Tables (private schema: not exposed through the Data API)
-- ---------------------------------------------------------------------------
create table if not exists private.blocks (
  blocker_id uuid not null references auth.users (id) on delete cascade,
  blocked_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);
create index if not exists blocks_blocked_idx on private.blocks (blocked_id);

create table if not exists private.spam_reports (
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reported_id uuid not null references auth.users (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (reporter_id, reported_id),
  constraint spam_reports_not_self check (reporter_id <> reported_id)
);
create index if not exists spam_reports_reported_idx on private.spam_reports (reported_id, created_at);

create table if not exists private.blocked_emails (
  email_hash text primary key,
  reason     text not null default 'manual',
  created_at timestamptz not null default now()
);

create table if not exists private.blocked_email_domains (
  domain     text primary key,
  created_at timestamptz not null default now()
);

create table if not exists private.inbox_tokens (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  token_hash text not null,
  updated_at timestamptz not null default now()
);

alter table private.blocks                enable row level security;
alter table private.spam_reports          enable row level security;
alter table private.blocked_emails        enable row level security;
alter table private.blocked_email_domains enable row level security;
alter table private.inbox_tokens          enable row level security;

-- Common disposable / throw-away e-mail domains. Extend with
-- `select private.block_email_domain('example.com');` in the SQL editor.
insert into private.blocked_email_domains (domain) values
  ('mailinator.com'), ('guerrillamail.com'), ('guerrillamail.net'), ('sharklasers.com'),
  ('10minutemail.com'), ('10minutemail.net'), ('tempmail.com'), ('temp-mail.org'),
  ('temp-mail.io'), ('throwawaymail.com'), ('yopmail.com'), ('yopmail.net'),
  ('trashmail.com'), ('trashmail.de'), ('getnada.com'), ('nada.email'),
  ('dispostable.com'), ('maildrop.cc'), ('mintemail.com'), ('fakeinbox.com'),
  ('mohmal.com'), ('emailondeck.com'), ('spamgourmet.com'), ('mailnesia.com'),
  ('tempinbox.com'), ('discard.email'), ('burnermail.io'), ('1secmail.com'),
  ('moakt.com'), ('tempail.com')
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function private.email_hash(p_email text)
returns text
language sql
immutable
set search_path = ''
as $$
  select encode(extensions.digest(lower(trim(coalesce(p_email, ''))), 'sha256'), 'hex')
$$;

create or replace function private.is_email_blocked(p_email text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_email is not null and (
    exists (select 1 from private.blocked_emails b where b.email_hash = private.email_hash(p_email))
    or exists (
      select 1 from private.blocked_email_domains d
       where d.domain = lower(split_part(trim(p_email), '@', 2))
    )
  )
$$;

-- Operator helpers, for the SQL editor only (not callable through the API).
create or replace function private.block_email(p_email text, p_reason text default 'manual')
returns void
language sql
security definer
set search_path = ''
as $$
  insert into private.blocked_emails (email_hash, reason)
  values (private.email_hash(p_email), coalesce(p_reason, 'manual'))
  on conflict (email_hash) do nothing
$$;

create or replace function private.block_email_domain(p_domain text)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into private.blocked_email_domains (domain) values (lower(trim(p_domain)))
  on conflict (domain) do nothing
$$;

create or replace function private.assert_username_allowed(p_username text)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_username is null or p_username !~ '^[a-z0-9_]{3,24}$' then
    raise exception 'invalid username' using errcode = '22023';
  end if;
  if p_username in ('admin', 'administrator', 'bvm', 'help', 'moderator', 'official',
                    'root', 'security', 'staff', 'support', 'system') then
    raise exception 'this username is reserved' using errcode = '23505';
  end if;
end
$$;

create or replace function private.assert_not_suspended(p_uid uuid)
returns void
language plpgsql
stable
set search_path = ''
as $$
begin
  if exists (select 1 from public.users u where u.id = p_uid and u.suspended_at is not null) then
    raise exception 'this account is suspended' using errcode = 'BVM02';
  end if;
end
$$;

revoke all on function private.email_hash(text) from public, anon, authenticated;
revoke all on function private.is_email_blocked(text) from public, anon, authenticated;
revoke all on function private.block_email(text, text) from public, anon, authenticated;
revoke all on function private.block_email_domain(text) from public, anon, authenticated;
revoke all on function private.assert_username_allowed(text) from public, anon, authenticated;
revoke all on function private.assert_not_suspended(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Registration: blocked e-mail addresses and reserved usernames
-- ---------------------------------------------------------------------------
create or replace function public.create_account(
  p_username      text,
  p_phone         text,
  p_identity_key  text,
  p_signing_key   text,
  p_fallback_key  jsonb,
  p_one_time_keys jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if private.is_email_blocked((select au.email from auth.users au where au.id = v_uid)) then
    raise exception 'this e-mail address cannot be used' using errcode = 'BVM03';
  end if;
  perform private.assert_username_allowed(p_username);
  if p_phone is null or p_phone !~ '^\+[1-9][0-9]{6,14}$' then
    raise exception 'invalid phone number' using errcode = '22023';
  end if;
  perform private.assert_b64(p_identity_key, 40, 64);
  perform private.assert_b64(p_signing_key, 40, 64);

  insert into public.users (id, username, identity_key, signing_key, fallback_key)
  values (v_uid, p_username, p_identity_key, p_signing_key, private.clean_signed_key(p_fallback_key));

  insert into private.user_contact (user_id, phone_enc)
  values (v_uid, extensions.pgp_sym_encrypt(p_phone, private.contact_key(), 'cipher-algo=aes256'))
  on conflict (user_id) do update
    set phone_enc = excluded.phone_enc, phone_verified = false, updated_at = now();

  perform private.insert_one_time_keys(v_uid, p_one_time_keys);
end
$$;

-- Supabase Auth "Before User Created" hook (optional, recommended): refuses
-- sign-ups from blocked addresses and domains before any OTP e-mail is sent.
-- Enable under Authentication > Hooks > Before User Created > Postgres
-- function `public.bvm_before_user_created`.
create or replace function public.bvm_before_user_created(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if private.is_email_blocked(event->'user'->>'email') then
    return jsonb_build_object('error', jsonb_build_object(
      'message', 'This e-mail address cannot be used with BVM.',
      'http_code', 403
    ));
  end if;
  return '{}'::jsonb;
end
$$;
revoke all on function public.bvm_before_user_created(jsonb) from public, anon, authenticated;
grant execute on function public.bvm_before_user_created(jsonb) to supabase_auth_admin;

-- ---------------------------------------------------------------------------
-- Username change (at most once every 24 hours)
-- ---------------------------------------------------------------------------
create or replace function public.change_username(p_device_key text, p_username text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := auth.uid();
  v_current text;
  v_changed timestamptz;
begin
  perform private.assert_current_device(v_uid, p_device_key);
  perform private.assert_not_suspended(v_uid);
  perform private.assert_username_allowed(p_username);
  select u.username, u.username_changed_at into v_current, v_changed
    from public.users u where u.id = v_uid;
  if v_current = p_username then
    return;
  end if;
  if v_changed is not null and v_changed > now() - interval '24 hours' then
    raise exception 'the username can be changed once every 24 hours' using errcode = 'BVM04';
  end if;
  update public.users
     set username = p_username, username_changed_at = now()
   where id = v_uid;
end
$$;

-- Discovery skips suspended accounts.
create or replace function public.lookup_user(p_username text)
returns table (id uuid, username text, identity_key text, signing_key text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  return query
    select u.id, u.username, u.identity_key, u.signing_key
      from public.users u
     where u.username = lower(trim(p_username))
       and u.suspended_at is null;
end
$$;

-- Suspended accounts cannot start new sessions.
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

-- New phone: also forget the previous phone's inbox token.
create or replace function public.replace_device_keys(
  p_identity_key  text,
  p_signing_key   text,
  p_fallback_key  jsonb,
  p_one_time_keys jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  perform private.assert_b64(p_identity_key, 40, 64);
  perform private.assert_b64(p_signing_key, 40, 64);

  update public.users
     set identity_key = p_identity_key,
         signing_key = p_signing_key,
         fallback_key = private.clean_signed_key(p_fallback_key),
         keys_updated_at = now()
   where id = v_uid;
  if not found then
    raise exception 'no account for this user' using errcode = 'P0002';
  end if;

  delete from public.one_time_keys where user_id = v_uid;
  delete from public.relay where recipient_id = v_uid;
  delete from private.inbox_tokens where user_id = v_uid;
  perform private.insert_one_time_keys(v_uid, p_one_time_keys);
end
$$;

-- ---------------------------------------------------------------------------
-- Relay: blocked senders are dropped silently, suspended senders refused.
-- The sender cannot tell that it was blocked (the call succeeds either way).
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
  if exists (select 1 from private.blocks b where b.blocker_id = p_recipient and b.blocked_id = v_uid) then
    return;
  end if;
  insert into public.relay (id, recipient_id, sender_id, type, ciphertext, expires_at)
  values (p_id, p_recipient, v_uid, p_type, p_ciphertext, p_expires_at)
  on conflict (id) do nothing;
end
$$;

-- ---------------------------------------------------------------------------
-- Blocking
-- ---------------------------------------------------------------------------
create or replace function public.block_user(p_device_key text, p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  perform private.assert_current_device(v_uid, p_device_key);
  if p_user is null or p_user = v_uid then
    raise exception 'invalid user' using errcode = '22023';
  end if;
  insert into private.blocks (blocker_id, blocked_id)
  select v_uid, p_user where exists (select 1 from auth.users au where au.id = p_user)
  on conflict do nothing;
  -- Whatever they already queued for you is dropped too.
  delete from public.relay r where r.recipient_id = v_uid and r.sender_id = p_user;
end
$$;

create or replace function public.unblock_user(p_device_key text, p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  perform private.assert_current_device(v_uid, p_device_key);
  delete from private.blocks b where b.blocker_id = v_uid and b.blocked_id = p_user;
end
$$;

-- Your block list (survives moving to a new phone).
create or replace function public.my_blocks()
returns table (user_id uuid, username text, blocked_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  return query
    select b.blocked_id, u.username, b.created_at
      from private.blocks b
      left join public.users u on u.id = b.blocked_id
     where b.blocker_id = auth.uid()
     order by b.created_at desc;
end
$$;

-- ---------------------------------------------------------------------------
-- Spam reports: report = block + report. An account reported by 5 different
-- users (whose own accounts are at least a day old) within 30 days is
-- suspended and its e-mail address is added to the blocklist (as a hash).
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
-- Notification inbox check. The phone registers a random token; a background
-- task later asks, without a login session, how many message envelopes are
-- waiting. The answer is 0 for a wrong token, so it reveals nothing.
-- ---------------------------------------------------------------------------
create or replace function public.set_inbox_token(p_device_key text, p_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  perform private.assert_current_device(v_uid, p_device_key);
  if p_token is null or length(p_token) < 32 or length(p_token) > 128 then
    raise exception 'invalid token' using errcode = '22023';
  end if;
  insert into private.inbox_tokens (user_id, token_hash)
  values (v_uid, encode(extensions.digest(p_token, 'sha256'), 'hex'))
  on conflict (user_id) do update set token_hash = excluded.token_hash, updated_at = now();
end
$$;

create or replace function public.inbox_pending(p_user uuid, p_token text)
returns integer
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_user is null or p_token is null or length(p_token) < 32 or length(p_token) > 128 then
    return 0;
  end if;
  if not exists (
    select 1 from private.inbox_tokens t
     where t.user_id = p_user
       and t.token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex')
  ) then
    return 0;
  end if;
  return (
    select least(count(*), 99)::integer
      from public.relay r
     where r.recipient_id = p_user and r.type = 'message' and r.expires_at > now()
  );
end
$$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------
revoke all on function public.change_username(text, text) from public, anon;
revoke all on function public.block_user(text, uuid) from public, anon;
revoke all on function public.unblock_user(text, uuid) from public, anon;
revoke all on function public.my_blocks() from public, anon;
revoke all on function public.report_spam(text, uuid) from public, anon;
revoke all on function public.set_inbox_token(text, text) from public, anon;
revoke all on function public.inbox_pending(uuid, text) from public;

grant execute on function public.change_username(text, text) to authenticated;
grant execute on function public.block_user(text, uuid) to authenticated;
grant execute on function public.unblock_user(text, uuid) to authenticated;
grant execute on function public.my_blocks() to authenticated;
grant execute on function public.report_spam(text, uuid) to authenticated;
grant execute on function public.set_inbox_token(text, text) to authenticated;
grant execute on function public.inbox_pending(uuid, text) to anon, authenticated;
