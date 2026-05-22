import { createServerSupabaseClient } from "@/lib/supabase/server";

export type StudentDashboardPreview = {
  id: string;
  name: string;
  profileCue: string;
  currentFocus: string;
  weakPoint: string;
  assignmentStatus: string;
  nextAction: string;
};

type StudentPreviewRow = {
  id: string;
  name: string;
  profile_cue: string;
  current_focus: string;
  primary_weak_point: string;
  assignments: { status: string; created_at: string }[];
  next_lesson_plans: { next_action: string; priority: string; created_at: string }[];
};

export async function getStudentDashboardPreview(): Promise<{
  data: StudentDashboardPreview[];
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
        assignments(status, created_at),
        next_lesson_plans(next_action, priority, created_at)
      `,
    )
    .eq("active", true)
    .order("name", { ascending: true })
    .limit(7)
    .returns<StudentPreviewRow[]>();

  if (error) {
    return { data: [], error: error.message };
  }

  return {
    data: (data ?? []).map((student) => {
      const assignment = [...student.assignments].sort((a, b) =>
        b.created_at.localeCompare(a.created_at),
      )[0];
      const nextPlan = [...student.next_lesson_plans].sort((a, b) => {
        if (a.priority !== b.priority) {
          return a.priority === "high" ? -1 : 1;
        }

        return b.created_at.localeCompare(a.created_at);
      })[0];

      return {
        id: student.id,
        name: student.name,
        profileCue: student.profile_cue,
        currentFocus: student.current_focus,
        weakPoint: student.primary_weak_point,
        assignmentStatus: assignment?.status ?? "not_started",
        nextAction: nextPlan?.next_action ?? "Set next lesson action",
      };
    }),
    error: null,
  };
}
