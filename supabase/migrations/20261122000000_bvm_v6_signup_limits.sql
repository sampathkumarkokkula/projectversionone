-- =============================================================================
-- BVM v6: sign-up and sign-in spam limits for a small server. Apply after
-- v1-v5 (SQL editor: paste and run). Safe to re-run.
--
--   * Sign-up caps in the "Before User Created" Auth hook (enable it under
--     Authentication > Hooks > Before User Created > Postgres function
--     public.bvm_before_user_created). New e-mail addresses beyond the caps
--     get no code e-mail at all:
--       signups_per_hour   default   30   (all users together)
--       signups_per_day    default  150
--       max_accounts       default 1000   (closes registration when reached)
--     Change them any time, no app update needed, e.g.:
--       update private.settings set value = 2000 where key = 'max_accounts';
--   * Unfinished sign-ups (code requested or typed, but no BVM account
--     created) are deleted after 24 hours, so OTP spam leaves nothing behind.
--   * Rate limits on the remaining per-user lookups: get_user (directory,
--     600 / hour) and get_account_backup (10 / hour).
--
-- Per-e-mail and per-IP limits on code e-mails and code checks are Supabase
-- Auth settings (Authentication > Rate Limits); see docs/GO_LIVE.md.
-- =============================================================================

create table if not exists private.settings (
  key   text primary key,
  value integer not null
);
alter table private.settings enable row level security;
insert into private.settings (key, value) values
  ('signups_per_hour', 30),
  ('signups_per_day', 150),
  ('max_accounts', 1000)
on conflict (key) do nothing;

create or replace function private.setting(p_key text, p_default integer)
returns integer
language sql
stable
set search_path = ''
as $$
  select coalesce((select s.value from private.settings s where s.key = p_key), p_default)
$$;
revoke all on function private.setting(text, integer) from public, anon, authenticated;

-- Same as v2 (blocked addresses and domains), plus the sign-up caps.
create or replace function public.bvm_before_user_created(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_busy jsonb := jsonb_build_object('error', jsonb_build_object(
    'message', 'BVM is not accepting new sign-ups right now. Please try again later.',
    'http_code', 429
  ));
begin
  if private.is_email_blocked(event->'user'->>'email') then
    return jsonb_build_object('error', jsonb_build_object(
      'message', 'This e-mail address cannot be used with BVM.',
      'http_code', 403
    ));
  end if;
  if (select count(*) from auth.users au where au.created_at > now() - interval '1 hour')
       >= private.setting('signups_per_hour', 30)
     or (select count(*) from auth.users au where au.created_at > now() - interval '1 day')
       >= private.setting('signups_per_day', 150)
     or (select count(*) from public.users) >= private.setting('max_accounts', 1000) then
    return v_busy;
  end if;
  return '{}'::jsonb;
end
$$;
revoke all on function public.bvm_before_user_created(jsonb) from public, anon, authenticated;
grant execute on function public.bvm_before_user_created(jsonb) to supabase_auth_admin;

-- Directory entry by user id (used for incoming messages from new senders and
-- for picking up username changes), now rate limited.
create or replace function public.get_user(p_user_id uuid)
returns table (id uuid, username text, identity_key text, signing_key text)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  perform private.hit_rate_limit(auth.uid(), 'directory', 600, interval '1 hour');
  return query
    select u.id, u.username, u.identity_key, u.signing_key
      from public.users u
     where u.id = p_user_id;
end
$$;

create or replace function public.get_account_backup()
returns table (copy_a text, copy_b text)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  perform private.hit_rate_limit(auth.uid(), 'backup_read', 10, interval '1 hour');
  return query
    select b.copy_a, b.copy_b from private.account_backups b where b.user_id = auth.uid();
end
$$;

-- Unfinished sign-ups: Auth users without a BVM account after 24 hours.
-- Accounts that were registered are never touched (they have a users row).
create or replace function private.purge_unfinished_signups()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  delete from auth.users au
   where au.created_at < now() - interval '24 hours'
     and not exists (select 1 from public.users u where u.id = au.id);
  get diagnostics v_count = row_count;
  return v_count;
end
$$;
revoke all on function private.purge_unfinished_signups() from public, anon, authenticated;

select cron.schedule(
  'bvm-purge-unfinished-signups',
  '41 * * * *',
  $$select private.purge_unfinished_signups()$$
);
