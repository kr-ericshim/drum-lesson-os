import { createServerSupabaseClient } from "@/lib/supabase/server";
import {
  mapStudentDetail,
  mapStudentRoster,
  type StudentDetail,
  type StudentDetailSourceRow,
  type StudentRosterItem,
  type StudentRosterSourceRow,
} from "@/lib/supabase/read-models";

export type { StudentDetail, StudentRosterItem } from "@/lib/supabase/read-models";

export type StudentDashboardPreview = StudentRosterItem;

export async function getStudentRoster(): Promise<{
  data: StudentRosterItem[];
  error: string | null;
}> {
  const supabase = await createServerSupabaseClient();

  if (!supabase) {
    return { data: [], error: "Supabase environment is not configured." };
  }

  const { data, error } = await supabase
    .from("students")
    .select(
      `
        id,
        slug,
        name,
        profile_cue,
        primary_weak_point,
        progress_items(id, category, status, title, current_focus, observed_on, detail, tempo_note),
        assignments(id, status, created_at, title, due_date, detail),
        lesson_notes(lesson_date),
        next_lesson_plans(id, next_action, priority, created_at, updated_at, planned_for, detail)
      `,
    )
    .eq("active", true)
    .order("name", { ascending: true })
    .returns<StudentRosterSourceRow[]>();

  if (error) {
    return { data: [], error: error.message };
  }

  return {
    data: mapStudentRoster(data ?? []),
    error: null,
  };
}

export async function getStudentDashboardPreview() {
  return getStudentRoster();
}

export async function getStudentDetail(studentRef: string): Promise<{
  data: StudentDetail | null;
  error: string | null;
}> {
  const supabase = await createServerSupabaseClient();

  if (!supabase) {
    return { data: null, error: "Supabase environment is not configured." };
  }

  let query = supabase
    .from("students")
    .select(
      `
        id,
        slug,
        name,
        profile_cue,
        primary_weak_point,
        progress_items(id, category, status, title, current_focus, observed_on, detail, tempo_note),
        student_traits(id, trait_type, label, detail),
        assignments(id, status, created_at, title, due_date, detail),
        next_lesson_plans(id, next_action, priority, created_at, updated_at, planned_for, detail),
        lesson_notes(id, lesson_date, created_at, covered_material, observations, practice_assigned, next_step_hint)
      `,
    )
    .eq("active", true);

  query = isUuid(studentRef) ? query.eq("id", studentRef) : query.eq("slug", studentRef);

  const { data, error } = await query.maybeSingle().returns<StudentDetailSourceRow | null>();

  if (error) {
    return { data: null, error: error.message };
  }

  return {
    data: data ? mapStudentDetail(data) : null,
    error: null,
  };
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
    value,
  );
}
