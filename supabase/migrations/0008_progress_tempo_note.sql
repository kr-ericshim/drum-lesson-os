alter table public.progress_items
  add column if not exists tempo_note text;

alter table public.progress_items
  drop constraint if exists progress_items_tempo_note_length;

alter table public.progress_items
  add constraint progress_items_tempo_note_length
  check (tempo_note is null or char_length(tempo_note) <= 240);
