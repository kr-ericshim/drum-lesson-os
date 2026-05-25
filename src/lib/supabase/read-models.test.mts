import assert from "node:assert/strict";
import test from "node:test";

import {
  buildLessonBrief,
  mapStudentDetail,
  mapLessonQueue,
  mapStudentRoster,
  pickCurrentFocusProgressItem,
  pickLatestAssignment,
  pickPriorityNextPlan,
} from "./read-models.ts";

test("mapStudentRoster derives current focus from focused progress item", () => {
  const roster = mapStudentRoster([
    {
      id: "student-1",
      name: "Mina Park",
      profile_cue: "Likes compact goals",
      primary_weak_point: "Rushing fills",
      progress_items: [
        {
          id: "progress-old",
          category: "song",
          status: "steady",
          title: "Older focused groove",
          current_focus: true,
          observed_on: "2026-05-10",
          detail: "Older focus should lose to newer focus.",
        },
        {
          id: "progress-new",
          category: "technique",
          status: "needs_review",
          title: "Syncopated eighth-note groove",
          current_focus: true,
          observed_on: "2026-05-15",
          detail: "Main focus for next lesson.",
        },
      ],
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
          planned_for: "2026-05-20",
          detail: "Start with the transition.",
        },
      ],
    },
  ]);

  assert.deepEqual(roster, [
    {
      id: "student-1",
      name: "Mina Park",
      profileCue: "Likes compact goals",
      currentFocus: {
        id: "progress-new",
        category: "technique",
        status: "needs_review",
        title: "Syncopated eighth-note groove",
        observedOn: "2026-05-15",
        detail: "Main focus for next lesson.",
      },
      weakPoint: "Rushing fills",
      assignmentStatus: "needs_review",
      nextAction: "Check slow fill transitions",
      nextPlan: {
        id: "plan-1",
        nextAction: "Check slow fill transitions",
        priority: "normal",
        plannedFor: "2026-05-20",
        detail: "Start with the transition.",
      },
    },
  ]);
});

test("mapStudentRoster returns null current focus when no focused progress item exists", () => {
  const roster = mapStudentRoster([
    {
      id: "student-1",
      name: "Mina Park",
      profile_cue: "Likes compact goals",
      primary_weak_point: "Rushing fills",
      progress_items: [
        {
          id: "progress-1",
          category: "song",
          status: "steady",
          title: "Verse groove",
          current_focus: false,
          observed_on: "2026-05-10",
          detail: "Stable enough to leave unflagged.",
        },
      ],
      assignments: [],
      next_lesson_plans: [],
    },
  ]);

  assert.equal(roster[0]?.currentFocus, null);
  assert.equal(roster[0]?.nextPlan, null);
});

test("pickCurrentFocusProgressItem prefers the newest focused progress item", () => {
  const focus = pickCurrentFocusProgressItem([
    {
      id: "older",
      category: "song",
      status: "needs_review",
      title: "Older focus",
      current_focus: true,
      observed_on: "2026-05-01",
      detail: "Older focus.",
    },
    {
      id: "newer",
      category: "rudiment",
      status: "in_progress",
      title: "Newer focus",
      current_focus: true,
      observed_on: "2026-05-20",
      detail: "Newer focus.",
    },
  ]);

  assert.equal(focus?.id, "newer");
});

test("pickCurrentFocusProgressItem has a deterministic same-date tie-break", () => {
  const focus = pickCurrentFocusProgressItem([
    {
      id: "bravo",
      category: "song",
      status: "needs_review",
      title: "Same-date focus B",
      current_focus: true,
      observed_on: "2026-05-20",
      detail: "Second title alphabetically.",
    },
    {
      id: "alpha",
      category: "rudiment",
      status: "in_progress",
      title: "Same-date focus A",
      current_focus: true,
      observed_on: "2026-05-20",
      detail: "First title alphabetically.",
    },
  ]);

  assert.equal(focus?.id, "alpha");
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
    primary_weak_point: "Rushing fills",
    progress_items: [
      {
        id: "focus",
        category: "technique",
        status: "in_progress",
        title: "Syncopated eighth-note groove",
        current_focus: true,
        observed_on: "2026-05-20",
        detail: "Keep the groove relaxed.",
      },
    ],
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
  assert.equal(detail.currentFocus?.id, "focus");
  assert.equal(detail.lessonBrief.latestObservation, "Newest observation");
});

test("buildLessonBrief falls back to the latest note hint when next plan is missing", () => {
  const brief = buildLessonBrief({
    profileCue: "Learns by watching first",
    currentFocus: null,
    weakPoint: "Needs visual demo",
    assignment: null,
    nextAction: "Set next lesson action",
    nextPlan: null,
    recentNotes: [
      {
        id: "note-new",
        lessonDate: "2026-05-22",
        coveredMaterial: "Paradiddle movement",
        observations: "Visual demo landed quickly.",
        practiceAssigned: "Two-bar loop.",
        nextStepHint: "Lead with full-phrase demo.",
      },
    ],
  });

  assert.equal(brief.latestObservation, "Visual demo landed quickly.");
  assert.equal(brief.firstCheck, "Lead with full-phrase demo.");
});

test("buildLessonBrief carries the briefing fields used by the UI", () => {
  const currentFocus = {
    id: "focus-1",
    category: "song",
    status: "needs_review",
    title: "Verse groove",
    observedOn: "2026-05-20",
    detail: "Review the verse entrance.",
  };
  const brief = buildLessonBrief({
    profileCue: "Adult hobby student",
    currentFocus,
    weakPoint: "Practice is uneven",
    assignment: {
      status: "needs_review",
      title: "Song section loop",
      dueDate: "2026-05-27",
      detail: "Review before adding the chorus.",
    },
    nextAction: "Check the assignment first",
    nextPlan: {
      id: "plan-1",
      nextAction: "Check the assignment first",
      priority: "high",
      plannedFor: "2026-05-27",
      detail: "Do not add a section before review.",
    },
    recentNotes: [
      {
        id: "note-1",
        lessonDate: "2026-05-22",
        coveredMaterial: "Verse groove",
        observations: "Tempo dropped after the entrance.",
        practiceAssigned: "Loop the verse.",
        nextStepHint: "Ask about practice consistency.",
      },
    ],
  });

  assert.deepEqual(brief, {
    profileCue: "Adult hobby student",
    currentFocus,
    weakPoint: "Practice is uneven",
    nextAction: "Check the assignment first",
    assignmentReviewCue: "Song section loop needs review.",
    latestObservation: "Tempo dropped after the entrance.",
    firstCheck: "Check the assignment first",
  });
});

test("mapLessonQueue sorts dated plans by date priority and name", () => {
  const queue = mapLessonQueue(
    [
      {
        id: "future-high",
        name: "Zoe",
        profileCue: "Future high",
        currentFocus: null,
        weakPoint: "None",
        assignmentStatus: "in_progress",
        nextAction: "Future high",
        nextPlan: {
          id: "plan-future-high",
          nextAction: "Future high",
          priority: "high",
          plannedFor: "2026-05-27",
          detail: "",
        },
      },
      {
        id: "today-normal-b",
        name: "Mina",
        profileCue: "Today normal",
        currentFocus: null,
        weakPoint: "None",
        assignmentStatus: "needs_review",
        nextAction: "Today normal",
        nextPlan: {
          id: "plan-today-normal-b",
          nextAction: "Today normal",
          priority: "normal",
          plannedFor: "2026-05-25",
          detail: "",
        },
      },
      {
        id: "undated",
        name: "No Date",
        profileCue: "Undated",
        currentFocus: null,
        weakPoint: "None",
        assignmentStatus: "in_progress",
        nextAction: "Undated",
        nextPlan: {
          id: "plan-undated",
          nextAction: "Undated",
          priority: "high",
          plannedFor: null,
          detail: "",
        },
      },
      {
        id: "overdue-low",
        name: "Aaron",
        profileCue: "Overdue low",
        currentFocus: null,
        weakPoint: "None",
        assignmentStatus: "complete",
        nextAction: "Overdue low",
        nextPlan: {
          id: "plan-overdue-low",
          nextAction: "Overdue low",
          priority: "low",
          plannedFor: "2026-05-24",
          detail: "",
        },
      },
      {
        id: "today-high",
        name: "Yuna",
        profileCue: "Today high",
        currentFocus: null,
        weakPoint: "None",
        assignmentStatus: "in_progress",
        nextAction: "Today high",
        nextPlan: {
          id: "plan-today-high",
          nextAction: "Today high",
          priority: "high",
          plannedFor: "2026-05-25",
          detail: "",
        },
      },
      {
        id: "today-normal-a",
        name: "Daniel",
        profileCue: "Today normal",
        currentFocus: null,
        weakPoint: "None",
        assignmentStatus: "in_progress",
        nextAction: "Today normal",
        nextPlan: {
          id: "plan-today-normal-a",
          nextAction: "Today normal",
          priority: "normal",
          plannedFor: "2026-05-25",
          detail: "",
        },
      },
    ],
    "2026-05-25",
  );

  assert.deepEqual(
    queue.map((item) => item.studentId),
    ["overdue-low", "today-high", "today-normal-a", "today-normal-b", "future-high"],
  );
  assert.equal(queue[0]?.dateState, "overdue");
  assert.equal(queue[1]?.dateState, "today");
  assert.equal(queue[4]?.dateState, "upcoming");
});
