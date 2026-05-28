import assert from "node:assert/strict";
import test from "node:test";

import { buildLessonCloseoutDraft } from "./lesson-closeout-draft.ts";

test("buildLessonCloseoutDraft keeps next hint and next action aligned", () => {
  const draft = buildLessonCloseoutDraft({
    coveredMaterial: "",
    observation: "Fill rushed after bar 4.",
    practiceAssigned: "",
    nextStepHint: "Check fill at 72 bpm before groove.",
    selectedChecklistLabels: ["First check", "Weak point"],
    fallbackFirstCheck: "Review paradiddle accents.",
    fallbackObservation: "No recent observation recorded.",
    fallbackPracticeAssigned: "Paradiddle grid needs review: slow accents.",
    progressItemId: "progress-1",
    progressCurrentFocus: true,
  });

  assert.equal(draft.nextStepHint, "Check fill at 72 bpm before groove.");
  assert.equal(draft.nextAction, "Check fill at 72 bpm before groove.");
  assert.equal(draft.observations, "Fill rushed after bar 4.");
  assert.equal(draft.practiceAssigned, "Paradiddle grid needs review: slow accents.");
  assert.equal(draft.progressItemId, "progress-1");
  assert.equal(draft.progressCurrentFocus, true);
});

test("buildLessonCloseoutDraft falls back to checked items and first check", () => {
  const draft = buildLessonCloseoutDraft({
    coveredMaterial: "",
    observation: "",
    practiceAssigned: "",
    nextStepHint: "",
    selectedChecklistLabels: ["First check", "Assignment review"],
    fallbackFirstCheck: "Review ghost notes first.",
    fallbackObservation: "Last note was about ghost note balance.",
    fallbackPracticeAssigned: "Practice groove slowly.",
    progressItemId: "",
    progressCurrentFocus: false,
  });

  assert.equal(draft.coveredMaterial, "First check; Assignment review");
  assert.equal(draft.observations, "First check; Assignment review");
  assert.equal(draft.nextStepHint, "Review ghost notes first.");
  assert.equal(draft.nextAction, "Review ghost notes first.");
  assert.equal(draft.progressItemId, undefined);
});
