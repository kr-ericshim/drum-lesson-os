alter table public.calendar_connections
  add column if not exists apple_calendar_home_url text;

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

revoke select, insert, update, delete on public.calendar_connections from anon;
revoke select, insert, update, delete on public.calendar_connections from authenticated;
revoke select, insert, update, delete on public.calendar_sync_outbox from authenticated;
revoke insert, update, delete on public.lesson_schedule_templates from authenticated;
revoke insert, update, delete on public.lesson_occurrences from authenticated;

grant select on public.calendar_connection_summaries to authenticated;
