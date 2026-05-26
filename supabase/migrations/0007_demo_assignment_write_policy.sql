alter table public.assignments
  add constraint assignments_title_present
  check (char_length(btrim(title)) between 1 and 160),
  add constraint assignments_detail_present
  check (char_length(btrim(detail)) between 1 and 1000);

revoke insert, update on public.assignments from anon;
grant insert (
  instructor_id,
  student_id,
  title,
  status,
  due_date,
  detail,
  updated_at
) on public.assignments to anon;
grant update (
  title,
  status,
  due_date,
  detail,
  updated_at
) on public.assignments to anon;

create policy "demo_assignments_insert_seed" on public.assignments
  for insert to anon
  with check (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = assignments.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  );

create policy "demo_assignments_update_seed" on public.assignments
  for update to anon
  using (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = assignments.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  )
  with check (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = assignments.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  );
