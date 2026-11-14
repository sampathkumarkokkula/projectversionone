-- =============================================================================
-- BVM v3: password-protected account backup. Apply after the v1 and v2
-- migrations (SQL editor: paste and run). Safe to re-run.
--
-- Lets a new (or reinstalled) phone keep the user's app passwords and
-- contact list. The phone encrypts the backup itself (AES-256-GCM, key from
-- Argon2id of the app password); the server stores two opaque copies:
-- one opens with the main password, the other with the secondary password or,
-- when there is none, with a random key nobody knows. Both copies always
-- exist and have the same size, so the server cannot tell whether a
-- secondary password exists. No messages are ever in the backup.
-- =============================================================================

create table if not exists private.account_backups (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  copy_a     text not null,
  copy_b     text not null,
  updated_at timestamptz not null default now(),
  constraint account_backups_size check (octet_length(copy_a) <= 262144 and octet_length(copy_b) <= 262144)
);
alter table private.account_backups enable row level security;

-- Only the account's current phone may replace the backup.
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
  if p_copy_a is null or p_copy_b is null or length(p_copy_a) < 64 or length(p_copy_b) < 64 then
    raise exception 'invalid backup' using errcode = '22023';
  end if;
  insert into private.account_backups (user_id, copy_a, copy_b)
  values (v_uid, p_copy_a, p_copy_b)
  on conflict (user_id) do update
    set copy_a = excluded.copy_a, copy_b = excluded.copy_b, updated_at = now();
end
$$;

-- A phone that just signed in with the e-mail code reads the backup before it
-- registers its own keys, so this needs no device key.
create or replace function public.get_account_backup()
returns table (copy_a text, copy_b text)
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
    select b.copy_a, b.copy_b from private.account_backups b where b.user_id = auth.uid();
end
$$;

revoke all on function public.put_account_backup(text, text, text) from public, anon;
revoke all on function public.get_account_backup() from public, anon;
grant execute on function public.put_account_backup(text, text, text) to authenticated;
grant execute on function public.get_account_backup() to authenticated;
