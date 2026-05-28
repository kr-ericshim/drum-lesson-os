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
