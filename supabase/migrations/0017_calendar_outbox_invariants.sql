alter table public.calendar_connections
  add constraint calendar_connections_id_instructor_id_key unique (id, instructor_id);

alter table public.lesson_occurrences
  add constraint lesson_occurrences_id_instructor_id_key unique (id, instructor_id);

alter table public.calendar_sync_outbox
  add constraint calendar_sync_outbox_connection_owner_fk
  foreign key (calendar_connection_id, instructor_id)
  references public.calendar_connections(id, instructor_id)
  on delete cascade;

alter table public.calendar_sync_outbox
  add constraint calendar_sync_outbox_occurrence_owner_fk
  foreign key (lesson_occurrence_id, instructor_id)
  references public.lesson_occurrences(id, instructor_id)
  on delete cascade;
