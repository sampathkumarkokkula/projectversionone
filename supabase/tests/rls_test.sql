-- Behavioural checks of the BVM schema, RLS policies and RPCs.
-- Runs on a local PostgreSQL after local_stubs.sql and the migration
-- (see validate-local.ps1). Every check raises an exception on failure.
\set ON_ERROR_STOP on

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'alice@example.org'),
  ('00000000-0000-0000-0000-00000000000b', 'bob@example.org'),
  ('00000000-0000-0000-0000-00000000000c', 'mallory@example.org');

create or replace function pg_temp.act_as(p_user text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', p_user, false);
  execute 'set role authenticated';
end $$;

create or replace function pg_temp.reset_role() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claim.sub', '', false);
end $$;

-- 43-character base64 strings stand in for Curve25519/Ed25519 keys, 86 for
-- signatures. Each user's identity key doubles as their "device key".
\set ka 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
\set kb 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
\set kc 'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'
\set kn 'NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN'
\set s 'SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS'

-- Registration ---------------------------------------------------------------
select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');
select public.create_account('alice', '+491701234567', :'ka', :'ka',
  jsonb_build_object('id', 'fb1', 'key', :'ka', 'sig', :'s'),
  jsonb_build_array(
    jsonb_build_object('id', 'otk1', 'key', :'ka', 'sig', :'s'),
    jsonb_build_object('id', 'otk2', 'key', :'ka', 'sig', :'s')));
select pg_temp.act_as('00000000-0000-0000-0000-00000000000b');
select public.create_account('bob', '+441234567890', :'kb', :'kb',
  jsonb_build_object('id', 'fb1', 'key', :'kb', 'sig', :'s'),
  jsonb_build_array(jsonb_build_object('id', 'otk1', 'key', :'kb', 'sig', :'s')));
select pg_temp.act_as('00000000-0000-0000-0000-00000000000c');
select public.create_account('mallory', '+15550001234', :'kc', :'kc', null, null);

select pg_temp.act_as('00000000-0000-0000-0000-00000000000b');
do $$
begin
  -- A taken username is a unique violation the app maps to "taken".
  begin
    perform public.create_account('bob', '+441234567890', repeat('B', 43), repeat('B', 43), null, null);
    raise exception 'duplicate account was accepted';
  exception when unique_violation then null;
  end;
  if public.username_available('bob') then raise exception 'username_available(bob) should be false'; end if;
  if not public.username_available('carol') then raise exception 'username_available(carol) should be true'; end if;
  if public.username_available('Bad Name') then raise exception 'invalid usernames must not be available'; end if;
end $$;

-- Directory: only your own row via SELECT, others only by exact username/id.
do $$
declare n int;
begin
  select count(*) into n from public.users;
  if n <> 1 then raise exception 'bob sees % directory rows directly, expected 1', n; end if;
  select count(*) into n from public.lookup_user('alice');
  if n <> 1 then raise exception 'lookup_user(alice) returned % rows', n; end if;
  select count(*) into n from public.lookup_user('ali');
  if n <> 0 then raise exception 'lookup_user must not do prefix matches'; end if;
  if (select username from public.get_user('00000000-0000-0000-0000-00000000000a')) <> 'alice' then
    raise exception 'get_user failed';
  end if;
end $$;

-- Restricted data is unreachable for API roles.
do $$
begin
  begin
    perform 1 from private.user_contact;
    raise exception 'authenticated can read private.user_contact';
  exception when insufficient_privilege then null;
  end;
  begin
    perform 1 from public.one_time_keys;
    raise exception 'authenticated can read one_time_keys directly';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.push_targets('00000000-0000-0000-0000-00000000000a', array[gen_random_uuid()]);
    raise exception 'authenticated can call push_targets';
  exception when insufficient_privilege then null;
  end;
end $$;

-- One-time keys: claimed atomically, then the fallback key.
do $$
declare r record;
begin
  select * into r from public.claim_one_time_key('00000000-0000-0000-0000-00000000000a');
  if r.key_id is null or r.is_fallback then raise exception 'expected a one-time key, got %', r; end if;
  select * into r from public.claim_one_time_key('00000000-0000-0000-0000-00000000000a');
  if r.is_fallback then raise exception 'second one-time key missing'; end if;
  select * into r from public.claim_one_time_key('00000000-0000-0000-0000-00000000000a');
  if not r.is_fallback or r.key_id <> 'fb1' then raise exception 'expected the fallback key, got %', r; end if;
  begin
    perform public.claim_one_time_key('00000000-0000-0000-0000-00000000000b');
    raise exception 'claiming your own keys was allowed';
  exception when invalid_parameter_value then null;
  end;
end $$;

-- Relay: only relay_send() can queue, with the caller as the sender.
select public.relay_send(:'kb', '10000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000000a', 'message', '{"v":1,"t":0,"c":"x"}', now() + interval '1 year');
-- Retrying the same id is a no-op (lost-response retries).
select public.relay_send(:'kb', '10000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000000a', 'message', 'changed', null);

do $$
begin
  begin
    insert into public.relay (recipient_id, sender_id, type, ciphertext)
    values ('00000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000a', 'message', 'spoofed');
    raise exception 'direct INSERT into relay is allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.relay_send(repeat('B', 43), gen_random_uuid(), '00000000-0000-0000-0000-00000000000a', 'chat_history', 'x');
    raise exception 'unknown envelope type was accepted';
  exception when check_violation then null;
  end;
  begin
    perform public.relay_send(repeat('B', 43), gen_random_uuid(), '00000000-0000-0000-0000-00000000000b', 'message', 'x');
    raise exception 'sending to yourself was accepted';
  exception when check_violation then null;
  end;
  begin
    perform public.relay_send(repeat('B', 43), gen_random_uuid(), '00000000-0000-0000-0000-0000000000ff', 'message', 'x');
    raise exception 'sending to a non-existent user was accepted';
  exception when foreign_key_violation then null;
  end;
  begin
    perform public.relay_send(repeat('Z', 43), gen_random_uuid(), '00000000-0000-0000-0000-00000000000a', 'message', 'x');
    raise exception 'a wrong device key could send';
  exception when sqlstate 'BVM01' then null;
  end;
  if exists (select 1 from public.relay) then
    raise exception 'the sender can read the envelope it sent';
  end if;
end $$;

select pg_temp.reset_role();
do $$
declare e timestamptz; c text; s uuid;
begin
  select expires_at, ciphertext, sender_id into e, c, s from public.relay where id = '10000000-0000-0000-0000-000000000001';
  if e > now() + interval '30 days 1 minute' then raise exception 'expires_at was not clamped: %', e; end if;
  if c <> '{"v":1,"t":0,"c":"x"}' then raise exception 'a retry overwrote the envelope'; end if;
  if s <> '00000000-0000-0000-0000-00000000000b' then raise exception 'sender_id is not the caller'; end if;
end $$;

select pg_temp.act_as('00000000-0000-0000-0000-00000000000c');
do $$
declare n int;
begin
  select count(*) into n from public.relay;
  if n <> 0 then raise exception 'a third user can see % envelopes', n; end if;
  select count(*) into n from public.relay_fetch(repeat('C', 43));
  if n <> 0 then raise exception 'relay_fetch shows a third user % envelopes', n; end if;
  if public.relay_ack(repeat('C', 43), array['10000000-0000-0000-0000-000000000001'::uuid]) <> 0 then
    raise exception 'a third user acknowledged (deleted) someone else''s envelope';
  end if;
  -- Direct DELETE is not granted at all; only relay_ack() deletes.
  begin
    delete from public.relay where id = '10000000-0000-0000-0000-000000000001';
    raise exception 'direct DELETE on relay is allowed';
  exception when insufficient_privilege then null;
  end;
end $$;

select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');
do $$
declare n int;
begin
  select count(*) into n from public.relay;
  if n <> 1 then raise exception 'the recipient sees % envelopes, expected 1', n; end if;
  select count(*) into n from public.relay_fetch(repeat('A', 43));
  if n <> 1 then raise exception 'relay_fetch returned % envelopes, expected 1', n; end if;
  if public.relay_ack(repeat('A', 43), array['10000000-0000-0000-0000-000000000001'::uuid]) <> 1 then
    raise exception 'relay_ack did not delete the envelope';
  end if;
  select count(*) into n from public.relay;
  if n <> 0 then raise exception 'acknowledged envelope still present'; end if;
end $$;

-- New phone: keys replaced, undecryptable envelopes dropped, old phone locked out.
select pg_temp.act_as('00000000-0000-0000-0000-00000000000b');
select public.relay_send(:'kb', gen_random_uuid(), '00000000-0000-0000-0000-00000000000a', 'delete', 'wipe');
select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');
select public.replace_device_keys(:'kn', :'kn', null,
  jsonb_build_array(jsonb_build_object('id', 'new1', 'key', :'kn', 'sig', :'s')));
do $$
begin
  if (select one_time_key_count from public.my_profile()) <> 1 then raise exception 'old one-time keys were kept'; end if;
  if exists (select 1 from public.relay) then raise exception 'envelopes for the old phone were kept'; end if;
  if public.upload_keys(repeat('N', 43), jsonb_build_array(jsonb_build_object('id', 'new2', 'key', repeat('B', 43), 'sig', repeat('C', 86)))) <> 2 then
    raise exception 'upload_keys did not return the stored count';
  end if;
  -- The previous phone (old identity key) can no longer fetch, acknowledge,
  -- send, upload keys or register for push.
  begin
    perform * from public.relay_fetch(repeat('A', 43));
    raise exception 'the replaced phone could still fetch';
  exception when sqlstate 'BVM01' then null;
  end;
  begin
    perform public.relay_ack(repeat('A', 43), array[gen_random_uuid()]);
    raise exception 'the replaced phone could still acknowledge';
  exception when sqlstate 'BVM01' then null;
  end;
  begin
    perform public.relay_send(repeat('A', 43), gen_random_uuid(), '00000000-0000-0000-0000-00000000000b', 'message', 'x');
    raise exception 'the replaced phone could still send';
  exception when sqlstate 'BVM01' then null;
  end;
  begin
    perform public.upload_keys(repeat('A', 43), '[]'::jsonb);
    raise exception 'the replaced phone could still upload keys';
  exception when sqlstate 'BVM01' then null;
  end;
  begin
    perform public.set_push_token(repeat('A', 43), 'fid-old-phone');
    raise exception 'the replaced phone could still register for push';
  exception when sqlstate 'BVM01' then null;
  end;
  perform * from public.relay_fetch(repeat('N', 43));
end $$;

-- Push targets (service role): only the caller's message envelopes, coalesced.
select public.set_push_token(:'kn', 'fid-alice');
select pg_temp.act_as('00000000-0000-0000-0000-00000000000b');
select public.relay_send(:'kb', '20000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-00000000000a', 'message', 'm');
select pg_temp.reset_role();
set role service_role;
do $$
declare n int;
begin
  select count(*) into n from public.push_targets('00000000-0000-0000-0000-00000000000b', array['20000000-0000-0000-0000-000000000001'::uuid]);
  if n <> 1 then raise exception 'push_targets returned % rows, expected 1', n; end if;
  select count(*) into n from public.push_targets('00000000-0000-0000-0000-00000000000b', array['20000000-0000-0000-0000-000000000001'::uuid]);
  if n <> 0 then raise exception 'push was not coalesced'; end if;
  select count(*) into n from public.push_targets('00000000-0000-0000-0000-00000000000c', array['20000000-0000-0000-0000-000000000001'::uuid]);
  if n <> 0 then raise exception 'push for an envelope someone else sent'; end if;
end $$;
reset role;

-- Phone numbers are encrypted at rest and decrypt only with the Vault key.
do $$
declare raw bytea; plain text;
begin
  select phone_enc into raw from private.user_contact where user_id = '00000000-0000-0000-0000-00000000000a';
  if position(convert_to('+491701234567', 'UTF8') in raw) > 0 then raise exception 'phone stored in plaintext'; end if;
  plain := extensions.pgp_sym_decrypt(raw, private.contact_key());
  if plain <> '+491701234567' then raise exception 'phone does not decrypt'; end if;
end $$;

-- Account deletion cascades (what the delete-account function triggers).
delete from auth.users where id = '00000000-0000-0000-0000-00000000000b';
do $$
begin
  if exists (select 1 from public.users where id = '00000000-0000-0000-0000-00000000000b') then
    raise exception 'directory entry survived account deletion';
  end if;
  if exists (select 1 from private.user_contact where user_id = '00000000-0000-0000-0000-00000000000b') then
    raise exception 'phone number survived account deletion';
  end if;
  -- An envelope bob sent before deleting his account is still delivered.
  if not exists (select 1 from public.relay where sender_id = '00000000-0000-0000-0000-00000000000b') then
    raise exception 'pending envelope from a deleted sender was dropped';
  end if;
end $$;

select 'ALL RLS CHECKS PASSED' as result;
