import assert from "node:assert/strict";
import test from "node:test";

import { lessonCloseoutInputSchema } from "./editing-schemas.ts";

const studentId = "22222222-2222-4222-8222-222222222222";
const assignmentId = "33333333-3333-4333-8333-333333333333";
const progressItemId = "44444444-4444-4444-8444-444444444444";
const nextPlanId = "55555555-5555-4555-8555-555555555555";

const validCloseout = {
  studentId,
  lessonDate: "2026-05-26",
  coveredMaterial: "Verse groove and fill exits",
  observations: "Tempo dropped after the crash entrance.",
  practiceAssigned: "Loop the final two bars slowly.",
  nextStepHint: "Start by checking the assignment.",
  nextPlanId,
  nextAction: "Review fill exit before adding chorus",
  nextPlanDetail: "Keep the first ten minutes on slow transition work.",
  plannedFor: "2026-05-29",
  priority: "high",
  assignmentId,
  assignmentTitle: "Two-bar fill exit loop",
  assignmentStatus: "needs_review",
  assignmentDueDate: "2026-05-29",
  assignmentDetail: "Record one slow take before the next lesson.",
  progressItemId,
  progressStatus: "needs_review",
  progressCurrentFocus: "on",
};

test("lessonCloseoutInputSchema parses the full closeout payload", () => {
  const parsed = lessonCloseoutInputSchema.parse(validCloseout);

  assert.equal(parsed.assignmentDueDate, "2026-05-29");
  assert.equal(parsed.progressCurrentFocus, true);
  assert.equal(parsed.progressStatus, "needs_review");
  assert.equal(parsed.nextAction, "Review fill exit before adding chorus");
});

test("lessonCloseoutInputSchema accepts note and next plan without assignment or progress", () => {
  const parsed = lessonCloseoutInputSchema.parse({
    ...validCloseout,
    nextPlanId: "",
    plannedFor: "",
    assignmentId: "",
    assignmentTitle: "",
    assignmentStatus: "",
    assignmentDueDate: "",
    assignmentDetail: "",
    progressItemId: "",
    progressStatus: "",
    progressCurrentFocus: "",
  });

  assert.equal(parsed.nextPlanId, undefined);
  assert.equal(parsed.plannedFor, null);
  assert.equal(parsed.assignmentTitle, "");
  assert.equal(parsed.assignmentStatus, undefined);
  assert.equal(parsed.assignmentDueDate, null);
  assert.equal(parsed.progressItemId, undefined);
  assert.equal(parsed.progressStatus, undefined);
  assert.equal(parsed.progressCurrentFocus, false);
});

test("lessonCloseoutInputSchema requires assignment title status and detail together", () => {
  const result = lessonCloseoutInputSchema.safeParse({
    ...validCloseout,
    assignmentId: "",
    assignmentTitle: "",
    assignmentStatus: "",
    assignmentDetail: "Review this assignment.",
  });

  assert.equal(result.success, false);
});

test("lessonCloseoutInputSchema can skip an existing assignment update", () => {
  const parsed = lessonCloseoutInputSchema.parse({
    ...validCloseout,
    assignmentStatus: "",
  });

  assert.equal(parsed.assignmentId, assignmentId);
  assert.equal(parsed.assignmentStatus, undefined);
});

test("lessonCloseoutInputSchema rejects status-only assignment updates", () => {
  const result = lessonCloseoutInputSchema.safeParse({
    ...validCloseout,
    assignmentId: "",
    assignmentTitle: "",
    assignmentStatus: "needs_review",
    assignmentDueDate: "",
    assignmentDetail: "",
  });

  assert.equal(result.success, false);
});

test("lessonCloseoutInputSchema requires progress status when progress item is selected", () => {
  const result = lessonCloseoutInputSchema.safeParse({
    ...validCloseout,
    progressItemId,
    progressStatus: "",
  });

  assert.equal(result.success, false);
});

test("lessonCloseoutInputSchema rejects invalid required note and next-plan fields", () => {
  const result = lessonCloseoutInputSchema.safeParse({
    ...validCloseout,
    studentId: "not-a-student-id",
    lessonDate: "2026-02-30",
    coveredMaterial: " ",
    observations: " ",
    practiceAssigned: " ",
    nextStepHint: " ",
    nextAction: " ",
    nextPlanDetail: " ",
    priority: "urgent",
  });

  assert.equal(result.success, false);
});
