alter table public.progress_items
  add constraint progress_items_title_present
  check (char_length(btrim(title)) between 1 and 240),
  add constraint progress_items_detail_present
  check (char_length(btrim(detail)) between 1 and 2000);

revoke insert, update on public.progress_items from anon;
grant insert (
  instructor_id,
  student_id,
  category,
  status,
  title,
  current_focus,
  observed_on,
  detail,
  updated_at
) on public.progress_items to anon;
grant update (
  category,
  status,
  title,
  current_focus,
  observed_on,
  detail,
  updated_at
) on public.progress_items to anon;

create policy "demo_progress_items_insert_seed" on public.progress_items
  for insert to anon
  with check (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = progress_items.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  );

create policy "demo_progress_items_update_seed" on public.progress_items
  for update to anon
  using (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = progress_items.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  )
  with check (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = progress_items.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  );
