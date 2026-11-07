-- Minimal stand-ins for the Supabase-specific objects the BVM migration uses,
-- so the migration and the RLS tests can run on a plain local PostgreSQL.
-- Validation only: never run this against a Supabase project.

create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
grant usage on schema public to anon, authenticated, service_role;

-- Supabase grants table privileges in public to the API roles by default.
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;

create schema auth;
create table auth.users (id uuid primary key, email text);
-- Same contract as Supabase: the JWT subject of the current request.
create function auth.uid() returns uuid
language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;

create schema extensions;
grant usage on schema extensions to anon, authenticated, service_role;

create schema vault;
create table vault.secrets (
  id uuid primary key default gen_random_uuid(),
  name text unique,
  secret text not null,
  description text
);
create view vault.decrypted_secrets as
  select id, name, secret as decrypted_secret, description from vault.secrets;
create function vault.create_secret(new_secret text, new_name text default null, new_description text default '')
returns uuid language sql
as $$ insert into vault.secrets (name, secret, description) values (new_name, new_secret, new_description) returning id $$;

create publication supabase_realtime;

create schema cron;
create function cron.schedule(job_name text, schedule text, command text) returns bigint
language sql as $$ select 1::bigint $$;
