create or replace function public.closeout_lesson(
  target_student_id uuid,
  closeout_lesson_date date,
  closeout_covered_material text,
  closeout_observations text,
  closeout_practice_assigned text,
  closeout_next_step_hint text,
  target_next_plan_id uuid,
  closeout_next_action text,
  closeout_next_plan_detail text,
  closeout_planned_for date,
  closeout_priority text,
  target_assignment_id uuid,
  closeout_assignment_title text,
  closeout_assignment_status text,
  closeout_assignment_due_date date,
  closeout_assignment_detail text,
  target_progress_item_id uuid,
  closeout_progress_status text,
  closeout_progress_current_focus boolean
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_instructor_id uuid;
  updated_at_value timestamptz := now();
begin
  select id
    into current_instructor_id
  from public.instructors
  where auth_user_id = (select auth.uid());

  if current_instructor_id is null then
    raise exception 'Instructor was not found.';
  end if;

  if not exists (
    select 1
    from public.students
    where id = target_student_id
      and instructor_id = current_instructor_id
  ) then
    raise exception 'Student was not found.';
  end if;

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
    current_instructor_id,
    target_student_id,
    closeout_lesson_date,
    closeout_covered_material,
    closeout_observations,
    closeout_practice_assigned,
    closeout_next_step_hint
  );

  if target_next_plan_id is not null then
    update public.next_lesson_plans
    set
      planned_for = closeout_planned_for,
      priority = closeout_priority,
      next_action = closeout_next_action,
      detail = coalesce(nullif(closeout_next_plan_detail, ''), detail),
      updated_at = updated_at_value
    where id = target_next_plan_id
      and student_id = target_student_id
      and instructor_id = current_instructor_id;

    if not found then
      raise exception 'Next lesson plan was not found.';
    end if;
  else
    insert into public.next_lesson_plans (
      instructor_id,
      student_id,
      planned_for,
      priority,
      next_action,
      detail,
      updated_at
    )
    values (
      current_instructor_id,
      target_student_id,
      closeout_planned_for,
      closeout_priority,
      closeout_next_action,
      coalesce(nullif(closeout_next_plan_detail, ''), closeout_next_action),
      updated_at_value
    );
  end if;

  if nullif(closeout_assignment_title, '') is not null
    and closeout_assignment_status is not null
    and nullif(closeout_assignment_detail, '') is not null then
    if target_assignment_id is not null then
      update public.assignments
      set
        title = closeout_assignment_title,
        status = closeout_assignment_status,
        due_date = closeout_assignment_due_date,
        detail = closeout_assignment_detail,
        updated_at = updated_at_value
      where id = target_assignment_id
        and student_id = target_student_id
        and instructor_id = current_instructor_id;

      if not found then
        raise exception 'Assignment was not found.';
      end if;
    else
      insert into public.assignments (
        instructor_id,
        student_id,
        title,
        status,
        due_date,
        detail,
        updated_at
      )
      values (
        current_instructor_id,
        target_student_id,
        closeout_assignment_title,
        closeout_assignment_status,
        closeout_assignment_due_date,
        closeout_assignment_detail,
        updated_at_value
      );
    end if;
  end if;

  if target_progress_item_id is not null
    and (closeout_progress_status is not null or closeout_progress_current_focus) then
    if not exists (
      select 1
      from public.progress_items
      where id = target_progress_item_id
        and student_id = target_student_id
        and instructor_id = current_instructor_id
    ) then
      raise exception 'Progress item was not found.';
    end if;

    if closeout_progress_current_focus then
      update public.progress_items
      set
        current_focus = false,
        updated_at = updated_at_value
      where student_id = target_student_id
        and instructor_id = current_instructor_id
        and id <> target_progress_item_id;
    end if;

    update public.progress_items
    set
      status = coalesce(closeout_progress_status, status),
      current_focus = case
        when closeout_progress_current_focus then true
        else current_focus
      end,
      updated_at = updated_at_value
    where id = target_progress_item_id
      and student_id = target_student_id
      and instructor_id = current_instructor_id;

    if not found then
      raise exception 'Progress item was not found.';
    end if;
  end if;
end;
$$;

revoke execute on function public.closeout_lesson(
  uuid,
  date,
  text,
  text,
  text,
  text,
  uuid,
  text,
  text,
  date,
  text,
  uuid,
  text,
  text,
  date,
  text,
  uuid,
  text,
  boolean
) from public;

grant execute on function public.closeout_lesson(
  uuid,
  date,
  text,
  text,
  text,
  text,
  uuid,
  text,
  text,
  date,
  text,
  uuid,
  text,
  text,
  date,
  text,
  uuid,
  text,
  boolean
) to authenticated;
