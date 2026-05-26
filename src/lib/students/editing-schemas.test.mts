import assert from "node:assert/strict";
import test from "node:test";

import {
  assignmentInputSchema,
  isProgressStatusTransitionAllowed,
  lessonNoteInputSchema,
  markAssignmentNeedsReviewInputSchema,
  nextPlanInputSchema,
  progressItemInputSchema,
  progressStatusTransitionInputSchema,
  quickLessonNoteInputSchema,
  quickNextActionInputSchema,
  studentProfileInputSchema,
  studentTraitInputSchema,
} from "./editing-schemas.ts";

const studentId = "22222222-2222-4222-8222-222222222222";

test("lessonNoteInputSchema trims valid note fields", () => {
  const parsed = lessonNoteInputSchema.parse({
    studentId,
    lessonDate: "2026-05-25",
    coveredMaterial: "  Groove Essentials page 12  ",
    observations: "  Rushes fills above 92 bpm  ",
    practiceAssigned: "  10 minutes with metronome  ",
    nextStepHint: "  Start with slow fill exits  ",
  });

  assert.deepEqual(parsed, {
    studentId,
    lessonDate: "2026-05-25",
    coveredMaterial: "Groove Essentials page 12",
    observations: "Rushes fills above 92 bpm",
    practiceAssigned: "10 minutes with metronome",
    nextStepHint: "Start with slow fill exits",
  });
});

test("lessonNoteInputSchema rejects blank text and invalid dates", () => {
  const result = lessonNoteInputSchema.safeParse({
    studentId,
    lessonDate: "2026-02-30",
    coveredMaterial: " ",
    observations: "Clear observation",
    practiceAssigned: "Practice task",
    nextStepHint: "Next step",
  });

  assert.equal(result.success, false);
});

test("nextPlanInputSchema accepts empty optional form fields as nullish values", () => {
  const parsed = nextPlanInputSchema.parse({
    studentId,
    planId: "",
    plannedFor: "",
    priority: "high",
    nextAction: "  Review kick-snare placement  ",
    detail: "  Compare slow and performance tempos.  ",
  });

  assert.deepEqual(parsed, {
    studentId,
    planId: undefined,
    plannedFor: null,
    priority: "high",
    nextAction: "Review kick-snare placement",
    detail: "Compare slow and performance tempos.",
  });
});

test("nextPlanInputSchema requires known priority and valid UUIDs", () => {
  const result = nextPlanInputSchema.safeParse({
    studentId: "not-a-uuid",
    planId: "not-a-plan-id",
    plannedFor: "2026-05-25",
    priority: "urgent",
    nextAction: "Review groove",
    detail: "Keep the same tempo target.",
  });

  assert.equal(result.success, false);
});

test("progressItemInputSchema trims valid create fields", () => {
  const parsed = progressItemInputSchema.parse({
    studentId,
    progressItemId: "",
    category: "technique",
    status: "in_progress",
    title: "  Double stroke control  ",
    detail: "  Keep the rebound relaxed at 80 bpm.  ",
    tempoNote: "  Clean at 84, tense at 96.  ",
    observedOn: "2026-05-25",
    currentFocus: "on",
  });

  assert.deepEqual(parsed, {
    studentId,
    progressItemId: undefined,
    category: "technique",
    status: "in_progress",
    title: "Double stroke control",
    detail: "Keep the rebound relaxed at 80 bpm.",
    tempoNote: "Clean at 84, tense at 96.",
    observedOn: "2026-05-25",
    currentFocus: true,
  });
});

test("progressItemInputSchema accepts a valid update id and unchecked focus", () => {
  const progressItemId = "33333333-3333-4333-8333-333333333333";
  const parsed = progressItemInputSchema.parse({
    studentId,
    progressItemId,
    category: "song",
    status: "needs_review",
    title: "Song groove",
    detail: "Review the verse entrance.",
    observedOn: "2026-05-25",
    currentFocus: "",
  });

  assert.equal(parsed.progressItemId, progressItemId);
  assert.equal(parsed.currentFocus, false);
});

test("progressItemInputSchema rejects invalid category status date and blank text", () => {
  const result = progressItemInputSchema.safeParse({
    studentId,
    progressItemId: "not-a-progress-item-id",
    category: "exercise",
    status: "stuck",
    title: " ",
    detail: " ",
    observedOn: "2026-02-30",
    currentFocus: "on",
  });

  assert.equal(result.success, false);
});

test("progressStatusTransitionInputSchema accepts valid quick status payloads", () => {
  const parsed = progressStatusTransitionInputSchema.parse({
    studentId,
    progressItemId: "44444444-4444-4444-8444-444444444444",
    nextStatus: "steady",
  });

  assert.equal(parsed.nextStatus, "steady");
});

test("progressStatusTransitionInputSchema rejects invalid quick status payloads", () => {
  const result = progressStatusTransitionInputSchema.safeParse({
    studentId: "not-a-student-id",
    progressItemId: "not-a-progress-id",
    nextStatus: "archived",
  });

  assert.equal(result.success, false);
});

test("isProgressStatusTransitionAllowed enforces the progress quick-action map", () => {
  assert.equal(isProgressStatusTransitionAllowed("new", "in_progress"), true);
  assert.equal(isProgressStatusTransitionAllowed("in_progress", "steady"), true);
  assert.equal(isProgressStatusTransitionAllowed("complete", "needs_review"), true);
  assert.equal(isProgressStatusTransitionAllowed("new", "complete"), false);
  assert.equal(isProgressStatusTransitionAllowed("unknown", "steady"), false);
});

test("quick dashboard action schemas validate narrow inputs", () => {
  assert.equal(
    quickLessonNoteInputSchema.parse({
      studentId,
      coveredMaterial: "  Fill entrance  ",
      observation: "  Watch the fill entrance next time.  ",
      practiceAssigned: "  Loop two bars slowly.  ",
      nextStepHint: "  Start with the fill.  ",
    }).observation,
    "Watch the fill entrance next time.",
  );
  assert.equal(
    quickNextActionInputSchema.parse({
      studentId,
      planId: "",
      nextAction: "  Start with the verse groove  ",
    }).nextAction,
    "Start with the verse groove",
  );
  assert.equal(
    markAssignmentNeedsReviewInputSchema.parse({
      studentId,
      assignmentId: "33333333-3333-4333-8333-333333333333",
    }).assignmentId,
    "33333333-3333-4333-8333-333333333333",
  );
});

test("quick dashboard action schemas reject invalid inputs", () => {
  assert.equal(
    quickLessonNoteInputSchema.safeParse({
      studentId,
      coveredMaterial: "Covered",
      observation: " ",
      practiceAssigned: "Practice",
      nextStepHint: "Next",
    }).success,
    false,
  );
  assert.equal(
    quickNextActionInputSchema.safeParse({ studentId, planId: "", nextAction: " " }).success,
    false,
  );
  assert.equal(
    markAssignmentNeedsReviewInputSchema.safeParse({ studentId, assignmentId: "bad-id" }).success,
    false,
  );
});

test("studentProfileInputSchema trims valid profile fields", () => {
  const parsed = studentProfileInputSchema.parse({
    studentId,
    name: "  Maya Park  ",
    profileCue: "  Adult hobbyist, learns best from short demos  ",
    primaryWeakPoint: "  Rushes fill exits after long work weeks  ",
    active: "on",
  });

  assert.deepEqual(parsed, {
    studentId,
    name: "Maya Park",
    profileCue: "Adult hobbyist, learns best from short demos",
    primaryWeakPoint: "Rushes fill exits after long work weeks",
    active: true,
  });
});

test("studentProfileInputSchema accepts new-student payload without id", () => {
  const parsed = studentProfileInputSchema.parse({
    studentId: "",
    name: "New Student",
    profileCue: "Beginner who responds well to counting aloud.",
    primaryWeakPoint: "Needs steady quarter-note pulse.",
    active: "",
  });

  assert.equal(parsed.studentId, undefined);
  assert.equal(parsed.active, false);
});

test("studentProfileInputSchema rejects blank profile fields and invalid id", () => {
  const result = studentProfileInputSchema.safeParse({
    studentId: "not-a-student-id",
    name: " ",
    profileCue: " ",
    primaryWeakPoint: " ",
    active: "on",
  });

  assert.equal(result.success, false);
});

test("studentTraitInputSchema trims valid trait fields", () => {
  const traitId = "33333333-3333-4333-8333-333333333333";
  const parsed = studentTraitInputSchema.parse({
    studentId,
    traitId,
    type: "learning_style",
    label: "  Demo first  ",
    detail: "  Understands groove shape faster after seeing one clean example.  ",
  });

  assert.deepEqual(parsed, {
    studentId,
    traitId,
    type: "learning_style",
    label: "Demo first",
    detail: "Understands groove shape faster after seeing one clean example.",
  });
});

test("studentTraitInputSchema rejects invalid trait type blank text and invalid UUID", () => {
  const result = studentTraitInputSchema.safeParse({
    studentId: "not-a-student-id",
    traitId: "not-a-trait-id",
    type: "tempo_preference",
    label: " ",
    detail: " ",
  });

  assert.equal(result.success, false);
});

test("assignmentInputSchema trims valid create fields", () => {
  const parsed = assignmentInputSchema.parse({
    studentId,
    assignmentId: "",
    title: "  Ghost-note ladder  ",
    status: "needs_review",
    dueDate: "",
    detail: "  Check 92 bpm before raising tempo.  ",
  });

  assert.deepEqual(parsed, {
    studentId,
    assignmentId: undefined,
    title: "Ghost-note ladder",
    status: "needs_review",
    dueDate: null,
    detail: "Check 92 bpm before raising tempo.",
  });
});

test("assignmentInputSchema accepts omitted optional due date", () => {
  const parsed = assignmentInputSchema.parse({
    studentId,
    assignmentId: "",
    title: "Ghost-note ladder",
    status: "needs_review",
    detail: "Check 92 bpm before raising tempo.",
  });

  assert.equal(parsed.dueDate, null);
});

test("assignmentInputSchema accepts valid update id and due date", () => {
  const assignmentId = "33333333-3333-4333-8333-333333333333";
  const parsed = assignmentInputSchema.parse({
    studentId,
    assignmentId,
    title: "Count-aloud groove loop",
    status: "in_progress",
    dueDate: "2026-05-29",
    detail: "Four bars only.",
  });

  assert.equal(parsed.assignmentId, assignmentId);
  assert.equal(parsed.dueDate, "2026-05-29");
});

test("assignmentInputSchema rejects each invalid field independently", () => {
  const validAssignment = {
    studentId,
    assignmentId: "",
    title: "Ghost-note ladder",
    status: "needs_review",
    dueDate: "2026-05-29",
    detail: "Check 92 bpm before raising tempo.",
  };

  const invalidPayloads = [
    { ...validAssignment, studentId: "not-a-student-id" },
    { ...validAssignment, assignmentId: "not-an-assignment-id" },
    { ...validAssignment, title: " " },
    { ...validAssignment, status: "practicing" },
    { ...validAssignment, dueDate: "2026-02-30" },
    { ...validAssignment, detail: " " },
  ];

  for (const payload of invalidPayloads) {
    assert.equal(assignmentInputSchema.safeParse(payload).success, false);
  }
});
