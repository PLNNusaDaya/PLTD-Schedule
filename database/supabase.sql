-- PLTD ENGINEERING SCHEDULE v2 · GUEST (READ ONLY) + ADMIN (WRITE)
-- Supabase > SQL Editor; execute as project owner.
-- IMPORTANT: public schedule/history/evidence will be readable by ANYONE with your site URL.
-- Admin passwords are managed by Supabase Authentication, NEVER in GitHub.
-- This creates NEW v2 tables/bucket; legacy v1 app_state / pltd-evidence remain unchanged.

-- 1. Admin allowlist. Only dashboard SQL editor / privileged backend can add admins.
create table if not exists public.pltd_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.pltd_admins enable row level security;
revoke all on table public.pltd_admins from anon, authenticated;
grant select on table public.pltd_admins to authenticated;
drop policy if exists pltd_admin_select_self on public.pltd_admins;
create policy pltd_admin_select_self on public.pltd_admins
  for select to authenticated using (user_id = (select auth.uid()));

-- 2. One canonical, published project schedule (guests read, allowlisted admins write).
create table if not exists public.pltd_public_schedule (
  id text primary key default 'main' check (id = 'main'),
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.pltd_public_schedule enable row level security;
revoke all on table public.pltd_public_schedule from anon, authenticated;
grant select on table public.pltd_public_schedule to anon, authenticated;
grant insert, update on table public.pltd_public_schedule to authenticated;

create or replace function public.pltd_touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
drop trigger if exists pltd_updated_at on public.pltd_public_schedule;
create trigger pltd_updated_at before update on public.pltd_public_schedule
  for each row execute function public.pltd_touch_updated_at();

drop policy if exists pltd_schedule_public_read on public.pltd_public_schedule;
create policy pltd_schedule_public_read on public.pltd_public_schedule
  for select to anon, authenticated using (true);
drop policy if exists pltd_schedule_admin_insert on public.pltd_public_schedule;
create policy pltd_schedule_admin_insert on public.pltd_public_schedule
  for insert to authenticated with check (
    exists (select 1 from public.pltd_admins where user_id = (select auth.uid()))
  );
drop policy if exists pltd_schedule_admin_update on public.pltd_public_schedule;
create policy pltd_schedule_admin_update on public.pltd_public_schedule
  for update to authenticated
  using (exists (select 1 from public.pltd_admins where user_id = (select auth.uid())))
  with check (exists (select 1 from public.pltd_admins where user_id = (select auth.uid())));

-- 3. Public evidence files, because guests may view/download attached proof documents.
-- Only admins may write/delete file objects. Files are PUBLIC by design.
insert into storage.buckets (id, name, public, file_size_limit)
values ('pltd-schedule-evidence', 'pltd-schedule-evidence', true, 15728640)
on conflict (id) do update set public = true, file_size_limit = 15728640;

drop policy if exists pltd_public_evidence_insert_admin on storage.objects;
create policy pltd_public_evidence_insert_admin on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'pltd-schedule-evidence'
    and exists (select 1 from public.pltd_admins where user_id = (select auth.uid()))
  );

drop policy if exists pltd_public_evidence_update_admin on storage.objects;
create policy pltd_public_evidence_update_admin on storage.objects
  for update to authenticated
  using (
    bucket_id = 'pltd-schedule-evidence'
    and exists (select 1 from public.pltd_admins where user_id = (select auth.uid()))
  )
  with check (
    bucket_id = 'pltd-schedule-evidence'
    and exists (select 1 from public.pltd_admins where user_id = (select auth.uid()))
  );

drop policy if exists pltd_public_evidence_delete_admin on storage.objects;
create policy pltd_public_evidence_delete_admin on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'pltd-schedule-evidence'
    and exists (select 1 from public.pltd_admins where user_id = (select auth.uid()))
  );

-- Guest file downloads work using /storage/v1/object/public/<bucket>/<path>.
-- No guest insert/update/delete policy is provided.

-- 4. MANUAL ADMIN SETUP (RUN AFTER creating your Admin user in Authentication > Users)
-- IMPORTANT: replace the email below and run this SEPARATELY in SQL Editor:
-- insert into public.pltd_admins (user_id)
-- select id from auth.users where lower(email) = lower('EMAIL_ADMIN_ANDA@CONTOH.COM')
-- on conflict (user_id) do nothing;
-- Verify:
-- select a.user_id,u.email from public.pltd_admins a join auth.users u on u.id=a.user_id;
