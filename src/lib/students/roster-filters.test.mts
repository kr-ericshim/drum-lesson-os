import assert from "node:assert/strict";
import test from "node:test";

import { createEmptyRosterFilters, matchesRosterFilters } from "./roster-filters.ts";
import type { StudentRosterItem } from "../supabase/read-models.ts";

const baseStudent: StudentRosterItem = {
  assignmentId: "assignment-1",
  assignmentStatus: "in_progress",
  assignmentTitle: "Verse loop",
  currentFocus: {
    category: "song",
    detail: "Keep it steady.",
    id: "focus-1",
    observedOn: "2026-05-20",
    status: "in_progress",
    tempoNote: null,
    title: "Verse groove",
  },
  hasRecentNote: true,
  id: "student-1",
  lastLessonDate: "2026-05-20",
  name: "Mina Park",
  nextAction: "Review the verse",
  nextPlan: {
    detail: "Start with the verse.",
    id: "plan-1",
    nextAction: "Review the verse",
    plannedFor: "2026-05-29",
    priority: "normal",
  },
  profileCue: "Likes compact goals",
  progressNeedsReview: false,
  weakPoint: "Rushing fills",
};

test("matchesRosterFilters applies no filters as full roster", () => {
  assert.equal(matchesRosterFilters(baseStudent, createEmptyRosterFilters()), true);
});

test("matchesRosterFilters supports each single attention filter", () => {
  assert.equal(
    matchesRosterFilters(
      { ...baseStudent, assignmentStatus: "needs_review" },
      { ...createEmptyRosterFilters(), needsReview: true },
    ),
    true,
  );
  assert.equal(
    matchesRosterFilters(
      { ...baseStudent, nextPlan: { ...baseStudent.nextPlan!, priority: "high" } },
      { ...createEmptyRosterFilters(), highPriority: true },
    ),
    true,
  );
  assert.equal(
    matchesRosterFilters(
      { ...baseStudent, hasRecentNote: false },
      { ...createEmptyRosterFilters(), noRecentNote: true },
    ),
    true,
  );
  assert.equal(
    matchesRosterFilters(
      { ...baseStudent, currentFocus: null },
      { ...createEmptyRosterFilters(), missingFocus: true },
    ),
    true,
  );
});

test("matchesRosterFilters combines active filters with AND semantics", () => {
  const filters = {
    ...createEmptyRosterFilters(),
    highPriority: true,
    needsReview: true,
  };

  assert.equal(
    matchesRosterFilters(
      {
        ...baseStudent,
        assignmentStatus: "needs_review",
        nextPlan: { ...baseStudent.nextPlan!, priority: "high" },
      },
      filters,
    ),
    true,
  );
  assert.equal(
    matchesRosterFilters({ ...baseStudent, assignmentStatus: "needs_review" }, filters),
    false,
  );
});
