"use server";

import { revalidatePath } from "next/cache";

import { loadCurrentInstructor } from "@/lib/auth/instructor";
import {
  assignmentInputSchema,
  lessonNoteInputSchema,
  lessonCloseoutInputSchema,
  markAssignmentNeedsReviewInputSchema,
  nextPlanInputSchema,
  quickLessonNoteInputSchema,
  quickNextActionInputSchema,
  isProgressStatusTransitionAllowed,
  progressStatusTransitionInputSchema,
  progressItemInputSchema,
  studentProfileInputSchema,
  studentTraitInputSchema,
} from "@/lib/students/editing-schemas";

function formText(formData: FormData, key: string) {
  const value = formData.get(key);

  return typeof value === "string" ? value : "";
}

function failAction(message: string): never {
  throw new Error(message);
}

function getTodayDateInputValue() {
  const parts = new Intl.DateTimeFormat("en", {
    day: "2-digit",
    month: "2-digit",
    timeZone: "Asia/Seoul",
    year: "numeric",
  }).formatToParts(new Date());

  const partByType = new Map(parts.map((part) => [part.type, part.value]));

  return `${partByType.get("year")}-${partByType.get("month")}-${partByType.get("day")}`;
}

async function ensureOwnedStudent(studentId: string) {
  const instructorResult = await loadCurrentInstructor();
  const supabase = instructorResult.supabase;

  if (!instructorResult.ok || !supabase) {
    return {
      supabase,
      ok: false,
      message: instructorResult.ok
        ? "Supabase environment is not configured."
        : instructorResult.message,
    } as const;
  }

  const { data, error } = await supabase
    .from("students")
    .select("id, slug")
    .eq("id", studentId)
    .eq("instructor_id", instructorResult.instructor.id)
    .maybeSingle();

  if (error) {
    return { supabase, ok: false, message: error.message } as const;
  }

  if (!data) {
    return {
      supabase,
      ok: false,
      message: "Student was not found.",
    } as const;
  }

  return {
    supabase,
    instructorId: instructorResult.instructor.id,
    ok: true,
    message: "",
    slug: data.slug as string | null,
  } as const;
}

function revalidateStudentPaths(studentId: string, studentSlug?: string | null) {
  revalidatePath("/");
  revalidatePath(`/students/${studentId}`);

  if (studentSlug) {
    revalidatePath(`/students/${studentSlug}`);
  }
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
  const studentCheck = await ensureOwnedStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const { error } = await studentCheck.supabase.from("lesson_notes").insert({
    instructor_id: studentCheck.instructorId,
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

  revalidateStudentPaths(studentId, studentCheck.slug);
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
  const studentCheck = await ensureOwnedStudent(studentId);

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
      .eq("instructor_id", studentCheck.instructorId)
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
      instructor_id: studentCheck.instructorId,
      student_id: studentId,
      ...planPayload,
    });

    if (error) {
      failAction(error.message);
    }
  }

  revalidateStudentPaths(studentId, studentCheck.slug);
}

export async function saveProgressItemAction(formData: FormData): Promise<void> {
  const parsed = progressItemInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    progressItemId: formText(formData, "progressItemId"),
    category: formText(formData, "category"),
    status: formText(formData, "status"),
    title: formText(formData, "title"),
    detail: formText(formData, "detail"),
    tempoNote: formText(formData, "tempoNote"),
    observedOn: formText(formData, "observedOn"),
    currentFocus: formText(formData, "currentFocus"),
  });

  if (!parsed.success) {
    failAction("Check the progress fields and try again.");
  }

  const { studentId, progressItemId, category, status, title, detail, tempoNote, observedOn, currentFocus } = parsed.data;
  const studentCheck = await ensureOwnedStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const updatedAt = new Date().toISOString();
  const progressPayload = {
    category,
    status,
    title,
    detail,
    tempo_note: tempoNote || null,
    observed_on: observedOn,
    current_focus: currentFocus,
    updated_at: updatedAt,
  };

  if (progressItemId) {
    if (currentFocus) {
      const { data: existingProgressItem, error: existingProgressItemError } =
        await studentCheck.supabase
          .from("progress_items")
          .select("id")
          .eq("id", progressItemId)
          .eq("student_id", studentId)
          .eq("instructor_id", studentCheck.instructorId)
          .maybeSingle();

      if (existingProgressItemError) {
        failAction(existingProgressItemError.message);
      }

      if (!existingProgressItem) {
        failAction("Progress item was not found.");
      }

      const { error: clearFocusError } = await studentCheck.supabase
        .from("progress_items")
        .update({
          current_focus: false,
          updated_at: updatedAt,
        })
        .eq("student_id", studentId)
        .eq("instructor_id", studentCheck.instructorId)
        .neq("id", progressItemId);

      if (clearFocusError) {
        failAction(clearFocusError.message);
      }
    }

    const { data, error } = await studentCheck.supabase
      .from("progress_items")
      .update(progressPayload)
      .eq("id", progressItemId)
      .eq("student_id", studentId)
      .eq("instructor_id", studentCheck.instructorId)
      .select("id")
      .maybeSingle();

    if (error) {
      failAction(error.message);
    }

    if (!data) {
      failAction("Progress item was not found.");
    }
  } else {
    const { data, error } = await studentCheck.supabase
      .from("progress_items")
      .insert({
        instructor_id: studentCheck.instructorId,
        student_id: studentId,
        ...progressPayload,
        current_focus: false,
      })
      .select("id")
      .maybeSingle();

    if (error) {
      failAction(error.message);
    }

    if (currentFocus && data) {
      const { error: clearFocusError } = await studentCheck.supabase
        .from("progress_items")
        .update({
          current_focus: false,
          updated_at: updatedAt,
        })
        .eq("student_id", studentId)
        .eq("instructor_id", studentCheck.instructorId)
        .neq("id", data.id);

      if (clearFocusError) {
        failAction(clearFocusError.message);
      }

      const { error: setFocusError } = await studentCheck.supabase
        .from("progress_items")
        .update({
          current_focus: true,
          updated_at: updatedAt,
        })
        .eq("id", data.id)
        .eq("student_id", studentId)
        .eq("instructor_id", studentCheck.instructorId);

      if (setFocusError) {
        failAction(setFocusError.message);
      }
    }
  }

  revalidateStudentPaths(studentId, studentCheck.slug);
}

export async function saveProgressItemStatusAction(formData: FormData): Promise<void> {
  const parsed = progressStatusTransitionInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    progressItemId: formText(formData, "progressItemId"),
    nextStatus: formText(formData, "nextStatus"),
  });

  if (!parsed.success) {
    failAction("Check the progress status and try again.");
  }

  const { studentId, progressItemId, nextStatus } = parsed.data;
  const studentCheck = await ensureOwnedStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const { data: progressItem, error: progressItemError } = await studentCheck.supabase
    .from("progress_items")
    .select("status")
    .eq("id", progressItemId)
    .eq("student_id", studentId)
    .eq("instructor_id", studentCheck.instructorId)
    .maybeSingle();

  if (progressItemError) {
    failAction(progressItemError.message);
  }

  if (!progressItem) {
    failAction("Progress item was not found.");
  }

  if (!isProgressStatusTransitionAllowed(progressItem.status, nextStatus)) {
    failAction("That status transition is not available from the progress list.");
  }

  const { data, error } = await studentCheck.supabase
    .from("progress_items")
    .update({
      status: nextStatus,
      updated_at: new Date().toISOString(),
    })
    .eq("id", progressItemId)
    .eq("student_id", studentId)
    .eq("instructor_id", studentCheck.instructorId)
    .select("id")
    .maybeSingle();

  if (error) {
    failAction(error.message);
  }

  if (!data) {
    failAction("Progress item was not found.");
  }

  revalidateStudentPaths(studentId, studentCheck.slug);
}

export async function saveStudentProfileAction(formData: FormData): Promise<void> {
  const parsed = studentProfileInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    name: formText(formData, "name"),
    profileCue: formText(formData, "profileCue"),
    primaryWeakPoint: formText(formData, "primaryWeakPoint"),
    active: formText(formData, "active"),
  });

  if (!parsed.success) {
    failAction("Check the student profile fields and try again.");
  }

  const { studentId, name, profileCue, primaryWeakPoint, active } = parsed.data;

  if (!studentId) {
    failAction("Student was not found.");
  }

  const studentCheck = await ensureOwnedStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const { data, error } = await studentCheck.supabase
    .from("students")
    .update({
      name,
      profile_cue: profileCue,
      primary_weak_point: primaryWeakPoint,
      active,
      updated_at: new Date().toISOString(),
    })
    .eq("id", studentId)
    .eq("instructor_id", studentCheck.instructorId)
    .select("id")
    .maybeSingle();

  if (error) {
    failAction(error.message);
  }

  if (!data) {
    failAction("Student was not found.");
  }

  revalidateStudentPaths(studentId, studentCheck.slug);
}

export async function saveStudentTraitAction(formData: FormData): Promise<void> {
  const parsed = studentTraitInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    traitId: formText(formData, "traitId"),
    type: formText(formData, "type"),
    label: formText(formData, "label"),
    detail: formText(formData, "detail"),
  });

  if (!parsed.success) {
    failAction("Check the trait fields and try again.");
  }

  const { studentId, traitId, type, label, detail } = parsed.data;
  const studentCheck = await ensureOwnedStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const traitPayload = {
    trait_type: type,
    label,
    detail,
    updated_at: new Date().toISOString(),
  };

  if (traitId) {
    const { data, error } = await studentCheck.supabase
      .from("student_traits")
      .update(traitPayload)
      .eq("id", traitId)
      .eq("student_id", studentId)
      .eq("instructor_id", studentCheck.instructorId)
      .select("id")
      .maybeSingle();

    if (error) {
      failAction(error.message);
    }

    if (!data) {
      failAction("Trait was not found.");
    }
  } else {
    const { error } = await studentCheck.supabase.from("student_traits").insert({
      instructor_id: studentCheck.instructorId,
      student_id: studentId,
      ...traitPayload,
    });

    if (error) {
      failAction(error.message);
    }
  }

  revalidateStudentPaths(studentId, studentCheck.slug);
}

export async function saveAssignmentAction(formData: FormData): Promise<void> {
  const parsed = assignmentInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    assignmentId: formText(formData, "assignmentId"),
    title: formText(formData, "title"),
    status: formText(formData, "status"),
    dueDate: formText(formData, "dueDate"),
    detail: formText(formData, "detail"),
  });

  if (!parsed.success) {
    failAction("Check the assignment fields and try again.");
  }

  const { studentId, assignmentId, title, status, dueDate, detail } = parsed.data;
  const studentCheck = await ensureOwnedStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const assignmentPayload = {
    title,
    status,
    due_date: dueDate,
    detail,
    updated_at: new Date().toISOString(),
  };

  if (assignmentId) {
    const { data, error } = await studentCheck.supabase
      .from("assignments")
      .update(assignmentPayload)
      .eq("id", assignmentId)
      .eq("student_id", studentId)
      .eq("instructor_id", studentCheck.instructorId)
      .select("id")
      .maybeSingle();

    if (error) {
      failAction(error.message);
    }

    if (!data) {
      failAction("Assignment was not found.");
    }
  } else {
    const { error } = await studentCheck.supabase.from("assignments").insert({
      instructor_id: studentCheck.instructorId,
      student_id: studentId,
      ...assignmentPayload,
    });

    if (error) {
      failAction(error.message);
    }
  }

  revalidateStudentPaths(studentId, studentCheck.slug);
}

export async function createQuickLessonNoteAction(formData: FormData): Promise<void> {
  const parsed = quickLessonNoteInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    coveredMaterial: formText(formData, "coveredMaterial"),
    observation: formText(formData, "observation"),
    practiceAssigned: formText(formData, "practiceAssigned"),
    nextStepHint: formText(formData, "nextStepHint"),
  });

  if (!parsed.success) {
    failAction("Add a short observation and try again.");
  }

  const { studentId, coveredMaterial, observation, practiceAssigned, nextStepHint } = parsed.data;
  const studentCheck = await ensureOwnedStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const { error } = await studentCheck.supabase.from("lesson_notes").insert({
    instructor_id: studentCheck.instructorId,
    student_id: studentId,
    lesson_date: getTodayDateInputValue(),
    covered_material: coveredMaterial,
    observations: observation,
    practice_assigned: practiceAssigned,
    next_step_hint: nextStepHint,
  });

  if (error) {
    failAction(error.message);
  }

  revalidateStudentPaths(studentId, studentCheck.slug);
}

export async function saveQuickNextActionAction(formData: FormData): Promise<void> {
  const parsed = quickNextActionInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    planId: formText(formData, "planId"),
    nextAction: formText(formData, "nextAction"),
  });

  if (!parsed.success) {
    failAction("Add a next action and try again.");
  }

  const { studentId, planId, nextAction } = parsed.data;
  const studentCheck = await ensureOwnedStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const updatedAt = new Date().toISOString();
  const updatePayload = {
    next_action: nextAction,
    updated_at: updatedAt,
  };

  if (planId) {
    const { data, error } = await studentCheck.supabase
      .from("next_lesson_plans")
      .update(updatePayload)
      .eq("id", planId)
      .eq("student_id", studentId)
      .eq("instructor_id", studentCheck.instructorId)
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
      instructor_id: studentCheck.instructorId,
      student_id: studentId,
      detail: nextAction,
      planned_for: null,
      priority: "normal",
      ...updatePayload,
    });

    if (error) {
      failAction(error.message);
    }
  }

  revalidateStudentPaths(studentId, studentCheck.slug);
}

export async function markAssignmentNeedsReviewAction(formData: FormData): Promise<void> {
  const parsed = markAssignmentNeedsReviewInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    assignmentId: formText(formData, "assignmentId"),
  });

  if (!parsed.success) {
    failAction("Assignment was not found.");
  }

  const { studentId, assignmentId } = parsed.data;
  const studentCheck = await ensureOwnedStudent(studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const { data, error } = await studentCheck.supabase
    .from("assignments")
    .update({
      status: "needs_review",
      updated_at: new Date().toISOString(),
    })
    .eq("id", assignmentId)
    .eq("student_id", studentId)
    .eq("instructor_id", studentCheck.instructorId)
    .select("id")
    .maybeSingle();

  if (error) {
    failAction(error.message);
  }

  if (!data) {
    failAction("Assignment was not found.");
  }

  revalidateStudentPaths(studentId, studentCheck.slug);
}

export async function closeoutLessonAction(formData: FormData): Promise<void> {
  const parsed = lessonCloseoutInputSchema.safeParse({
    studentId: formText(formData, "studentId"),
    lessonDate: formText(formData, "lessonDate"),
    coveredMaterial: formText(formData, "coveredMaterial"),
    observations: formText(formData, "observations"),
    practiceAssigned: formText(formData, "practiceAssigned"),
    nextStepHint: formText(formData, "nextStepHint"),
    nextPlanId: formText(formData, "nextPlanId"),
    nextAction: formText(formData, "nextAction"),
    nextPlanDetail: formText(formData, "nextPlanDetail"),
    plannedFor: formText(formData, "plannedFor"),
    priority: formText(formData, "priority"),
    assignmentId: formText(formData, "assignmentId"),
    assignmentTitle: formText(formData, "assignmentTitle"),
    assignmentStatus: formText(formData, "assignmentStatus"),
    assignmentDueDate: formText(formData, "assignmentDueDate"),
    assignmentDetail: formText(formData, "assignmentDetail"),
    progressItemId: formText(formData, "progressItemId"),
    progressStatus: formText(formData, "progressStatus"),
    progressCurrentFocus: formText(formData, "progressCurrentFocus"),
  });

  if (!parsed.success) {
    failAction("Check the closeout fields and try again.");
  }

  const input = parsed.data;
  const studentCheck = await ensureOwnedStudent(input.studentId);

  if (!studentCheck.ok) {
    failAction(studentCheck.message);
  }

  const updatedAt = new Date().toISOString();
  const { error: noteError } = await studentCheck.supabase.from("lesson_notes").insert({
    instructor_id: studentCheck.instructorId,
    student_id: input.studentId,
    lesson_date: input.lessonDate,
    covered_material: input.coveredMaterial,
    observations: input.observations,
    practice_assigned: input.practiceAssigned,
    next_step_hint: input.nextStepHint,
  });

  if (noteError) {
    failAction(noteError.message);
  }

  const nextPlanPayload: {
    planned_for: string | null;
    priority: string;
    next_action: string;
    detail?: string;
    updated_at: string;
  } = {
    planned_for: input.plannedFor,
    priority: input.priority,
    next_action: input.nextAction,
    updated_at: updatedAt,
  };

  if (input.nextPlanDetail) {
    nextPlanPayload.detail = input.nextPlanDetail;
  }

  if (input.nextPlanId) {
    const { data, error } = await studentCheck.supabase
      .from("next_lesson_plans")
      .update(nextPlanPayload)
      .eq("id", input.nextPlanId)
      .eq("student_id", input.studentId)
      .eq("instructor_id", studentCheck.instructorId)
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
      instructor_id: studentCheck.instructorId,
      student_id: input.studentId,
      ...nextPlanPayload,
      detail: input.nextPlanDetail || input.nextAction,
    });

    if (error) {
      failAction(error.message);
    }
  }

  if (input.assignmentTitle && input.assignmentStatus && input.assignmentDetail) {
    const assignmentPayload = {
      title: input.assignmentTitle,
      status: input.assignmentStatus,
      due_date: input.assignmentDueDate,
      detail: input.assignmentDetail,
      updated_at: updatedAt,
    };

    if (input.assignmentId) {
      const { data, error } = await studentCheck.supabase
        .from("assignments")
        .update(assignmentPayload)
        .eq("id", input.assignmentId)
        .eq("student_id", input.studentId)
        .eq("instructor_id", studentCheck.instructorId)
        .select("id")
        .maybeSingle();

      if (error) {
        failAction(error.message);
      }

      if (!data) {
        failAction("Assignment was not found.");
      }
    } else {
      const { error } = await studentCheck.supabase.from("assignments").insert({
        instructor_id: studentCheck.instructorId,
        student_id: input.studentId,
        ...assignmentPayload,
      });

      if (error) {
        failAction(error.message);
      }
    }
  }

  if (input.progressItemId && (input.progressStatus || input.progressCurrentFocus)) {
    const { data: existingProgressItem, error: existingProgressItemError } =
      await studentCheck.supabase
        .from("progress_items")
        .select("id")
        .eq("id", input.progressItemId)
        .eq("student_id", input.studentId)
        .eq("instructor_id", studentCheck.instructorId)
        .maybeSingle();

    if (existingProgressItemError) {
      failAction(existingProgressItemError.message);
    }

    if (!existingProgressItem) {
      failAction("Progress item was not found.");
    }

    if (input.progressCurrentFocus) {
      const { error: clearFocusError } = await studentCheck.supabase
        .from("progress_items")
        .update({
          current_focus: false,
          updated_at: updatedAt,
        })
        .eq("student_id", input.studentId)
        .eq("instructor_id", studentCheck.instructorId)
        .neq("id", input.progressItemId);

      if (clearFocusError) {
        failAction(clearFocusError.message);
      }
    }

    const progressPayload: {
      status?: string;
      current_focus?: boolean;
      updated_at: string;
    } = {
      updated_at: updatedAt,
    };

    if (input.progressStatus) {
      progressPayload.status = input.progressStatus;
    }

    if (input.progressCurrentFocus) {
      progressPayload.current_focus = true;
    }

    const { data, error } = await studentCheck.supabase
      .from("progress_items")
      .update(progressPayload)
      .eq("id", input.progressItemId)
      .eq("student_id", input.studentId)
      .eq("instructor_id", studentCheck.instructorId)
      .select("id")
      .maybeSingle();

    if (error) {
      failAction(error.message);
    }

    if (!data) {
      failAction("Progress item was not found.");
    }
  }

  revalidateStudentPaths(input.studentId, studentCheck.slug);
}
