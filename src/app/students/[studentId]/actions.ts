"use server";

import { revalidatePath } from "next/cache";

import { DEMO_INSTRUCTOR_ID } from "@/lib/demo-instructor";
import { createServerSupabaseAnonClient } from "@/lib/supabase/server";
import {
  lessonNoteInputSchema,
  nextPlanInputSchema,
  progressItemInputSchema,
} from "@/lib/students/editing-schemas";

function formText(formData: FormData, key: string) {
  const value = formData.get(key);

  return typeof value === "string" ? value : "";
}

function failAction(message: string): never {
  throw new Error(message);
}

async function ensureDemoStudent(studentId: string) {
  const supabase = createServerSupabaseAnonClient();

  if (!supabase) {
    return {
      supabase,
      ok: false,
      message: "Supabase environment is not configured.",
    } as const;
  }

  const { data, error } = await supabase
    .from("students")
    .select("id")
    .eq("id", studentId)
    .eq("instructor_id", DEMO_INSTRUCTOR_ID)
    .maybeSingle();

  if (error) {
    return { supabase, ok: false, message: error.message } as const;
  }

  if (!data) {
    return { supabase, ok: false, message: "Student was not found." } as const;
  }

  return { supabase, ok: true, message: "" } as const;
}

export async function createLessonNoteAction(formData: FormData): Promise<void> {
  const parsed = lessonNoteInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    lessonDate: formText(formData, "lessonDate"),
    coveredMaterial: formText(formData, "coveredMaterial"),
    observations: formText(formData, "observations"),
    practiceAssigned: formText(formData, "practiceAssigned"),
    nextStepHint: formText(formData, "nextStepHint"),
  });

  if (!parsed.success) {
    failAction("Check the lesson note fields and try again.");
  }

  const { studentId, lessonDate, coveredMaterial, observations, practiceAssigned, nextStepHint } =
    parsed.data;
  const studentCheck = await ensureDemoStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const { error } = await studentCheck.supabase.from("lesson_notes").insert({
    instructor_id: DEMO_INSTRUCTOR_ID,
    student_id: studentId,
    lesson_date: lessonDate,
    covered_material: coveredMaterial,
    observations,
    practice_assigned: practiceAssigned,
    next_step_hint: nextStepHint,
  });

  if (error) {
    failAction(error.message);
  }

  revalidatePath(`/students/${studentId}`);
}

export async function saveNextLessonPlanAction(
  formData: FormData,
): Promise<void> {
  const parsed = nextPlanInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    planId: formText(formData, "planId"),
    plannedFor: formText(formData, "plannedFor"),
    priority: formText(formData, "priority"),
    nextAction: formText(formData, "nextAction"),
    detail: formText(formData, "detail"),
  });

  if (!parsed.success) {
    failAction("Check the next lesson fields and try again.");
  }

  const { studentId, planId, plannedFor, priority, nextAction, detail } = parsed.data;
  const studentCheck = await ensureDemoStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const planPayload = {
    planned_for: plannedFor,
    priority,
    next_action: nextAction,
    detail,
    updated_at: new Date().toISOString(),
  };

  if (planId) {
    const { data, error } = await studentCheck.supabase
      .from("next_lesson_plans")
      .update(planPayload)
      .eq("id", planId)
      .eq("student_id", studentId)
      .eq("instructor_id", DEMO_INSTRUCTOR_ID)
      .select("id")
      .maybeSingle();

    if (error) {
      failAction(error.message);
    }

    if (!data) {
      failAction("Next lesson plan was not found.");
    }
  } else {
    const { error } = await studentCheck.supabase.from("next_lesson_plans").insert({
      instructor_id: DEMO_INSTRUCTOR_ID,
      student_id: studentId,
      ...planPayload,
    });

    if (error) {
      failAction(error.message);
    }
  }

  revalidatePath(`/students/${studentId}`);
}

export async function saveProgressItemAction(formData: FormData): Promise<void> {
  const parsed = progressItemInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    progressItemId: formText(formData, "progressItemId"),
    category: formText(formData, "category"),
    status: formText(formData, "status"),
    title: formText(formData, "title"),
    detail: formText(formData, "detail"),
    observedOn: formText(formData, "observedOn"),
    currentFocus: formText(formData, "currentFocus"),
  });

  if (!parsed.success) {
    failAction("Check the progress fields and try again.");
  }

  const { studentId, progressItemId, category, status, title, detail, observedOn, currentFocus } =
    parsed.data;
  const studentCheck = await ensureDemoStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const progressPayload = {
    category,
    status,
    title,
    detail,
    observed_on: observedOn,
    current_focus: currentFocus,
    updated_at: new Date().toISOString(),
  };

  if (progressItemId) {
    const { data, error } = await studentCheck.supabase
      .from("progress_items")
      .update(progressPayload)
      .eq("id", progressItemId)
      .eq("student_id", studentId)
      .eq("instructor_id", DEMO_INSTRUCTOR_ID)
      .select("id")
      .maybeSingle();

    if (error) {
      failAction(error.message);
    }

    if (!data) {
      failAction("Progress item was not found.");
    }

    if (currentFocus) {
      const { error } = await studentCheck.supabase
        .from("progress_items")
        .update({
          current_focus: false,
          updated_at: new Date().toISOString(),
        })
        .eq("student_id", studentId)
        .eq("instructor_id", DEMO_INSTRUCTOR_ID)
        .neq("id", progressItemId);

      if (error) {
        failAction(error.message);
      }
    }
  } else {
    const { data, error } = await studentCheck.supabase
      .from("progress_items")
      .insert({
        instructor_id: DEMO_INSTRUCTOR_ID,
        student_id: studentId,
        ...progressPayload,
      })
      .select("id")
      .maybeSingle();

    if (error) {
      failAction(error.message);
    }

    if (currentFocus && data) {
      const { error } = await studentCheck.supabase
        .from("progress_items")
        .update({
          current_focus: false,
          updated_at: new Date().toISOString(),
        })
        .eq("student_id", studentId)
        .eq("instructor_id", DEMO_INSTRUCTOR_ID)
        .neq("id", data.id);

      if (error) {
        failAction(error.message);
      }
    }
  }

  revalidatePath(`/students/${studentId}`);
}
