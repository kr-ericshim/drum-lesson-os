import assert from "node:assert/strict";
import test from "node:test";

import {
  lessonNoteInputSchema,
  nextPlanInputSchema,
  progressItemInputSchema,
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
