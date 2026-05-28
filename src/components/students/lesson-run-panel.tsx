"use client";

import { ClipboardCheck, ListChecks } from "lucide-react";
import { useMemo, useState } from "react";

import { Button } from "@/components/ui/button";
import {
  buildLessonCloseoutDraft,
  type LessonCloseoutDraft,
} from "@/lib/students/lesson-closeout-draft";
import type { StudentDetail } from "@/lib/supabase/queries";

type LessonRunPanelProps = {
  onDraftReady: (draft: LessonCloseoutDraft) => void;
  student: StudentDetail;
};

const fieldClassName =
  "min-h-11 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm leading-6 shadow-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:outline-2 focus-visible:outline-ring";

export function LessonRunPanel({ onDraftReady, student }: LessonRunPanelProps) {
  const checklist = useMemo(() => buildChecklist(student), [student]);
  const [checkedItems, setCheckedItems] = useState<Record<string, boolean>>({});
  const [coveredMaterial, setCoveredMaterial] = useState("");
  const [observation, setObservation] = useState("");
  const [practiceAssigned, setPracticeAssigned] = useState("");
  const [nextStepHint, setNextStepHint] = useState(student.lessonBrief.firstCheck);
  const [progressItemId, setProgressItemId] = useState(student.currentFocus?.id ?? "");
  const [progressCurrentFocus, setProgressCurrentFocus] = useState(Boolean(student.currentFocus));

  const selectedChecklistLabels = checklist
    .filter((item) => checkedItems[item.id])
    .map((item) => item.label);

  function sendDraftToCloseout() {
    onDraftReady(
      buildLessonCloseoutDraft({
        coveredMaterial,
        observation,
        practiceAssigned,
        nextStepHint,
        selectedChecklistLabels,
        fallbackFirstCheck: student.lessonBrief.firstCheck,
        fallbackObservation: student.lessonBrief.latestObservation,
        fallbackPracticeAssigned: student.assignment?.detail || student.lessonBrief.assignmentReviewCue,
        progressItemId,
        progressCurrentFocus,
      }),
    );
  }

  return (
    <section className="rounded-lg border border-border bg-card p-5" aria-labelledby="lesson-run-heading">
      <div className="flex items-center gap-2">
        <ListChecks className="h-4 w-4 text-primary" aria-hidden="true" />
        <div>
          <p className="quiet-label">During lesson</p>
          <h2 id="lesson-run-heading" className="mt-1 text-[20px] font-semibold leading-tight">
            Run the lesson
          </h2>
        </div>
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)]">
        <div>
          <p className="field-label">Checklist</p>
          <div className="mt-3 space-y-2">
            {checklist.map((item) => (
              <label
                className="flex items-start gap-3 rounded-lg border border-border bg-background p-3 text-sm leading-5"
                key={item.id}
              >
                <input
                  checked={Boolean(checkedItems[item.id])}
                  className="mt-1 h-4 w-4 rounded border-input text-primary"
                  onChange={(event) =>
                    setCheckedItems((current) => ({
                      ...current,
                      [item.id]: event.target.checked,
                    }))
                  }
                  type="checkbox"
                />
                <span>
                  <span className="font-semibold">{item.label}</span>
                  <span className="block text-muted-foreground">{item.detail}</span>
                </span>
              </label>
            ))}
          </div>
        </div>

        <div className="space-y-3">
          <TextAreaField
            label="Covered"
            onChange={setCoveredMaterial}
            placeholder="What actually happened in the lesson?"
            value={coveredMaterial}
          />
          <TextAreaField
            label="Observation"
            onChange={setObservation}
            placeholder="What changed, clicked, or got stuck?"
            value={observation}
          />
          <TextAreaField
            label="Practice assigned"
            onChange={setPracticeAssigned}
            placeholder="What should they practice this week?"
            value={practiceAssigned}
          />
          <TextAreaField
            label="Next hint"
            onChange={setNextStepHint}
            placeholder="First thing to check next time"
            value={nextStepHint}
          />

          <div className="grid gap-3 sm:grid-cols-[minmax(0,1fr)_180px]">
            <div>
              <label className="field-label" htmlFor={`run-progress-${student.id}`}>
                Progress focus
              </label>
              <select
                className={`${fieldClassName} mt-1`}
                id={`run-progress-${student.id}`}
                onChange={(event) => setProgressItemId(event.target.value)}
                value={progressItemId}
              >
                <option value="">No progress focus draft</option>
                {student.progressItems.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.title}
                  </option>
                ))}
              </select>
            </div>
            <label className="mt-6 flex items-start gap-3 text-sm leading-5">
              <input
                checked={progressCurrentFocus}
                className="mt-1 h-4 w-4 rounded border-input text-primary"
                onChange={(event) => setProgressCurrentFocus(event.target.checked)}
                type="checkbox"
              />
              <span>Keep as current focus</span>
            </label>
          </div>

          <div className="flex justify-end">
            <Button onClick={sendDraftToCloseout} type="button">
              <ClipboardCheck className="mr-2 h-4 w-4" aria-hidden="true" />
              Use in closeout
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}

function buildChecklist(student: StudentDetail) {
  return [
    {
      id: "first-check",
      label: "First check",
      detail: student.lessonBrief.firstCheck,
    },
    {
      id: "assignment",
      label: "Assignment review",
      detail: student.lessonBrief.assignmentReviewCue,
    },
    {
      id: "weak-point",
      label: "Weak point",
      detail: student.lessonBrief.weakPoint,
    },
    {
      id: "next-action",
      label: "Next action",
      detail: student.lessonBrief.nextAction,
    },
  ];
}

function TextAreaField({
  label,
  onChange,
  placeholder,
  value,
}: {
  label: string;
  onChange: (value: string) => void;
  placeholder: string;
  value: string;
}) {
  return (
    <label className="block">
      <span className="field-label">{label}</span>
      <textarea
        className={`${fieldClassName} mt-1 min-h-20 resize-y`}
        maxLength={2000}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
        value={value}
      />
    </label>
  );
}
