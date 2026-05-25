import assert from "node:assert/strict";
import test from "node:test";

import {
  mapStudentDetail,
  mapStudentRoster,
  pickLatestAssignment,
  pickPriorityNextPlan,
} from "./read-models.ts";

test("mapStudentRoster keeps active roster fields and latest related context", () => {
  const roster = mapStudentRoster([
    {
      id: "student-1",
      name: "Mina Park",
      profile_cue: "Likes compact goals",
      current_focus: "Syncopated eighth-note groove",
      primary_weak_point: "Rushing fills",
      assignments: [
        { status: "not_started", created_at: "2026-05-01T10:00:00.000Z" },
        { status: "needs_review", created_at: "2026-05-15T10:00:00.000Z" },
      ],
      next_lesson_plans: [
        {
          id: "plan-1",
          next_action: "Check slow fill transitions",
          priority: "normal",
          created_at: "2026-05-16T10:00:00.000Z",
        },
      ],
    },
  ]);

  assert.deepEqual(roster, [
    {
      id: "student-1",
      name: "Mina Park",
      profileCue: "Likes compact goals",
      currentFocus: "Syncopated eighth-note groove",
      weakPoint: "Rushing fills",
      assignmentStatus: "needs_review",
      nextAction: "Check slow fill transitions",
    },
  ]);
});

test("pickPriorityNextPlan prefers high priority before recency", () => {
  const plan = pickPriorityNextPlan([
    {
      id: "plan-recent",
      next_action: "Recent normal plan",
      priority: "normal",
      created_at: "2026-05-20T10:00:00.000Z",
    },
    {
      id: "plan-high",
      next_action: "Older high plan",
      priority: "high",
      created_at: "2026-05-10T10:00:00.000Z",
    },
  ]);

  assert.equal(plan?.next_action, "Older high plan");
  assert.equal(plan?.id, "plan-high");
});

test("pickLatestAssignment chooses newest assignment status", () => {
  const assignment = pickLatestAssignment([
    { status: "in_progress", created_at: "2026-05-10T10:00:00.000Z" },
    { status: "complete", created_at: "2026-05-21T10:00:00.000Z" },
  ]);

  assert.equal(assignment?.status, "complete");
});

test("mapStudentDetail limits recent notes to newest three by lesson date", () => {
  const detail = mapStudentDetail({
    id: "student-1",
    name: "Mina Park",
    profile_cue: "Likes compact goals",
    current_focus: "Syncopated eighth-note groove",
    primary_weak_point: "Rushing fills",
    progress_items: [],
    student_traits: [],
    assignments: [],
    next_lesson_plans: [
      {
        id: "plan-detail",
        next_action: "Review next groove",
        priority: "normal",
        created_at: "2026-05-20T10:00:00.000Z",
        planned_for: "2026-05-29",
        detail: "Start with slow eighth notes.",
      },
    ],
    lesson_notes: [
      {
        id: "old",
        lesson_date: "2026-04-01",
        covered_material: "Old material",
        observations: "Old observation",
        practice_assigned: "Old practice",
        next_step_hint: "Old next step",
      },
      {
        id: "newest",
        lesson_date: "2026-05-22",
        covered_material: "Newest material",
        observations: "Newest observation",
        practice_assigned: "Newest practice",
        next_step_hint: "Newest next step",
      },
      {
        id: "middle",
        lesson_date: "2026-05-15",
        covered_material: "Middle material",
        observations: "Middle observation",
        practice_assigned: "Middle practice",
        next_step_hint: "Middle next step",
      },
      {
        id: "third",
        lesson_date: "2026-05-01",
        covered_material: "Third material",
        observations: "Third observation",
        practice_assigned: "Third practice",
        next_step_hint: "Third next step",
      },
    ],
  });

  assert.deepEqual(
    detail.recentNotes.map((note) => note.id),
    ["newest", "middle", "third"],
  );
  assert.equal(detail.nextPlan?.id, "plan-detail");
});
