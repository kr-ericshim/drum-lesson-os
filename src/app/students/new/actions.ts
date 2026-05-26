"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";

import { DEMO_INSTRUCTOR_ID } from "@/lib/demo-instructor";
import { createServerSupabaseAnonClient } from "@/lib/supabase/server";
import { studentProfileInputSchema } from "@/lib/students/editing-schemas";

function formText(formData: FormData, key: string) {
  const value = formData.get(key);

  return typeof value === "string" ? value : "";
}

function failAction(message: string): never {
  throw new Error(message);
}

export async function createStudentAction(formData: FormData): Promise<void> {
  const parsed = studentProfileInputSchema.safeParse({
    studentId: "",
    name: formText(formData, "name"),
    profileCue: formText(formData, "profileCue"),
    primaryWeakPoint: formText(formData, "primaryWeakPoint"),
    active: "on",
  });

  if (!parsed.success) {
    failAction("Check the student profile fields and try again.");
  }

  const supabase = createServerSupabaseAnonClient();

  if (!supabase) {
    failAction("Supabase environment is not configured.");
  }

  const { name, profileCue, primaryWeakPoint } = parsed.data;
  const { data, error } = await supabase
    .from("students")
    .insert({
      instructor_id: DEMO_INSTRUCTOR_ID,
      name,
      profile_cue: profileCue,
      primary_weak_point: primaryWeakPoint,
      active: true,
      updated_at: new Date().toISOString(),
    })
    .select("id")
    .maybeSingle();

  if (error) {
    failAction(error.message);
  }

  if (!data) {
    failAction("Student could not be created.");
  }

  revalidatePath("/");
  redirect(`/students/${data.id}`);
}
