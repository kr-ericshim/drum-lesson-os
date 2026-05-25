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
        name,
        profile_cue,
        current_focus,
        primary_weak_point,
        assignments(status, created_at, title, due_date, detail),
        next_lesson_plans(id, next_action, priority, created_at)
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

export async function getStudentDetail(studentId: string): Promise<{
  data: StudentDetail | null;
  error: string | null;
}> {
  const supabase = await createServerSupabaseClient();

  if (!supabase) {
    return { data: null, error: "Supabase environment is not configured." };
  }

  const { data, error } = await supabase
    .from("students")
    .select(
      `
        id,
        name,
        profile_cue,
        current_focus,
        primary_weak_point,
        progress_items(id, category, status, title, current_focus, observed_on, detail),
        student_traits(id, trait_type, label, detail),
        assignments(status, created_at, title, due_date, detail),
        next_lesson_plans(id, next_action, priority, created_at, planned_for, detail),
        lesson_notes(id, lesson_date, covered_material, observations, practice_assigned, next_step_hint)
      `,
    )
    .eq("id", studentId)
    .eq("active", true)
    .maybeSingle()
    .returns<StudentDetailSourceRow | null>();

  if (error) {
    return { data: null, error: error.message };
  }

  return {
    data: data ? mapStudentDetail(data) : null,
    error: null,
  };
}
