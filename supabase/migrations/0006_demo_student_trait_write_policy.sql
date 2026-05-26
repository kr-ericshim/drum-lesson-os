alter table public.students
  add constraint students_name_present
  check (char_length(btrim(name)) between 1 and 120),
  add constraint students_profile_cue_present
  check (char_length(btrim(profile_cue)) between 1 and 240),
  add constraint students_primary_weak_point_present
  check (char_length(btrim(primary_weak_point)) between 1 and 240);

alter table public.student_traits
  add constraint student_traits_label_present
  check (char_length(btrim(label)) between 1 and 120),
  add constraint student_traits_detail_present
  check (char_length(btrim(detail)) between 1 and 1000);

revoke insert, update on public.students from anon;
grant insert (
  instructor_id,
  name,
  profile_cue,
  primary_weak_point,
  active,
  updated_at
) on public.students to anon;
grant update (
  name,
  profile_cue,
  primary_weak_point,
  active,
  updated_at
) on public.students to anon;

revoke insert, update on public.student_traits from anon;
grant insert (
  instructor_id,
  student_id,
  trait_type,
  label,
  detail,
  updated_at
) on public.student_traits to anon;
grant update (
  trait_type,
  label,
  detail,
  updated_at
) on public.student_traits to anon;

create policy "demo_students_insert_seed" on public.students
  for insert to anon
  with check (instructor_id = '11111111-1111-4111-8111-111111111111'::uuid);

create policy "demo_students_update_seed" on public.students
  for update to anon
  using (instructor_id = '11111111-1111-4111-8111-111111111111'::uuid)
  with check (instructor_id = '11111111-1111-4111-8111-111111111111'::uuid);

create policy "demo_student_traits_insert_seed" on public.student_traits
  for insert to anon
  with check (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = student_traits.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  );

create policy "demo_student_traits_update_seed" on public.student_traits
  for update to anon
  using (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = student_traits.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  )
  with check (
    instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    and exists (
      select 1
      from public.students
      where students.id = student_traits.student_id
        and students.instructor_id = '11111111-1111-4111-8111-111111111111'::uuid
    )
  );
