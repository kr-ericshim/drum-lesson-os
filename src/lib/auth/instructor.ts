type SupabaseAuthUser = {
  id: string;
};

type InstructorRow = {
  id: string;
  display_name: string;
  studio_name: string | null;
};

type InstructorClient = {
  auth: {
    getUser: () => Promise<{
      data: { user: SupabaseAuthUser | null };
      error: Error | null;
    }>;
  };
  from: (table: "instructors") => {
    select: (columns: "id, display_name, studio_name") => {
      eq: (
        column: "auth_user_id",
        value: string,
      ) => {
        maybeSingle: () => Promise<{
          data: InstructorRow | null;
          error: Error | null;
        }>;
      };
    };
  };
};

export type CurrentInstructor = {
  id: string;
  displayName: string;
  studioName: string | null;
};

export type CurrentInstructorResult =
  | {
      ok: true;
      instructor: CurrentInstructor;
    }
  | {
      ok: false;
      reason: "missing_supabase" | "signed_out" | "instructor_not_found" | "query_error";
      message: string;
    };

export async function getCurrentInstructor(
  supabase: InstructorClient | null,
): Promise<CurrentInstructorResult> {
  if (!supabase) {
    return {
      ok: false,
      reason: "missing_supabase",
      message: "Supabase environment is not configured.",
    };
  }

  const { data: userData, error: userError } = await supabase.auth.getUser();

  if (userError || !userData.user) {
    return {
      ok: false,
      reason: "signed_out",
      message: "Sign in to access Drum Lesson OS.",
    };
  }

  const { data, error } = await supabase
    .from("instructors")
    .select("id, display_name, studio_name")
    .eq("auth_user_id", userData.user.id)
    .maybeSingle();

  if (error) {
    return {
      ok: false,
      reason: "query_error",
      message: error.message,
    };
  }

  if (!data) {
    return {
      ok: false,
      reason: "instructor_not_found",
      message: "No instructor profile is linked to this login.",
    };
  }

  return {
    ok: true,
    instructor: {
      id: data.id,
      displayName: data.display_name,
      studioName: data.studio_name,
    },
  };
}

export async function loadCurrentInstructor() {
  const { createServerSupabaseClient } = await import("../supabase/server");
  const supabase = await createServerSupabaseClient();
  const result = await getCurrentInstructor(supabase as unknown as InstructorClient | null);

  return {
    ...result,
    supabase,
  };
}
