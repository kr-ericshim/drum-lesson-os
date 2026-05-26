import { z } from "zod";

export const nextPlanPriorities = ["low", "normal", "high"] as const;
export const progressItemCategories = [
  "book",
  "song",
  "rudiment",
  "genre",
  "technique",
  "session",
  "assignment",
] as const;
export const progressItemStatuses = [
  "new",
  "in_progress",
  "needs_review",
  "steady",
  "complete",
] as const;
export const progressStatusTransitions: Record<
  (typeof progressItemStatuses)[number],
  (typeof progressItemStatuses)[number][]
> = {
  complete: ["needs_review"],
  in_progress: ["needs_review", "steady"],
  needs_review: ["in_progress", "steady"],
  new: ["in_progress"],
  steady: ["complete"],
};

export function isProgressStatusTransitionAllowed(currentStatus: string, nextStatus: string) {
  const allowedStatuses =
    progressStatusTransitions[currentStatus as keyof typeof progressStatusTransitions] ?? [];

  return allowedStatuses.includes(nextStatus as (typeof progressItemStatuses)[number]);
}
export const assignmentStatuses = [
  "not_started",
  "in_progress",
  "needs_review",
  "complete",
  "paused",
] as const;
export const studentTraitTypes = [
  "strength",
  "weak_point",
  "practice_habit",
  "learning_style",
  "musical_preference",
  "caution",
] as const;

const dateOnlyPattern = /^\d{4}-\d{2}-\d{2}$/;

function isValidDateOnly(value: string) {
  if (!dateOnlyPattern.test(value)) {
    return false;
  }

  const [year, month, day] = value.split("-").map(Number);
  const parsedDate = new Date(Date.UTC(year, month - 1, day));

  return (
    parsedDate.getUTCFullYear() === year &&
    parsedDate.getUTCMonth() === month - 1 &&
    parsedDate.getUTCDate() === day
  );
}

function requiredTrimmedText(maxLength: number) {
  return z.string().trim().min(1).max(maxLength);
}

const dateOnlySchema = z.string().trim().refine(isValidDateOnly, {
  message: "Use a valid YYYY-MM-DD date.",
});

const optionalUuidFromForm = z.preprocess(
  (value) => (typeof value === "string" && value.trim() === "" ? undefined : value),
  z.string().trim().uuid().optional(),
);

const optionalDateFromForm = z.preprocess(
  (value) =>
    value === undefined || (typeof value === "string" && value.trim() === "") ? null : value,
  dateOnlySchema.nullable(),
);

const checkboxFromForm = z.preprocess(
  (value) => value === true || value === "on" || value === "true",
  z.boolean(),
);

function optionalEnumFromForm<T extends readonly [string, ...string[]]>(values: T) {
  return z.preprocess(
    (value) => (typeof value === "string" && value.trim() === "" ? undefined : value),
    z.enum(values).optional(),
  );
}

export const lessonNoteInputSchema = z.object({
  studentId: z.string().trim().uuid(),
  lessonDate: dateOnlySchema,
  coveredMaterial: requiredTrimmedText(2000),
  observations: requiredTrimmedText(2000),
  practiceAssigned: requiredTrimmedText(2000),
  nextStepHint: requiredTrimmedText(1000),
});

export const nextPlanInputSchema = z.object({
  studentId: z.string().trim().uuid(),
  planId: optionalUuidFromForm,
  plannedFor: optionalDateFromForm,
  priority: z.enum(nextPlanPriorities),
  nextAction: requiredTrimmedText(240),
  detail: requiredTrimmedText(2000),
});

export const progressItemInputSchema = z.object({
  studentId: z.string().trim().uuid(),
  progressItemId: optionalUuidFromForm,
  category: z.enum(progressItemCategories),
  status: z.enum(progressItemStatuses),
  title: requiredTrimmedText(240),
  detail: requiredTrimmedText(2000),
  tempoNote: z.string().trim().max(240).optional(),
  observedOn: dateOnlySchema,
  currentFocus: checkboxFromForm,
});

export const progressStatusTransitionInputSchema = z.object({
  studentId: z.string().trim().uuid(),
  progressItemId: z.string().trim().uuid(),
  nextStatus: z.enum(progressItemStatuses),
});

export const studentProfileInputSchema = z.object({
  studentId: optionalUuidFromForm,
  name: requiredTrimmedText(120),
  profileCue: requiredTrimmedText(240),
  primaryWeakPoint: requiredTrimmedText(240),
  active: checkboxFromForm,
});

export const studentTraitInputSchema = z.object({
  studentId: z.string().trim().uuid(),
  traitId: optionalUuidFromForm,
  type: z.enum(studentTraitTypes),
  label: requiredTrimmedText(120),
  detail: requiredTrimmedText(1000),
});

export const assignmentInputSchema = z.object({
  studentId: z.string().trim().uuid(),
  assignmentId: optionalUuidFromForm,
  title: requiredTrimmedText(160),
  status: z.enum(assignmentStatuses),
  dueDate: optionalDateFromForm,
  detail: requiredTrimmedText(1000),
});

export const lessonCloseoutInputSchema = z
  .object({
    studentId: z.string().trim().uuid(),
    lessonDate: dateOnlySchema,
    coveredMaterial: requiredTrimmedText(2000),
    observations: requiredTrimmedText(2000),
    practiceAssigned: requiredTrimmedText(2000),
    nextStepHint: requiredTrimmedText(1000),
    nextPlanId: optionalUuidFromForm,
    nextAction: requiredTrimmedText(240),
    nextPlanDetail: requiredTrimmedText(2000),
    plannedFor: optionalDateFromForm,
    priority: z.enum(nextPlanPriorities),
    assignmentId: optionalUuidFromForm,
    assignmentTitle: z.string().trim().max(160).optional(),
    assignmentStatus: optionalEnumFromForm(assignmentStatuses),
    assignmentDueDate: optionalDateFromForm,
    assignmentDetail: z.string().trim().max(1000).optional(),
    progressItemId: optionalUuidFromForm,
    progressStatus: optionalEnumFromForm(progressItemStatuses),
    progressCurrentFocus: checkboxFromForm,
  })
  .superRefine((input, context) => {
    const isSkippingExistingAssignment = Boolean(input.assignmentId && !input.assignmentStatus);
    const hasAssignmentInput = Boolean(
      !isSkippingExistingAssignment &&
        (input.assignmentTitle ||
          input.assignmentStatus ||
          input.assignmentDetail ||
          input.assignmentDueDate),
    );

    if (hasAssignmentInput && !input.assignmentTitle) {
      context.addIssue({
        code: "custom",
        message: "Assignment title is required when saving assignment review.",
        path: ["assignmentTitle"],
      });
    }

    if (hasAssignmentInput && !input.assignmentStatus) {
      context.addIssue({
        code: "custom",
        message: "Assignment status is required when saving assignment review.",
        path: ["assignmentStatus"],
      });
    }

    if (hasAssignmentInput && !input.assignmentDetail) {
      context.addIssue({
        code: "custom",
        message: "Assignment detail is required when saving assignment review.",
        path: ["assignmentDetail"],
      });
    }

    if (input.progressItemId && !input.progressStatus) {
      context.addIssue({
        code: "custom",
        message: "Progress status is required when updating progress.",
        path: ["progressStatus"],
      });
    }
  });

export const quickLessonNoteInputSchema = z.object({
  studentId: z.string().trim().uuid(),
  coveredMaterial: requiredTrimmedText(160),
  observation: requiredTrimmedText(300),
  practiceAssigned: requiredTrimmedText(300),
  nextStepHint: requiredTrimmedText(300),
});

export const quickNextActionInputSchema = z.object({
  studentId: z.string().trim().uuid(),
  planId: optionalUuidFromForm,
  nextAction: requiredTrimmedText(240),
});

export const markAssignmentNeedsReviewInputSchema = z.object({
  studentId: z.string().trim().uuid(),
  assignmentId: z.string().trim().uuid(),
});

export type LessonNoteInput = z.infer<typeof lessonNoteInputSchema>;
export type NextPlanInput = z.infer<typeof nextPlanInputSchema>;
export type ProgressItemInput = z.infer<typeof progressItemInputSchema>;
export type ProgressStatusTransitionInput = z.infer<typeof progressStatusTransitionInputSchema>;
export type StudentProfileInput = z.infer<typeof studentProfileInputSchema>;
export type StudentTraitInput = z.infer<typeof studentTraitInputSchema>;
export type AssignmentInput = z.infer<typeof assignmentInputSchema>;
export type LessonCloseoutInput = z.infer<typeof lessonCloseoutInputSchema>;
export type QuickLessonNoteInput = z.infer<typeof quickLessonNoteInputSchema>;
export type QuickNextActionInput = z.infer<typeof quickNextActionInputSchema>;
export type MarkAssignmentNeedsReviewInput = z.infer<typeof markAssignmentNeedsReviewInputSchema>;
