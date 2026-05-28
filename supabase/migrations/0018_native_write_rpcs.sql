alter table public.lesson_occurrences
  add column if not exists native_calendar_event_identifier text,
  add column if not exists native_calendar_identifier text,
  add column if not exists native_calendar_external_identifier text,
  add column if not exists native_calendar_sync_status text not null default 'not_connected'
    check (native_calendar_sync_status in ('not_connected', 'pending', 'synced', 'failed', 'disabled')),
  add column if not exists native_calendar_sync_error text,
  add column if not exists native_calendar_synced_at timestamptz;

create or replace function public.native_current_instructor_id()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_instructor_id uuid;
begin
  select id
  into current_instructor_id
  from public.instructors
  where auth_user_id = (select auth.uid());

  if current_instructor_id is null then
    raise exception 'Instructor was not found.';
  end if;

  return current_instructor_id;
end;
$$;

create or replace function public.native_create_student(
  p_name text,
  p_profile_cue text,
  p_primary_weak_point text,
  p_active boolean default true
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
  v_student_id uuid := gen_random_uuid();
begin
  return query
  insert into public.students (
    id,
    instructor_id,
    name,
    profile_cue,
    primary_weak_point,
    active,
    slug
  )
  values (
    v_student_id,
    v_instructor_id,
    p_name,
    p_profile_cue,
    p_primary_weak_point,
    p_active,
    'student-' || left(v_student_id::text, 8)
  )
  returning public.students.id, public.students.updated_at;
end;
$$;

create or replace function public.native_update_student_profile(
  p_student_id uuid,
  p_name text,
  p_profile_cue text,
  p_primary_weak_point text,
  p_active boolean
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  return query
  update public.students
  set
    name = p_name,
    profile_cue = p_profile_cue,
    primary_weak_point = p_primary_weak_point,
    active = p_active,
    updated_at = now()
  where public.students.id = p_student_id
    and public.students.instructor_id = v_instructor_id
  returning public.students.id, public.students.updated_at;

  if not found then
    raise exception 'Student was not found.';
  end if;
end;
$$;

create or replace function public.native_upsert_student_trait(
  p_student_id uuid,
  p_trait_type text,
  p_label text,
  p_detail text,
  p_trait_id uuid default null
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  perform 1
  from public.students
  where students.id = p_student_id
    and students.instructor_id = v_instructor_id;

  if not found then
    raise exception 'Student was not found.';
  end if;

  if p_trait_id is null then
    return query
    insert into public.student_traits (
      instructor_id,
      student_id,
      trait_type,
      label,
      detail
    )
    values (
      v_instructor_id,
      p_student_id,
      p_trait_type,
      p_label,
      p_detail
    )
    returning public.student_traits.id, public.student_traits.updated_at;
    return;
  end if;

  return query
  update public.student_traits
  set
    trait_type = p_trait_type,
    label = p_label,
    detail = p_detail,
    updated_at = now()
  where public.student_traits.id = p_trait_id
    and public.student_traits.student_id = p_student_id
    and public.student_traits.instructor_id = v_instructor_id
  returning public.student_traits.id, public.student_traits.updated_at;

  if not found then
    raise exception 'Trait was not found.';
  end if;
end;
$$;

create or replace function public.native_upsert_progress_item(
  p_student_id uuid,
  p_category text,
  p_status text,
  p_title text,
  p_detail text,
  p_observed_on date,
  p_current_focus boolean default false,
  p_tempo_note text default null,
  p_progress_item_id uuid default null
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  perform 1
  from public.students
  where students.id = p_student_id
    and students.instructor_id = v_instructor_id;

  if not found then
    raise exception 'Student was not found.';
  end if;

  if p_current_focus then
    update public.progress_items
    set
      current_focus = false,
      updated_at = now()
    where progress_items.student_id = p_student_id
      and progress_items.instructor_id = v_instructor_id
      and (p_progress_item_id is null or progress_items.id <> p_progress_item_id);
  end if;

  if p_progress_item_id is null then
    return query
    insert into public.progress_items (
      instructor_id,
      student_id,
      category,
      status,
      title,
      detail,
      tempo_note,
      observed_on,
      current_focus
    )
    values (
      v_instructor_id,
      p_student_id,
      p_category,
      p_status,
      p_title,
      p_detail,
      p_tempo_note,
      p_observed_on,
      p_current_focus
    )
    returning public.progress_items.id, public.progress_items.updated_at;
    return;
  end if;

  return query
  update public.progress_items
  set
    category = p_category,
    status = p_status,
    title = p_title,
    detail = p_detail,
    tempo_note = p_tempo_note,
    observed_on = p_observed_on,
    current_focus = p_current_focus,
    updated_at = now()
  where public.progress_items.id = p_progress_item_id
    and public.progress_items.student_id = p_student_id
    and public.progress_items.instructor_id = v_instructor_id
  returning public.progress_items.id, public.progress_items.updated_at;

  if not found then
    raise exception 'Progress item was not found.';
  end if;
end;
$$;

create or replace function public.native_update_progress_status(
  p_student_id uuid,
  p_progress_item_id uuid,
  p_status text
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  return query
  update public.progress_items
  set
    status = p_status,
    updated_at = now()
  where public.progress_items.id = p_progress_item_id
    and public.progress_items.student_id = p_student_id
    and public.progress_items.instructor_id = v_instructor_id
  returning public.progress_items.id, public.progress_items.updated_at;

  if not found then
    raise exception 'Progress item was not found.';
  end if;
end;
$$;

create or replace function public.native_upsert_assignment(
  p_student_id uuid,
  p_title text,
  p_status text,
  p_due_date date,
  p_detail text,
  p_assignment_id uuid default null
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  perform 1
  from public.students
  where students.id = p_student_id
    and students.instructor_id = v_instructor_id;

  if not found then
    raise exception 'Student was not found.';
  end if;

  if p_assignment_id is null then
    return query
    insert into public.assignments (
      instructor_id,
      student_id,
      title,
      status,
      due_date,
      detail
    )
    values (
      v_instructor_id,
      p_student_id,
      p_title,
      p_status,
      p_due_date,
      p_detail
    )
    returning public.assignments.id, public.assignments.updated_at;
    return;
  end if;

  return query
  update public.assignments
  set
    title = p_title,
    status = p_status,
    due_date = p_due_date,
    detail = p_detail,
    updated_at = now()
  where public.assignments.id = p_assignment_id
    and public.assignments.student_id = p_student_id
    and public.assignments.instructor_id = v_instructor_id
  returning public.assignments.id, public.assignments.updated_at;

  if not found then
    raise exception 'Assignment was not found.';
  end if;
end;
$$;

create or replace function public.native_create_lesson_note(
  p_student_id uuid,
  p_lesson_date date,
  p_covered_material text,
  p_observations text,
  p_practice_assigned text,
  p_next_step_hint text
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  perform 1
  from public.students
  where students.id = p_student_id
    and students.instructor_id = v_instructor_id;

  if not found then
    raise exception 'Student was not found.';
  end if;

  return query
  insert into public.lesson_notes (
    instructor_id,
    student_id,
    lesson_date,
    covered_material,
    observations,
    practice_assigned,
    next_step_hint
  )
  values (
    v_instructor_id,
    p_student_id,
    p_lesson_date,
    p_covered_material,
    p_observations,
    p_practice_assigned,
    p_next_step_hint
  )
  returning public.lesson_notes.id, public.lesson_notes.updated_at;
end;
$$;

create or replace function public.native_upsert_next_lesson_plan(
  p_student_id uuid,
  p_planned_for date,
  p_priority text,
  p_next_action text,
  p_detail text,
  p_next_lesson_plan_id uuid default null
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  perform 1
  from public.students
  where students.id = p_student_id
    and students.instructor_id = v_instructor_id;

  if not found then
    raise exception 'Student was not found.';
  end if;

  if p_next_lesson_plan_id is null then
    return query
    insert into public.next_lesson_plans (
      instructor_id,
      student_id,
      planned_for,
      priority,
      next_action,
      detail
    )
    values (
      v_instructor_id,
      p_student_id,
      p_planned_for,
      p_priority,
      p_next_action,
      p_detail
    )
    returning public.next_lesson_plans.id, public.next_lesson_plans.updated_at;
    return;
  end if;

  return query
  update public.next_lesson_plans
  set
    planned_for = p_planned_for,
    priority = p_priority,
    next_action = p_next_action,
    detail = p_detail,
    updated_at = now()
  where public.next_lesson_plans.id = p_next_lesson_plan_id
    and public.next_lesson_plans.student_id = p_student_id
    and public.next_lesson_plans.instructor_id = v_instructor_id
  returning public.next_lesson_plans.id, public.next_lesson_plans.updated_at;

  if not found then
    raise exception 'Next lesson plan was not found.';
  end if;
end;
$$;

create or replace function public.native_create_one_off_occurrence(
  p_student_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_timezone text,
  p_title text,
  p_native_calendar_sync_status text default 'pending'
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  perform 1
  from public.students
  where students.id = p_student_id
    and students.instructor_id = v_instructor_id;

  if not found then
    raise exception 'Student was not found.';
  end if;

  return query
  insert into public.lesson_occurrences (
    instructor_id,
    student_id,
    starts_at,
    ends_at,
    timezone,
    title,
    native_calendar_sync_status
  )
  values (
    v_instructor_id,
    p_student_id,
    p_starts_at,
    p_ends_at,
    p_timezone,
    p_title,
    p_native_calendar_sync_status
  )
  returning public.lesson_occurrences.id, public.lesson_occurrences.updated_at;
end;
$$;

create or replace function public.native_create_weekly_schedule_template(
  p_student_id uuid,
  p_title text,
  p_default_duration_minutes integer,
  p_timezone text,
  p_starts_on date,
  p_start_time time,
  p_ends_on date default null,
  p_recurrence_interval integer default 1,
  p_recurrence_weekday integer default null
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  perform 1
  from public.students
  where students.id = p_student_id
    and students.instructor_id = v_instructor_id;

  if not found then
    raise exception 'Student was not found.';
  end if;

  return query
  insert into public.lesson_schedule_templates (
    instructor_id,
    student_id,
    title,
    default_duration_minutes,
    timezone,
    recurrence_kind,
    recurrence_interval,
    recurrence_weekday,
    starts_on,
    ends_on,
    start_time
  )
  values (
    v_instructor_id,
    p_student_id,
    p_title,
    p_default_duration_minutes,
    p_timezone,
    'weekly',
    p_recurrence_interval,
    coalesce(p_recurrence_weekday, extract(dow from p_starts_on)::integer),
    p_starts_on,
    p_ends_on,
    p_start_time
  )
  returning public.lesson_schedule_templates.id, public.lesson_schedule_templates.updated_at;
end;
$$;

create or replace function public.native_insert_expanded_occurrences(
  p_occurrences jsonb
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
  v_occurrence jsonb;
  v_student_id uuid;
  v_schedule_template_id uuid;
begin
  if jsonb_typeof(p_occurrences) <> 'array' then
    raise exception 'Occurrences must be a JSON array.';
  end if;

  for v_occurrence in
    select value from jsonb_array_elements(p_occurrences)
  loop
    v_student_id := (v_occurrence ->> 'student_id')::uuid;
    v_schedule_template_id := nullif(v_occurrence ->> 'schedule_template_id', '')::uuid;

    perform 1
    from public.students
    where students.id = v_student_id
      and students.instructor_id = v_instructor_id;

    if not found then
      raise exception 'Student was not found.';
    end if;

    if v_schedule_template_id is not null then
      perform 1
      from public.lesson_schedule_templates
      where lesson_schedule_templates.id = v_schedule_template_id
        and lesson_schedule_templates.instructor_id = v_instructor_id;

      if not found then
        raise exception 'Schedule template was not found.';
      end if;
    end if;

    return query
    insert into public.lesson_occurrences (
      instructor_id,
      student_id,
      schedule_template_id,
      starts_at,
      ends_at,
      timezone,
      status,
      title,
      native_calendar_sync_status
    )
    values (
      v_instructor_id,
      v_student_id,
      v_schedule_template_id,
      (v_occurrence ->> 'starts_at')::timestamptz,
      (v_occurrence ->> 'ends_at')::timestamptz,
      v_occurrence ->> 'timezone',
      coalesce(nullif(v_occurrence ->> 'status', ''), 'scheduled'),
      v_occurrence ->> 'title',
      coalesce(nullif(v_occurrence ->> 'native_calendar_sync_status', ''), 'pending')
    )
    returning public.lesson_occurrences.id, public.lesson_occurrences.updated_at;
  end loop;
end;
$$;

create or replace function public.native_edit_occurrence_time(
  p_occurrence_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_timezone text,
  p_native_calendar_sync_status text default 'pending'
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  return query
  update public.lesson_occurrences
  set
    starts_at = p_starts_at,
    ends_at = p_ends_at,
    timezone = p_timezone,
    native_calendar_sync_status = p_native_calendar_sync_status,
    native_calendar_sync_error = null,
    updated_at = now()
  where public.lesson_occurrences.id = p_occurrence_id
    and public.lesson_occurrences.instructor_id = v_instructor_id
  returning public.lesson_occurrences.id, public.lesson_occurrences.updated_at;

  if not found then
    raise exception 'Lesson occurrence was not found.';
  end if;
end;
$$;

create or replace function public.native_cancel_occurrence(
  p_occurrence_id uuid,
  p_native_calendar_sync_status text default 'pending',
  p_native_calendar_sync_error text default null
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  return query
  update public.lesson_occurrences
  set
    status = 'canceled',
    native_calendar_sync_status = p_native_calendar_sync_status,
    native_calendar_sync_error = p_native_calendar_sync_error,
    updated_at = now()
  where public.lesson_occurrences.id = p_occurrence_id
    and public.lesson_occurrences.instructor_id = v_instructor_id
  returning public.lesson_occurrences.id, public.lesson_occurrences.updated_at;

  if not found then
    raise exception 'Lesson occurrence was not found.';
  end if;
end;
$$;

create or replace function public.native_update_occurrence_calendar_sync(
  p_occurrence_id uuid,
  p_native_calendar_sync_status text,
  p_native_calendar_event_identifier text default null,
  p_native_calendar_identifier text default null,
  p_native_calendar_external_identifier text default null,
  p_native_calendar_sync_error text default null,
  p_native_calendar_synced_at timestamptz default null
)
returns table (id uuid, updated_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instructor_id uuid := public.native_current_instructor_id();
begin
  return query
  update public.lesson_occurrences
  set
    native_calendar_event_identifier = p_native_calendar_event_identifier,
    native_calendar_identifier = p_native_calendar_identifier,
    native_calendar_external_identifier = p_native_calendar_external_identifier,
    native_calendar_sync_status = p_native_calendar_sync_status,
    native_calendar_sync_error = p_native_calendar_sync_error,
    native_calendar_synced_at = p_native_calendar_synced_at,
    updated_at = now()
  where public.lesson_occurrences.id = p_occurrence_id
    and public.lesson_occurrences.instructor_id = v_instructor_id
  returning public.lesson_occurrences.id, public.lesson_occurrences.updated_at;

  if not found then
    raise exception 'Lesson occurrence was not found.';
  end if;
end;
$$;

revoke execute on function public.native_current_instructor_id() from public;
revoke execute on function public.native_create_student(text, text, text, boolean) from public;
revoke execute on function public.native_update_student_profile(uuid, text, text, text, boolean) from public;
revoke execute on function public.native_upsert_student_trait(uuid, text, text, text, uuid) from public;
revoke execute on function public.native_upsert_progress_item(uuid, text, text, text, text, date, boolean, text, uuid) from public;
revoke execute on function public.native_update_progress_status(uuid, uuid, text) from public;
revoke execute on function public.native_upsert_assignment(uuid, text, text, date, text, uuid) from public;
revoke execute on function public.native_create_lesson_note(uuid, date, text, text, text, text) from public;
revoke execute on function public.native_upsert_next_lesson_plan(uuid, date, text, text, text, uuid) from public;
revoke execute on function public.native_create_one_off_occurrence(uuid, timestamptz, timestamptz, text, text, text) from public;
revoke execute on function public.native_create_weekly_schedule_template(uuid, text, integer, text, date, time, date, integer, integer) from public;
revoke execute on function public.native_insert_expanded_occurrences(jsonb) from public;
revoke execute on function public.native_edit_occurrence_time(uuid, timestamptz, timestamptz, text, text) from public;
revoke execute on function public.native_cancel_occurrence(uuid, text, text) from public;
revoke execute on function public.native_update_occurrence_calendar_sync(uuid, text, text, text, text, text, timestamptz) from public;

revoke execute on function public.native_current_instructor_id() from anon;
revoke execute on function public.native_create_student(text, text, text, boolean) from anon;
revoke execute on function public.native_update_student_profile(uuid, text, text, text, boolean) from anon;
revoke execute on function public.native_upsert_student_trait(uuid, text, text, text, uuid) from anon;
revoke execute on function public.native_upsert_progress_item(uuid, text, text, text, text, date, boolean, text, uuid) from anon;
revoke execute on function public.native_update_progress_status(uuid, uuid, text) from anon;
revoke execute on function public.native_upsert_assignment(uuid, text, text, date, text, uuid) from anon;
revoke execute on function public.native_create_lesson_note(uuid, date, text, text, text, text) from anon;
revoke execute on function public.native_upsert_next_lesson_plan(uuid, date, text, text, text, uuid) from anon;
revoke execute on function public.native_create_one_off_occurrence(uuid, timestamptz, timestamptz, text, text, text) from anon;
revoke execute on function public.native_create_weekly_schedule_template(uuid, text, integer, text, date, time, date, integer, integer) from anon;
revoke execute on function public.native_insert_expanded_occurrences(jsonb) from anon;
revoke execute on function public.native_edit_occurrence_time(uuid, timestamptz, timestamptz, text, text) from anon;
revoke execute on function public.native_cancel_occurrence(uuid, text, text) from anon;
revoke execute on function public.native_update_occurrence_calendar_sync(uuid, text, text, text, text, text, timestamptz) from anon;

grant execute on function public.native_current_instructor_id() to authenticated;
grant execute on function public.native_create_student(text, text, text, boolean) to authenticated;
grant execute on function public.native_update_student_profile(uuid, text, text, text, boolean) to authenticated;
grant execute on function public.native_upsert_student_trait(uuid, text, text, text, uuid) to authenticated;
grant execute on function public.native_upsert_progress_item(uuid, text, text, text, text, date, boolean, text, uuid) to authenticated;
grant execute on function public.native_update_progress_status(uuid, uuid, text) to authenticated;
grant execute on function public.native_upsert_assignment(uuid, text, text, date, text, uuid) to authenticated;
grant execute on function public.native_create_lesson_note(uuid, date, text, text, text, text) to authenticated;
grant execute on function public.native_upsert_next_lesson_plan(uuid, date, text, text, text, uuid) to authenticated;
grant execute on function public.native_create_one_off_occurrence(uuid, timestamptz, timestamptz, text, text, text) to authenticated;
grant execute on function public.native_create_weekly_schedule_template(uuid, text, integer, text, date, time, date, integer, integer) to authenticated;
grant execute on function public.native_insert_expanded_occurrences(jsonb) to authenticated;
grant execute on function public.native_edit_occurrence_time(uuid, timestamptz, timestamptz, text, text) to authenticated;
grant execute on function public.native_cancel_occurrence(uuid, text, text) to authenticated;
grant execute on function public.native_update_occurrence_calendar_sync(uuid, text, text, text, text, text, timestamptz) to authenticated;
