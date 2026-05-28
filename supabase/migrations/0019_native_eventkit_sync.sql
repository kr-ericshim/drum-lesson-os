alter table public.lesson_occurrences
  add column if not exists native_calendar_event_identifier text,
  add column if not exists native_calendar_identifier text,
  add column if not exists native_calendar_external_identifier text,
  add column if not exists native_calendar_sync_status text not null default 'not_connected'
    check (native_calendar_sync_status in ('not_connected', 'pending', 'synced', 'failed', 'disabled')),
  add column if not exists native_calendar_sync_error text,
  add column if not exists native_calendar_synced_at timestamptz;

create index if not exists lesson_occurrences_native_calendar_sync_idx
  on public.lesson_occurrences (instructor_id, native_calendar_sync_status, starts_at);

grant select (
  native_calendar_event_identifier,
  native_calendar_identifier,
  native_calendar_external_identifier,
  native_calendar_sync_status,
  native_calendar_sync_error,
  native_calendar_synced_at
) on public.lesson_occurrences to authenticated;
