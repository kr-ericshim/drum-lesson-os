import type { StudentRosterItem } from "@/lib/supabase/read-models";

export const rosterFilterKeys = [
  "needsReview",
  "highPriority",
  "noRecentNote",
  "missingFocus",
] as const;

export type RosterFilterKey = (typeof rosterFilterKeys)[number];
export type RosterFilterState = Record<RosterFilterKey, boolean>;

export function createEmptyRosterFilters(): RosterFilterState {
  return {
    highPriority: false,
    missingFocus: false,
    needsReview: false,
    noRecentNote: false,
  };
}

export function matchesRosterFilters(student: StudentRosterItem, filters: RosterFilterState) {
  if (filters.needsReview && !isNeedsReview(student)) {
    return false;
  }

  if (filters.highPriority && student.nextPlan?.priority !== "high") {
    return false;
  }

  if (filters.noRecentNote && student.hasRecentNote) {
    return false;
  }

  if (filters.missingFocus && student.currentFocus) {
    return false;
  }

  return true;
}

function isNeedsReview(student: StudentRosterItem) {
  return student.assignmentStatus === "needs_review" || student.progressNeedsReview;
}
