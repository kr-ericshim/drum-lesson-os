alter table public.lesson_notes
  add constraint lesson_notes_covered_material_present
  check (char_length(btrim(covered_material)) between 1 and 2000),
  add constraint lesson_notes_observations_present
  check (char_length(btrim(observations)) between 1 and 2000),
  add constraint lesson_notes_practice_assigned_present
  check (char_length(btrim(practice_assigned)) between 1 and 2000),
  add constraint lesson_notes_next_step_hint_present
  check (char_length(btrim(next_step_hint)) between 1 and 1000);

alter table public.next_lesson_plans
  add constraint next_lesson_plans_next_action_present
  check (char_length(btrim(next_action)) between 1 and 240),
  add constraint next_lesson_plans_detail_present
  check (char_length(btrim(detail)) between 1 and 2000);

revoke insert on public.lesson_notes from anon;
grant insert (
  instructor_id,
  student_id,
  lesson_date,
  covered_material,
  observations,
  practice_assigned,
  next_step_hint
) on public.lesson_notes to anon;

revoke insert, update on public.next_lesson_plans from anon;
grant insert (
  instructor_id,
  student_id,
  planned_for,
  priority,
  next_action,
  detail,
  updated_at
) on public.next_lesson_plans to anon;
grant update (
  planned_for,
  priority,
  next_action,
  detail,
  updated_at
) on public.next_lesson_plans to anon;

create policy "demo_lesson_notes_insert_seed" on public.lesson_notes
  for insert to anon
  with check (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = lesson_notes.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  );

create policy "demo_next_lesson_plans_insert_seed" on public.next_lesson_plans
  for insert to anon
  with check (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = next_lesson_plans.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  );

create policy "demo_next_lesson_plans_update_seed" on public.next_lesson_plans
  for update to anon
  using (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = next_lesson_plans.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  )
  with check (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = next_lesson_plans.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  );
