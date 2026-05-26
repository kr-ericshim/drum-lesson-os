alter table public.instructors
  add column if not exists auth_user_id uuid;

create unique index if not exists instructors_auth_user_id_idx
  on public.instructors (auth_user_id)
  where auth_user_id is not null;

revoke select, insert, update, delete on public.instructors from anon;
revoke select, insert, update, delete on public.students from anon;
revoke select, insert, update, delete on public.progress_items from anon;
revoke select, insert, update, delete on public.student_traits from anon;
revoke select, insert, update, delete on public.lesson_notes from anon;
revoke select, insert, update, delete on public.assignments from anon;
revoke select, insert, update, delete on public.next_lesson_plans from anon;

drop policy if exists "demo_instructors_select_seed" on public.instructors;
drop policy if exists "demo_students_select_seed" on public.students;
drop policy if exists "demo_progress_items_select_seed" on public.progress_items;
drop policy if exists "demo_student_traits_select_seed" on public.student_traits;
drop policy if exists "demo_lesson_notes_select_seed" on public.lesson_notes;
drop policy if exists "demo_assignments_select_seed" on public.assignments;
drop policy if exists "demo_next_lesson_plans_select_seed" on public.next_lesson_plans;
drop policy if exists "demo_lesson_notes_insert_seed" on public.lesson_notes;
drop policy if exists "demo_next_lesson_plans_insert_seed" on public.next_lesson_plans;
drop policy if exists "demo_next_lesson_plans_update_seed" on public.next_lesson_plans;
drop policy if exists "demo_progress_items_insert_seed" on public.progress_items;
drop policy if exists "demo_progress_items_update_seed" on public.progress_items;
drop policy if exists "demo_students_insert_seed" on public.students;
drop policy if exists "demo_students_update_seed" on public.students;
drop policy if exists "demo_student_traits_insert_seed" on public.student_traits;
drop policy if exists "demo_student_traits_update_seed" on public.student_traits;
drop policy if exists "demo_assignments_insert_seed" on public.assignments;
drop policy if exists "demo_assignments_update_seed" on public.assignments;

drop policy if exists "instructors_select_own" on public.instructors;
drop policy if exists "instructors_insert_own" on public.instructors;
drop policy if exists "instructors_update_own" on public.instructors;
drop policy if exists "instructors_delete_own" on public.instructors;
drop policy if exists "students_select_own" on public.students;
drop policy if exists "students_insert_own" on public.students;
drop policy if exists "students_update_own" on public.students;
drop policy if exists "students_delete_own" on public.students;
drop policy if exists "progress_items_select_own" on public.progress_items;
drop policy if exists "progress_items_insert_own" on public.progress_items;
drop policy if exists "progress_items_update_own" on public.progress_items;
drop policy if exists "progress_items_delete_own" on public.progress_items;
drop policy if exists "student_traits_select_own" on public.student_traits;
drop policy if exists "student_traits_insert_own" on public.student_traits;
drop policy if exists "student_traits_update_own" on public.student_traits;
drop policy if exists "student_traits_delete_own" on public.student_traits;
drop policy if exists "lesson_notes_select_own" on public.lesson_notes;
drop policy if exists "lesson_notes_insert_own" on public.lesson_notes;
drop policy if exists "lesson_notes_update_own" on public.lesson_notes;
drop policy if exists "lesson_notes_delete_own" on public.lesson_notes;
drop policy if exists "assignments_select_own" on public.assignments;
drop policy if exists "assignments_insert_own" on public.assignments;
drop policy if exists "assignments_update_own" on public.assignments;
drop policy if exists "assignments_delete_own" on public.assignments;
drop policy if exists "next_lesson_plans_select_own" on public.next_lesson_plans;
drop policy if exists "next_lesson_plans_insert_own" on public.next_lesson_plans;
drop policy if exists "next_lesson_plans_update_own" on public.next_lesson_plans;
drop policy if exists "next_lesson_plans_delete_own" on public.next_lesson_plans;

create or replace function public.student_owner_can_access(target_instructor_id uuid)
returns boolean
language sql
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.instructors
    where id = target_instructor_id
      and auth_user_id = (select auth.uid())
  );
$$;

create policy "instructors_select_owner" on public.instructors
  for select to authenticated using (auth_user_id = (select auth.uid()));
create policy "instructors_insert_owner" on public.instructors
  for insert to authenticated with check (auth_user_id = (select auth.uid()));
create policy "instructors_update_owner" on public.instructors
  for update to authenticated
  using (auth_user_id = (select auth.uid()))
  with check (auth_user_id = (select auth.uid()));
create policy "instructors_delete_owner" on public.instructors
  for delete to authenticated using (auth_user_id = (select auth.uid()));

create policy "students_select_owner" on public.students
  for select to authenticated using (public.student_owner_can_access(instructor_id));
create policy "students_insert_owner" on public.students
  for insert to authenticated with check (public.student_owner_can_access(instructor_id));
create policy "students_update_owner" on public.students
  for update to authenticated
  using (public.student_owner_can_access(instructor_id))
  with check (public.student_owner_can_access(instructor_id));
create policy "students_delete_owner" on public.students
  for delete to authenticated using (public.student_owner_can_access(instructor_id));

create policy "progress_items_select_owner" on public.progress_items
  for select to authenticated using (public.student_owner_can_access(instructor_id));
create policy "progress_items_insert_owner" on public.progress_items
  for insert to authenticated with check (public.student_owner_can_access(instructor_id));
create policy "progress_items_update_owner" on public.progress_items
  for update to authenticated
  using (public.student_owner_can_access(instructor_id))
  with check (public.student_owner_can_access(instructor_id));
create policy "progress_items_delete_owner" on public.progress_items
  for delete to authenticated using (public.student_owner_can_access(instructor_id));

create policy "student_traits_select_owner" on public.student_traits
  for select to authenticated using (public.student_owner_can_access(instructor_id));
create policy "student_traits_insert_owner" on public.student_traits
  for insert to authenticated with check (public.student_owner_can_access(instructor_id));
create policy "student_traits_update_owner" on public.student_traits
  for update to authenticated
  using (public.student_owner_can_access(instructor_id))
  with check (public.student_owner_can_access(instructor_id));
create policy "student_traits_delete_owner" on public.student_traits
  for delete to authenticated using (public.student_owner_can_access(instructor_id));

create policy "lesson_notes_select_owner" on public.lesson_notes
  for select to authenticated using (public.student_owner_can_access(instructor_id));
create policy "lesson_notes_insert_owner" on public.lesson_notes
  for insert to authenticated with check (public.student_owner_can_access(instructor_id));
create policy "lesson_notes_update_owner" on public.lesson_notes
  for update to authenticated
  using (public.student_owner_can_access(instructor_id))
  with check (public.student_owner_can_access(instructor_id));
create policy "lesson_notes_delete_owner" on public.lesson_notes
  for delete to authenticated using (public.student_owner_can_access(instructor_id));

create policy "assignments_select_owner" on public.assignments
  for select to authenticated using (public.student_owner_can_access(instructor_id));
create policy "assignments_insert_owner" on public.assignments
  for insert to authenticated with check (public.student_owner_can_access(instructor_id));
create policy "assignments_update_owner" on public.assignments
  for update to authenticated
  using (public.student_owner_can_access(instructor_id))
  with check (public.student_owner_can_access(instructor_id));
create policy "assignments_delete_owner" on public.assignments
  for delete to authenticated using (public.student_owner_can_access(instructor_id));

create policy "next_lesson_plans_select_owner" on public.next_lesson_plans
  for select to authenticated using (public.student_owner_can_access(instructor_id));
create policy "next_lesson_plans_insert_owner" on public.next_lesson_plans
  for insert to authenticated with check (public.student_owner_can_access(instructor_id));
create policy "next_lesson_plans_update_owner" on public.next_lesson_plans
  for update to authenticated
  using (public.student_owner_can_access(instructor_id))
  with check (public.student_owner_can_access(instructor_id));
create policy "next_lesson_plans_delete_owner" on public.next_lesson_plans
  for delete to authenticated using (public.student_owner_can_access(instructor_id));
