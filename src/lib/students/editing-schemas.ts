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
  (value) => (typeof value === "string" && value.trim() === "" ? null : value),
  dateOnlySchema.nullable(),
);

const checkboxFromForm = z.preprocess(
  (value) => value === true || value === "on" || value === "true",
  z.boolean(),
);

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
  observedOn: dateOnlySchema,
  currentFocus: checkboxFromForm,
});

export type LessonNoteInput = z.infer<typeof lessonNoteInputSchema>;
export type NextPlanInput = z.infer<typeof nextPlanInputSchema>;
export type ProgressItemInput = z.infer<typeof progressItemInputSchema>;
