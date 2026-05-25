create policy "demo_instructors_select_seed" on public.instructors
  for select to anon
  using (id = '11111111-1111-4111-8111-111111111111'::uuid);

create policy "demo_students_select_seed" on public.students
  for select to anon
  using (instructor_id = '11111111-1111-4111-8111-111111111111'::uuid);

create policy "demo_progress_items_select_seed" on public.progress_items
  for select to anon
  using (instructor_id = '11111111-1111-4111-8111-111111111111'::uuid);

create policy "demo_student_traits_select_seed" on public.student_traits
  for select to anon
  using (instructor_id = '11111111-1111-4111-8111-111111111111'::uuid);

create policy "demo_lesson_notes_select_seed" on public.lesson_notes
  for select to anon
  using (instructor_id = '11111111-1111-4111-8111-111111111111'::uuid);

create policy "demo_assignments_select_seed" on public.assignments
  for select to anon
  using (instructor_id = '11111111-1111-4111-8111-111111111111'::uuid);

create policy "demo_next_lesson_plans_select_seed" on public.next_lesson_plans
  for select to anon
  using (instructor_id = '11111111-1111-4111-8111-111111111111'::uuid);
