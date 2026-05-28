export type LessonCloseoutDraft = {
  coveredMaterial: string;
  observations: string;
  practiceAssigned: string;
  nextStepHint: string;
  nextAction: string;
  progressItemId?: string;
  progressCurrentFocus?: boolean;
};

export type LessonCloseoutDraftInput = {
  coveredMaterial: string;
  observation: string;
  practiceAssigned: string;
  nextStepHint: string;
  selectedChecklistLabels: string[];
  fallbackFirstCheck: string;
  fallbackObservation: string;
  fallbackPracticeAssigned: string;
  progressItemId?: string;
  progressCurrentFocus: boolean;
};

export function buildLessonCloseoutDraft(input: LessonCloseoutDraftInput): LessonCloseoutDraft {
  const checklistSummary = input.selectedChecklistLabels.join("; ");
  const nextHint = input.nextStepHint || input.fallbackFirstCheck;

  return {
    coveredMaterial: input.coveredMaterial || checklistSummary || input.fallbackFirstCheck,
    observations: input.observation || checklistSummary || input.fallbackObservation,
    practiceAssigned: input.practiceAssigned || input.fallbackPracticeAssigned,
    nextStepHint: nextHint,
    nextAction: nextHint,
    progressItemId: input.progressItemId || undefined,
    progressCurrentFocus: input.progressCurrentFocus,
  };
}
