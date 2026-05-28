create table if not exists public.lesson_schedule_templates (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.instructors(id) on delete cascade,
  student_id uuid not null,
  title text not null,
  default_duration_minutes integer not null check (default_duration_minutes between 15 and 240),
  timezone text not null,
  recurrence_kind text not null default 'none' check (recurrence_kind in ('none', 'weekly')),
  recurrence_interval integer not null default 1 check (recurrence_interval between 1 and 12),
  recurrence_weekday integer check (recurrence_weekday between 0 and 6),
  starts_on date not null,
  ends_on date,
  start_time time not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (student_id, instructor_id) references public.students(id, instructor_id) on delete cascade
);

create table if not exists public.lesson_occurrences (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.instructors(id) on delete cascade,
  student_id uuid not null,
  schedule_template_id uuid references public.lesson_schedule_templates(id) on delete set null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  timezone text not null,
  status text not null default 'scheduled' check (status in ('scheduled', 'completed', 'canceled')),
  title text not null,
  apple_calendar_event_uid text,
  apple_calendar_event_href text,
  apple_calendar_etag text,
  apple_sync_status text not null default 'not_connected' check (apple_sync_status in ('not_connected', 'pending', 'synced', 'failed', 'disabled')),
  apple_sync_error text,
  apple_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at),
  foreign key (student_id, instructor_id) references public.students(id, instructor_id) on delete cascade
);

create table if not exists public.calendar_connections (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.instructors(id) on delete cascade,
  provider text not null default 'apple_caldav' check (provider = 'apple_caldav'),
  account_label text not null,
  apple_principal_url text,
  apple_calendar_home_url text,
  apple_calendar_url text,
  apple_calendar_display_name text,
  username text not null,
  encrypted_app_password text not null,
  status text not null default 'connected' check (status in ('connected', 'needs_attention', 'disabled')),
  last_checked_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.calendar_sync_outbox (
  id uuid primary key default gen_random_uuid(),
  instructor_id uuid not null references public.instructors(id) on delete cascade,
  calendar_connection_id uuid not null references public.calendar_connections(id) on delete cascade,
  lesson_occurrence_id uuid not null references public.lesson_occurrences(id) on delete cascade,
  operation text not null check (operation in ('create', 'update', 'delete')),
  status text not null default 'pending' check (status in ('pending', 'processing', 'succeeded', 'failed')),
  attempt_count integer not null default 0 check (attempt_count >= 0),
  next_attempt_at timestamptz not null default now(),
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists lesson_schedule_templates_owner_idx
  on public.lesson_schedule_templates (instructor_id, student_id, active, starts_on);
create index if not exists lesson_occurrences_owner_range_idx
  on public.lesson_occurrences (instructor_id, starts_at, status);
create index if not exists lesson_occurrences_template_start_idx
  on public.lesson_occurrences (schedule_template_id, starts_at);
create index if not exists calendar_connections_owner_status_idx
  on public.calendar_connections (instructor_id, status);
create index if not exists calendar_sync_outbox_due_idx
  on public.calendar_sync_outbox (status, next_attempt_at, created_at);

alter table public.lesson_schedule_templates enable row level security;
alter table public.lesson_occurrences enable row level security;
alter table public.calendar_connections enable row level security;
alter table public.calendar_sync_outbox enable row level security;

create policy "lesson_schedule_templates_select_owner" on public.lesson_schedule_templates
  for select to authenticated using (public.student_owner_can_access(instructor_id));
create policy "lesson_schedule_templates_insert_owner" on public.lesson_schedule_templates
  for insert to authenticated with check (public.student_owner_can_access(instructor_id));
create policy "lesson_schedule_templates_update_owner" on public.lesson_schedule_templates
  for update to authenticated
  using (public.student_owner_can_access(instructor_id))
  with check (public.student_owner_can_access(instructor_id));
create policy "lesson_schedule_templates_delete_owner" on public.lesson_schedule_templates
  for delete to authenticated using (public.student_owner_can_access(instructor_id));

create policy "lesson_occurrences_select_owner" on public.lesson_occurrences
  for select to authenticated using (public.student_owner_can_access(instructor_id));
create policy "lesson_occurrences_insert_owner" on public.lesson_occurrences
  for insert to authenticated with check (public.student_owner_can_access(instructor_id));
create policy "lesson_occurrences_update_owner" on public.lesson_occurrences
  for update to authenticated
  using (public.student_owner_can_access(instructor_id))
  with check (public.student_owner_can_access(instructor_id));
create policy "lesson_occurrences_delete_owner" on public.lesson_occurrences
  for delete to authenticated using (public.student_owner_can_access(instructor_id));

create policy "calendar_connections_select_owner" on public.calendar_connections
  for select to authenticated using (public.student_owner_can_access(instructor_id));
create policy "calendar_connections_insert_owner" on public.calendar_connections
  for insert to authenticated with check (public.student_owner_can_access(instructor_id));
create policy "calendar_connections_update_owner" on public.calendar_connections
  for update to authenticated
  using (public.student_owner_can_access(instructor_id))
  with check (public.student_owner_can_access(instructor_id));
create policy "calendar_connections_delete_owner" on public.calendar_connections
  for delete to authenticated using (public.student_owner_can_access(instructor_id));

create policy "calendar_sync_outbox_select_owner" on public.calendar_sync_outbox
  for select to authenticated using (public.student_owner_can_access(instructor_id));
create policy "calendar_sync_outbox_insert_owner" on public.calendar_sync_outbox
  for insert to authenticated with check (public.student_owner_can_access(instructor_id));
create policy "calendar_sync_outbox_update_owner" on public.calendar_sync_outbox
  for update to authenticated
  using (public.student_owner_can_access(instructor_id))
  with check (public.student_owner_can_access(instructor_id));
create policy "calendar_sync_outbox_delete_owner" on public.calendar_sync_outbox
  for delete to authenticated using (public.student_owner_can_access(instructor_id));

create or replace view public.calendar_connection_summaries as
  select
    id,
    instructor_id,
    account_label,
    apple_calendar_display_name,
    status,
    last_checked_at,
    last_error,
    created_at,
    updated_at
  from public.calendar_connections
  where public.student_owner_can_access(instructor_id);

revoke all on public.calendar_connection_summaries from anon;
revoke all on public.calendar_connection_summaries from authenticated;

revoke select, insert, update, delete on public.lesson_schedule_templates from anon;
revoke select, insert, update, delete on public.lesson_occurrences from anon;
revoke select, insert, update, delete on public.calendar_connections from anon;
revoke select, insert, update, delete on public.calendar_sync_outbox from anon;

revoke select, insert, update, delete on public.lesson_schedule_templates from authenticated;
revoke select, insert, update, delete on public.lesson_occurrences from authenticated;
revoke select, insert, update, delete on public.calendar_connections from authenticated;
revoke select, insert, update, delete on public.calendar_sync_outbox from authenticated;

grant select on public.lesson_schedule_templates to authenticated;

grant select (
  id,
  instructor_id,
  student_id,
  schedule_template_id,
  starts_at,
  ends_at,
  timezone,
  status,
  title,
  apple_sync_status,
  apple_sync_error,
  apple_synced_at,
  created_at,
  updated_at
) on public.lesson_occurrences to authenticated;

grant select on public.calendar_connection_summaries to authenticated;
