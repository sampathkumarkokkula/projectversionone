-- =============================================================================
-- BVM - initial Supabase schema, Row Level Security, RPCs and TTL job.
--
-- The server is a thin relay + username directory + public-key store + push
-- trigger. It never stores readable messages and never stores history:
--   * public.relay holds end-to-end-encrypted envelopes only until the
--     recipient acknowledges them (relay_ack deletes the row) or the row's
--     TTL passes (pg_cron purges it).
--   * There are no passwords on the server. The app-lock passwords (main and
--     optional secondary) are verified on the device only; the server cannot
--     tell whether a secondary password exists.
--   * Phone numbers are stored encrypted (pgcrypto, key held in Supabase Vault)
--     in a schema that the Data API does not expose. E-mail addresses live
--     only in Supabase Auth (auth.users), which is required for e-mail OTP and
--     is not exposed through the Data API either; this schema keeps no copy.
--
-- Apply with `supabase db push` or paste into the SQL editor. Idempotent where
-- practical (safe to re-run).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists pgcrypto with schema extensions;
create extension if not exists supabase_vault;
create extension if not exists pg_cron with schema pg_catalog;

-- ---------------------------------------------------------------------------
-- Private schema: not exposed by the Data API, no access for API roles.
-- ---------------------------------------------------------------------------
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- Encryption key for contact data (phone numbers), generated once and kept in
-- Supabase Vault. It never leaves the database.
do $$
begin
  if not exists (select 1 from vault.secrets where name = 'bvm_contact_key') then
    perform vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'base64'),
      'bvm_contact_key',
      'BVM: encrypts phone numbers at rest'
    );
  end if;
end
$$;

create or replace function private.contact_key()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select decrypted_secret from vault.decrypted_secrets where name = 'bvm_contact_key' limit 1
$$;
revoke all on function private.contact_key() from public, anon, authenticated;

-- Validates an unpadded/padded base64 encoded public key or signature.
create or replace function private.assert_b64(p_value text, p_min int, p_max int)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_value is null
     or length(p_value) < p_min
     or length(p_value) > p_max
     or p_value !~ '^[A-Za-z0-9+/=_-]+$' then
    raise exception 'invalid key material' using errcode = '22023';
  end if;
end
$$;
revoke all on function private.assert_b64(text, int, int) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Directory + identity keys
--   identity_key  Curve25519 identity key (Olm), base64
--   signing_key   Ed25519 identity key (Olm), base64; signs one-time and
--                 fallback keys, and is the basis of the safety number
--   fallback_key  {"id","key","sig"} - signed last-resort key, the Olm
--                 counterpart of Signal's signed prekey
-- ---------------------------------------------------------------------------
create table if not exists public.users (
  id              uuid primary key references auth.users (id) on delete cascade,
  username        text not null,
  identity_key    text not null,
  signing_key     text not null,
  fallback_key    jsonb,
  created_at      timestamptz not null default now(),
  keys_updated_at timestamptz not null default now(),
  constraint users_username_format check (username ~ '^[a-z0-9_]{3,24}$')
);
create unique index if not exists users_username_key on public.users (username);

create table if not exists public.one_time_keys (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.users (id) on delete cascade,
  key_id      text not null,
  public_key  text not null,
  signature   text not null,
  created_at  timestamptz not null default now(),
  constraint one_time_keys_unique unique (user_id, key_id)
);
create index if not exists one_time_keys_user_idx on public.one_time_keys (user_id, id);

-- Restricted contact data (encrypted). Phone verification is deferred.
create table if not exists private.user_contact (
  user_id         uuid primary key references auth.users (id) on delete cascade,
  phone_enc       bytea not null,
  phone_verified  boolean not null default false,
  updated_at      timestamptz not null default now()
);

-- FCM registrations (restricted; only the push Edge Function reads them).
-- fcm_token holds the app instance's Firebase Installation ID (FID), which
-- FCM now uses instead of the deprecated registration tokens.
create table if not exists private.push_tokens (
  user_id       uuid primary key references auth.users (id) on delete cascade,
  fcm_token     text not null unique,
  last_push_at  timestamptz,
  updated_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Transient relay. One row per end-to-end-encrypted envelope; deleted by the
-- recipient right after it has been decrypted and stored on the device.
--   sender_id has no foreign key on purpose: an envelope that is already
--   queued (for example a wipe command for an offline peer) must still reach
--   the peer if the sender deletes their account afterwards.
-- ---------------------------------------------------------------------------
create table if not exists public.relay (
  id            uuid primary key default gen_random_uuid(),
  recipient_id  uuid not null references public.users (id) on delete cascade,
  sender_id     uuid not null,
  type          text not null,
  ciphertext    text not null,
  created_at    timestamptz not null default now(),
  expires_at    timestamptz not null default (now() + interval '30 days'),
  constraint relay_type_check check (type in ('message', 'receipt', 'delete', 'timer_change')),
  constraint relay_size_check check (octet_length(ciphertext) <= 65536),
  constraint relay_not_self check (recipient_id <> sender_id)
);
create index if not exists relay_recipient_idx on public.relay (recipient_id, created_at);
create index if not exists relay_expires_idx on public.relay (expires_at);

-- The server, not the client, decides created_at; expires_at is clamped to
-- [now + 1 minute, now + 30 days]. Clients set a shorter expires_at for
-- messages with an auto-delete timer, so an undelivered timed message never
-- outlives its timer on the server.
create or replace function private.relay_before_insert()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.created_at := now();
  if new.expires_at is null or new.expires_at > now() + interval '30 days' then
    new.expires_at := now() + interval '30 days';
  elsif new.expires_at < now() + interval '1 minute' then
    new.expires_at := now() + interval '1 minute';
  end if;
  return new;
end
$$;
revoke all on function private.relay_before_insert() from public, anon, authenticated;

drop trigger if exists relay_before_insert on public.relay;
create trigger relay_before_insert
  before insert on public.relay
  for each row execute function private.relay_before_insert();

-- ---------------------------------------------------------------------------
-- Privileges + Row Level Security
-- ---------------------------------------------------------------------------
alter table public.users          enable row level security;
alter table public.one_time_keys  enable row level security;
alter table public.relay          enable row level security;
alter table private.user_contact  enable row level security;
alter table private.push_tokens   enable row level security;

revoke all on table public.users, public.one_time_keys, public.relay from anon, authenticated;
grant select on table public.users to authenticated;
-- SELECT stays so Realtime can notify the recipient (it applies the select
-- policy per subscriber). Sending, fetching and acknowledging go through
-- relay_send(), relay_fetch() and relay_ack(), which also check that the
-- caller is the account's current phone.
grant select on table public.relay to authenticated;

-- users: only your own row is readable directly. Other users are reachable
-- only through lookup_user() (exact username) and get_user() (by id), so the
-- directory cannot be listed or scraped with a plain SELECT.
drop policy if exists users_select_own on public.users;
create policy users_select_own on public.users
  for select to authenticated
  using (id = (select auth.uid()));

-- one_time_keys: no direct access; RPCs only (RLS enabled, no policies).

-- relay: read only rows addressed to you (used by Realtime). No INSERT or
-- DELETE grants: those go through relay_send() / relay_ack().
drop policy if exists relay_insert_as_sender on public.relay;

drop policy if exists relay_select_recipient on public.relay;
create policy relay_select_recipient on public.relay
  for select to authenticated
  using (recipient_id = (select auth.uid()) and expires_at > now());

-- No DELETE policy: acknowledging is only possible through relay_ack().
drop policy if exists relay_delete_recipient on public.relay;

-- ---------------------------------------------------------------------------
-- Helpers for key uploads
-- ---------------------------------------------------------------------------
create or replace function private.clean_signed_key(p_key jsonb)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_key is null or jsonb_typeof(p_key) = 'null' then
    return null;
  end if;
  if jsonb_typeof(p_key) <> 'object' then
    raise exception 'invalid signed key' using errcode = '22023';
  end if;
  perform private.assert_b64(p_key->>'id', 1, 64);
  perform private.assert_b64(p_key->>'key', 40, 64);
  perform private.assert_b64(p_key->>'sig', 80, 100);
  return jsonb_build_object('id', p_key->>'id', 'key', p_key->>'key', 'sig', p_key->>'sig');
end
$$;
revoke all on function private.clean_signed_key(jsonb) from public, anon, authenticated;

create or replace function private.insert_one_time_keys(p_user uuid, p_keys jsonb)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_key     jsonb;
  v_clean   jsonb;
  v_stored  integer;
  v_added   integer := 0;
begin
  if p_keys is null or jsonb_typeof(p_keys) = 'null' then
    return 0;
  end if;
  if jsonb_typeof(p_keys) <> 'array' or jsonb_array_length(p_keys) > 100 then
    raise exception 'invalid one-time key batch' using errcode = '22023';
  end if;
  select count(*) into v_stored from public.one_time_keys where user_id = p_user;
  if v_stored + jsonb_array_length(p_keys) > 200 then
    raise exception 'too many one-time keys' using errcode = '22023';
  end if;
  for v_key in select * from jsonb_array_elements(p_keys) loop
    v_clean := private.clean_signed_key(v_key);
    insert into public.one_time_keys (user_id, key_id, public_key, signature)
    values (p_user, v_clean->>'id', v_clean->>'key', v_clean->>'sig')
    on conflict on constraint one_time_keys_unique do nothing;
    if found then
      v_added := v_added + 1;
    end if;
  end loop;
  return v_added;
end
$$;
revoke all on function private.insert_one_time_keys(uuid, jsonb) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- RPCs (all SECURITY DEFINER with an empty search_path; each one checks
-- auth.uid() itself).
-- ---------------------------------------------------------------------------

-- First registration: directory entry, encrypted phone, identity keys.
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
  if p_username is null or p_username !~ '^[a-z0-9_]{3,24}$' then
    raise exception 'invalid username' using errcode = '22023';
  end if;
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

-- Signing in on a new (or reinstalled) device: replace the identity keys.
-- Undelivered envelopes were encrypted for the previous device and can never
-- be decrypted, so they are dropped together with the old one-time keys.
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
  perform private.insert_one_time_keys(v_uid, p_one_time_keys);
end
$$;

-- Earlier drafts of this migration had these without the device key.
drop function if exists public.upload_keys(jsonb, jsonb);
drop function if exists public.set_push_token(text);

-- Replenish one-time keys and optionally rotate the fallback key.
-- Returns the number of one-time keys now stored on the server. Only the
-- current phone may upload: keys signed by a replaced phone would not verify
-- against the directory's signing key.
create or replace function public.upload_keys(
  p_device_key    text,
  p_one_time_keys jsonb,
  p_fallback_key  jsonb default null
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid();
  v_count integer;
begin
  perform private.assert_current_device(v_uid, p_device_key);
  perform private.insert_one_time_keys(v_uid, p_one_time_keys);
  if p_fallback_key is not null and jsonb_typeof(p_fallback_key) <> 'null' then
    update public.users
       set fallback_key = private.clean_signed_key(p_fallback_key), keys_updated_at = now()
     where id = v_uid;
  end if;
  select count(*) into v_count from public.one_time_keys where user_id = v_uid;
  return v_count;
end
$$;

-- One phone per account. A phone proves it is the account's current phone by
-- sending its Curve25519 identity key; after another phone registered new
-- keys (replace_device_keys) the old phone gets SQLSTATE BVM01 and must stop.
-- Without this, the old phone would keep fetching and deleting envelopes it
-- can no longer decrypt, and the new phone would never receive them.
create or replace function private.assert_current_device(p_uid uuid, p_device_key text)
returns void
language plpgsql
stable
set search_path = ''
as $$
declare
  v_key text;
begin
  if p_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  select u.identity_key into v_key from public.users u where u.id = p_uid;
  if v_key is null then
    raise exception 'no account for this user' using errcode = 'P0002';
  end if;
  if p_device_key is distinct from v_key then
    raise exception 'this account is now used on another phone' using errcode = 'BVM01';
  end if;
end
$$;
revoke all on function private.assert_current_device(uuid, text) from public, anon, authenticated;

-- Queue one end-to-end-encrypted envelope for p_recipient. Idempotent per id,
-- so the app can retry after a lost response. created_at and expires_at are
-- normalised by the relay_before_insert trigger.
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
  if p_id is null or p_recipient is null then
    raise exception 'missing id or recipient' using errcode = '22023';
  end if;
  insert into public.relay (id, recipient_id, sender_id, type, ciphertext, expires_at)
  values (p_id, p_recipient, v_uid, p_type, p_ciphertext, p_expires_at)
  on conflict (id) do nothing;
end
$$;

-- Envelopes waiting for the calling phone, oldest first.
create or replace function public.relay_fetch(p_device_key text, p_limit integer default 100)
returns table (id uuid, sender_id uuid, type text, ciphertext text)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  perform private.assert_current_device(v_uid, p_device_key);
  return query
    select r.id, r.sender_id, r.type, r.ciphertext
      from public.relay r
     where r.recipient_id = v_uid
       and r.expires_at > now()
     order by r.created_at, r.id
     limit least(greatest(coalesce(p_limit, 100), 1), 200);
end
$$;

-- Acknowledge = delete. Called right after the envelopes are stored on the
-- phone. Returns the number of envelopes deleted.
create or replace function public.relay_ack(p_device_key text, p_ids uuid[])
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := auth.uid();
  v_count integer;
begin
  perform private.assert_current_device(v_uid, p_device_key);
  if p_ids is null or cardinality(p_ids) = 0 then
    return 0;
  end if;
  if cardinality(p_ids) > 200 then
    raise exception 'too many ids' using errcode = '22023';
  end if;
  delete from public.relay r where r.recipient_id = v_uid and r.id = any (p_ids);
  get diagnostics v_count = row_count;
  return v_count;
end
$$;

-- The caller's own directory entry (null when not registered yet).
create or replace function public.my_profile()
returns table (id uuid, username text, identity_key text, signing_key text, one_time_key_count integer)
language sql
stable
security definer
set search_path = ''
as $$
  select u.id, u.username, u.identity_key, u.signing_key,
         (select count(*)::integer from public.one_time_keys k where k.user_id = u.id)
    from public.users u
   where u.id = auth.uid()
$$;

create or replace function public.username_available(p_username text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_username is null or p_username !~ '^[a-z0-9_]{3,24}$' then
    return false;
  end if;
  return not exists (select 1 from public.users u where u.username = p_username);
end
$$;

-- Discovery by exact username only. Never returns phone or e-mail.
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
     where u.username = lower(trim(p_username));
end
$$;

-- Public directory fields of a known user id (used when a first message
-- arrives from someone not yet in the local chat list).
create or replace function public.get_user(p_user_id uuid)
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
     where u.id = p_user_id;
end
$$;

-- Atomically hands out one signed one-time key of p_user_id (deleting it), or
-- the signed fallback key when none are left.
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

-- Register (or clear, with null) the current phone's push address (FID).
create or replace function public.set_push_token(p_device_key text, p_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  perform private.assert_current_device(v_uid, p_device_key);
  if p_token is null or length(p_token) = 0 then
    delete from private.push_tokens where user_id = v_uid;
    return;
  end if;
  if length(p_token) > 4096 then
    raise exception 'invalid token' using errcode = '22023';
  end if;
  -- A token belongs to one device; drop it from any previous account.
  delete from private.push_tokens where fcm_token = p_token and user_id <> v_uid;
  insert into private.push_tokens (user_id, fcm_token)
  values (v_uid, p_token)
  on conflict (user_id) do update set fcm_token = excluded.fcm_token, updated_at = now();
end
$$;

-- Service-role only: which recipients of the caller's just-sent message
-- envelopes should get a content-free wake-up push. Coalesces pushes to at
-- most one per recipient every 5 seconds.
create or replace function public.push_targets(p_sender uuid, p_relay_ids uuid[])
returns table (recipient_id uuid, fcm_token text)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  if p_relay_ids is null or cardinality(p_relay_ids) = 0 or cardinality(p_relay_ids) > 100 then
    return;
  end if;
  return query
    with targets as (
      select distinct r.recipient_id as uid
        from public.relay r
       where r.id = any (p_relay_ids)
         and r.sender_id = p_sender
         and r.type = 'message'
    ),
    due as (
      update private.push_tokens t
         set last_push_at = now()
        from targets
       where t.user_id = targets.uid
         and (t.last_push_at is null or t.last_push_at < now() - interval '5 seconds')
      returning t.user_id, t.fcm_token
    )
    select due.user_id, due.fcm_token from due;
end
$$;

-- Service-role only: forget a token that FCM reported as invalid.
create or replace function public.drop_push_token(p_user_id uuid, p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from private.push_tokens where user_id = p_user_id and fcm_token = p_token
$$;

-- Function privileges: nothing for anon; client RPCs for authenticated users;
-- push helpers for the service role (Edge Functions) only.
revoke all on function public.create_account(text, text, text, text, jsonb, jsonb) from public, anon;
revoke all on function public.replace_device_keys(text, text, jsonb, jsonb) from public, anon;
revoke all on function public.upload_keys(text, jsonb, jsonb) from public, anon;
revoke all on function public.my_profile() from public, anon;
revoke all on function public.username_available(text) from public, anon;
revoke all on function public.lookup_user(text) from public, anon;
revoke all on function public.get_user(uuid) from public, anon;
revoke all on function public.claim_one_time_key(uuid) from public, anon;
revoke all on function public.relay_send(text, uuid, uuid, text, text, timestamptz) from public, anon;
revoke all on function public.relay_fetch(text, integer) from public, anon;
revoke all on function public.relay_ack(text, uuid[]) from public, anon;
revoke all on function public.set_push_token(text, text) from public, anon;
revoke all on function public.push_targets(uuid, uuid[]) from public, anon, authenticated;
revoke all on function public.drop_push_token(uuid, text) from public, anon, authenticated;

grant execute on function public.create_account(text, text, text, text, jsonb, jsonb) to authenticated;
grant execute on function public.replace_device_keys(text, text, jsonb, jsonb) to authenticated;
grant execute on function public.upload_keys(text, jsonb, jsonb) to authenticated;
grant execute on function public.my_profile() to authenticated;
grant execute on function public.username_available(text) to authenticated;
grant execute on function public.lookup_user(text) to authenticated;
grant execute on function public.get_user(uuid) to authenticated;
grant execute on function public.claim_one_time_key(uuid) to authenticated;
grant execute on function public.relay_send(text, uuid, uuid, text, text, timestamptz) to authenticated;
grant execute on function public.relay_fetch(text, integer) to authenticated;
grant execute on function public.relay_ack(text, uuid[]) to authenticated;
grant execute on function public.set_push_token(text, text) to authenticated;
grant execute on function public.push_targets(uuid, uuid[]) to service_role;
grant execute on function public.drop_push_token(uuid, text) to service_role;

-- ---------------------------------------------------------------------------
-- Realtime: recipients get INSERT events for their own relay rows (Realtime
-- applies the RLS select policy above per subscriber).
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'relay'
  ) then
    alter publication supabase_realtime add table public.relay;
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- TTL: purge envelopes that were never delivered (every 5 minutes).
-- ---------------------------------------------------------------------------
select cron.schedule(
  'bvm-relay-ttl',
  '*/5 * * * *',
  $$delete from public.relay where expires_at < now()$$
);
