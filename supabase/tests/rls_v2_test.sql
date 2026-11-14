-- Checks for the v2 migration (usernames, blocks, spam, e-mail blocklist,
-- inbox token). Runs after rls_test.sql on the same database.
\set ON_ERROR_STOP on

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000d1', 'dana@example.org'),
  ('00000000-0000-0000-0000-0000000000d2', 'eve@example.org'),
  ('00000000-0000-0000-0000-0000000000d3', 'spam@mailinator.com');

create or replace function pg_temp.act_as(p_user text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', p_user, false);
  execute 'set role authenticated';
end $$;

\set kd 'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'
\set ke 'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE'

select pg_temp.act_as('00000000-0000-0000-0000-0000000000d1');
select public.create_account('dana', '+491700000001', :'kd', :'kd', null, null);
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d2');
select public.create_account('eve', '+491700000002', :'ke', :'ke', null, null);

-- Blocked e-mail domains cannot register; the auth hook refuses them too.
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d3');
do $$
begin
  begin
    perform public.create_account('spammer', '+491700000003', repeat('F', 43), repeat('F', 43), null, null);
    raise exception 'a blocked e-mail domain could register';
  exception when sqlstate 'BVM03' then null;
  end;
end $$;
reset role;
do $$
begin
  if (public.bvm_before_user_created('{"user":{"email":"x@Mailinator.com"}}'::jsonb)->'error') is null then
    raise exception 'hook did not refuse a blocked domain';
  end if;
  if public.bvm_before_user_created('{"user":{"email":"ok@example.org"}}'::jsonb) <> '{}'::jsonb then
    raise exception 'hook refused a normal address';
  end if;
  perform private.block_email('Someone@Example.org ');
  if not private.is_email_blocked('someone@example.org') then raise exception 'block_email did not work'; end if;
end $$;

-- Username change: reserved names refused, taken names refused, once per 24 h.
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d1');
do $$
begin
  begin
    perform public.change_username(repeat('D', 43), 'admin');
    raise exception 'a reserved username was accepted';
  exception when unique_violation then null;
  end;
  begin
    perform public.change_username(repeat('D', 43), 'eve');
    raise exception 'a taken username was accepted';
  exception when unique_violation then null;
  end;
  perform public.change_username(repeat('D', 43), 'dana_new');
  if (select username from public.my_profile()) <> 'dana_new' then raise exception 'username not changed'; end if;
  begin
    perform public.change_username(repeat('D', 43), 'dana_again');
    raise exception 'a second change within 24 hours was accepted';
  exception when sqlstate 'BVM04' then null;
  end;
  if (select count(*) from public.lookup_user('dana')) <> 0 then raise exception 'old username still resolves'; end if;
end $$;

-- Blocking: eve's envelopes to dana are dropped silently, both ways visible only to dana.
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d2');
select public.relay_send(:'ke', gen_random_uuid(), '00000000-0000-0000-0000-0000000000d1', 'message', 'before block');
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d1');
select public.block_user(:'kd', '00000000-0000-0000-0000-0000000000d2');
do $$
begin
  if exists (select 1 from public.relay) then raise exception 'queued envelopes from a blocked user were kept'; end if;
  if (select count(*) from public.my_blocks()) <> 1 then raise exception 'my_blocks is wrong'; end if;
end $$;
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d2');
select public.relay_send(:'ke', gen_random_uuid(), '00000000-0000-0000-0000-0000000000d1', 'message', 'after block');
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d1');
do $$
begin
  if exists (select 1 from public.relay) then raise exception 'a blocked user could still deliver'; end if;
end $$;
select public.unblock_user(:'kd', '00000000-0000-0000-0000-0000000000d2');
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d2');
select public.relay_send(:'ke', gen_random_uuid(), '00000000-0000-0000-0000-0000000000d1', 'message', 'after unblock');

-- Inbox token: right token sees the count, wrong token and anon guessing see 0.
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d1');
select public.set_inbox_token(:'kd', repeat('t', 43));
reset role;
set role anon;
do $$
begin
  if public.inbox_pending('00000000-0000-0000-0000-0000000000d1', repeat('t', 43)) <> 1 then
    raise exception 'inbox_pending did not count the waiting envelope';
  end if;
  if public.inbox_pending('00000000-0000-0000-0000-0000000000d1', repeat('x', 43)) <> 0 then
    raise exception 'inbox_pending answered for a wrong token';
  end if;
end $$;
reset role;

-- Spam: 5 reports from accounts older than a day suspend the account.
update public.users set created_at = now() - interval '2 days';
insert into auth.users (id, email)
select ('00000000-0000-0000-0000-0000000001' || lpad(g::text, 2, '0'))::uuid, 'r' || g || '@example.org'
  from generate_series(1, 5) g;
insert into public.users (id, username, identity_key, signing_key, created_at)
select ('00000000-0000-0000-0000-0000000001' || lpad(g::text, 2, '0'))::uuid, 'reporter' || g,
       repeat(chr(70 + g), 43), repeat(chr(70 + g), 43), now() - interval '2 days'
  from generate_series(1, 5) g;
do $$
declare g int;
begin
  for g in 1..5 loop
    perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000001' || lpad(g::text, 2, '0'), false);
    execute 'set role authenticated';
    perform public.report_spam(repeat(chr(70 + g), 43), '00000000-0000-0000-0000-0000000000d2');
    execute 'reset role';
  end loop;
  if (select suspended_at from public.users where id = '00000000-0000-0000-0000-0000000000d2') is null then
    raise exception 'five reports did not suspend the account';
  end if;
  if not private.is_email_blocked('eve@example.org') then
    raise exception 'the suspended account''s e-mail was not blocklisted';
  end if;
end $$;
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d2');
do $$
begin
  begin
    perform public.relay_send(repeat('E', 43), gen_random_uuid(), '00000000-0000-0000-0000-0000000000d1', 'message', 'x');
    raise exception 'a suspended account could still send';
  exception when sqlstate 'BVM02' then null;
  end;
end $$;
select pg_temp.act_as('00000000-0000-0000-0000-0000000000d1');
do $$
begin
  if (select count(*) from public.lookup_user('eve')) <> 0 then raise exception 'suspended account still discoverable'; end if;
end $$;

select 'ALL V2 CHECKS PASSED' as result;
