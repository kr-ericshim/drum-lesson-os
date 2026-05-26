"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";

import { loadCurrentInstructor } from "@/lib/auth/instructor";
import { studentProfileInputSchema } from "@/lib/students/editing-schemas";

function formText(formData: FormData, key: string) {
  const value = formData.get(key);

  return typeof value === "string" ? value : "";
}

function failAction(message: string): never {
  throw new Error(message);
}

function createStudentSlug(name: string) {
  const base = name
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40);

  return `${base || "student"}-${Date.now().toString(36)}`;
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

  const instructorResult = await loadCurrentInstructor();

  const supabase = instructorResult.supabase;

  if (!instructorResult.ok || !supabase) {
    failAction(
      instructorResult.ok
        ? "Supabase environment is not configured."
        : instructorResult.message,
    );
  }

  const { name, profileCue, primaryWeakPoint } = parsed.data;
  const slug = createStudentSlug(name);
  const { data, error } = await supabase
    .from("students")
    .insert({
      instructor_id: instructorResult.instructor.id,
      slug,
      name,
      profile_cue: profileCue,
      primary_weak_point: primaryWeakPoint,
      active: true,
      updated_at: new Date().toISOString(),
    })
    .select("id, slug")
    .maybeSingle();

  if (error) {
    failAction(error.message);
  }

  if (!data) {
    failAction("Student could not be created.");
  }

  revalidatePath("/");
  redirect(`/students/${data.slug}`);
}
