"use client";

import { closeoutLessonAction } from "@/app/students/[studentId]/actions";
import { FormSubmitButton } from "@/components/students/form-submit-button";
import {
  assignmentLabelByStatus,
  progressLabelByStatus,
} from "@/components/students/status-labels";
import {
  assignmentStatuses,
  nextPlanPriorities,
  progressItemStatuses,
} from "@/lib/students/status-options";
import type { LessonCloseoutDraft } from "@/lib/students/lesson-closeout-draft";
import type { StudentDetail } from "@/lib/supabase/queries";

type LessonCloseoutFormProps = {
  draft?: LessonCloseoutDraft | null;
  student: StudentDetail;
};

const fieldClassName =
  "min-h-11 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm leading-6 shadow-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:outline-2 focus-visible:outline-ring";

const priorityLabels: Record<(typeof nextPlanPriorities)[number], string> = {
  high: "High",
  low: "Low",
  normal: "Normal",
};

export function LessonCloseoutForm({ draft = null, student }: LessonCloseoutFormProps) {
  return (
    <section className="rounded-lg border border-border bg-card p-5" aria-labelledby="closeout-heading">
      <div>
        <p className="quiet-label">After lesson</p>
        <h2 id="closeout-heading" className="mt-1 text-[20px] font-semibold leading-tight">
          Closeout lesson
        </h2>
        <p className="mt-2 max-w-2xl text-sm leading-5 text-muted-foreground text-pretty">
          Record the note, next action, assignment cue, and one progress adjustment in a single pass.
        </p>
      </div>

      <details className="mt-4 border-t border-border pt-4" open={Boolean(draft)}>
        <summary className="cursor-pointer text-sm font-semibold leading-5">Closeout form</summary>
        <form action={closeoutLessonAction} className="mt-4 space-y-5">
          <input type="hidden" name="studentId" value={student.id} />
          <input type="hidden" name="nextPlanId" value={student.nextPlan?.id ?? ""} />
          <input type="hidden" name="assignmentId" value={student.assignment?.id ?? ""} />

          <div className="grid gap-4 md:grid-cols-[160px_minmax(0,1fr)]">
            <div>
              <label className="field-label" htmlFor="closeout-lesson-date">
                Lesson date
              </label>
              <input
                className={`${fieldClassName} mt-1`}
                defaultValue={getTodayDateInputValue()}
                id="closeout-lesson-date"
                name="lessonDate"
                required
                type="date"
              />
            </div>
            <TextAreaField
              defaultValue={draft?.coveredMaterial ?? ""}
              id="closeout-covered"
              label="Covered"
              maxLength={2000}
              name="coveredMaterial"
              placeholder="What happened today?"
            />
          </div>

          <div className="grid gap-4 md:grid-cols-3">
            <TextAreaField
              defaultValue={draft?.observations ?? ""}
              id="closeout-observations"
              label="Observation"
              maxLength={2000}
              name="observations"
              placeholder="What changed or got stuck?"
            />
            <TextAreaField
              defaultValue={draft?.practiceAssigned ?? ""}
              id="closeout-practice"
              label="Practice assigned"
              maxLength={2000}
              name="practiceAssigned"
              placeholder="What should they practice?"
            />
            <TextAreaField
              defaultValue={draft?.nextStepHint ?? ""}
              id="closeout-next-hint"
              label="Next hint"
              maxLength={1000}
              name="nextStepHint"
              placeholder="First thing to check next time"
            />
          </div>

          <div className="border-t border-border pt-4">
            <h3 className="text-sm font-semibold leading-5">Next lesson</h3>
            <div className="mt-3 grid gap-3 md:grid-cols-[minmax(0,1fr)_140px_160px]">
              <div>
                <label className="field-label" htmlFor="closeout-next-action">
                  Next action
                </label>
                <input
                  className={`${fieldClassName} mt-1`}
                  defaultValue={draft?.nextAction ?? student.nextPlan?.nextAction ?? ""}
                  id="closeout-next-action"
                  maxLength={240}
                  name="nextAction"
                  placeholder="What should happen first next lesson?"
                  required
                  type="text"
                />
              </div>
              <SelectField
                defaultValue={student.nextPlan?.priority ?? "normal"}
                id="closeout-priority"
                label="Priority"
                name="priority"
                options={nextPlanPriorities.map((priority) => ({
                  label: priorityLabels[priority],
                  value: priority,
                }))}
              />
              <div>
                <label className="field-label" htmlFor="closeout-planned-for">
                  Planned for
                </label>
                <input
                  className={`${fieldClassName} mt-1`}
                  defaultValue={student.nextPlan?.plannedFor ?? ""}
                  id="closeout-planned-for"
                  name="plannedFor"
                  type="date"
                />
              </div>
            </div>
            <TextAreaField
              defaultValue={student.nextPlan?.detail ?? ""}
              id="closeout-next-detail"
              label="Next detail (optional)"
              maxLength={2000}
              name="nextPlanDetail"
              placeholder="Prep sequence, tempo target, or review note"
              required={false}
            />
          </div>

          <div className="border-t border-border pt-4">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <h3 className="text-sm font-semibold leading-5">Assignment review</h3>
              <span className="quiet-label">Optional</span>
            </div>
            <div className="mt-3 grid gap-3 md:grid-cols-[minmax(0,1fr)_160px_160px]">
              <div>
                <label className="field-label" htmlFor="closeout-assignment-title">
                  Assignment title
                </label>
                <input
                  className={`${fieldClassName} mt-1`}
                  defaultValue={student.assignment?.title ?? ""}
                  id="closeout-assignment-title"
                  maxLength={160}
                  name="assignmentTitle"
                  placeholder="Leave blank to skip assignment update"
                  type="text"
                />
              </div>
              <SelectField
                defaultValue={student.assignment?.status ?? ""}
                id="closeout-assignment-status"
                label="Status"
                name="assignmentStatus"
                options={[
                  { label: "Skip assignment update", value: "" },
                  ...assignmentStatuses.map((status) => ({
                    label: assignmentLabelByStatus[status] ?? status,
                    value: status,
                  })),
                ]}
              />
              <div>
                <label className="field-label" htmlFor="closeout-assignment-due">
                  Due date
                </label>
                <input
                  className={`${fieldClassName} mt-1`}
                  defaultValue={student.assignment?.dueDate ?? ""}
                  id="closeout-assignment-due"
                  name="assignmentDueDate"
                  type="date"
                />
              </div>
            </div>
            <TextAreaField
              defaultValue={student.assignment?.detail ?? ""}
              id="closeout-assignment-detail"
              label="Assignment detail"
              maxLength={1000}
              name="assignmentDetail"
              placeholder="Leave blank to skip assignment update"
              required={false}
            />
          </div>

          <div className="border-t border-border pt-4">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <h3 className="text-sm font-semibold leading-5">Progress update</h3>
              <span className="quiet-label">Optional</span>
            </div>
            <div className="mt-3 grid gap-3 md:grid-cols-[minmax(0,1fr)_160px]">
              <SelectField
                defaultValue={draft?.progressItemId ?? ""}
                id="closeout-progress-item"
                label="Progress item"
                name="progressItemId"
                options={[
                  { label: "Skip progress update", value: "" },
                  ...student.progressItems.map((item) => ({
                    label: item.title,
                    value: item.id,
                  })),
                ]}
              />
              <SelectField
                defaultValue=""
                id="closeout-progress-status"
                label="New status"
                name="progressStatus"
                options={[
                  { label: "No status change", value: "" },
                  ...progressItemStatuses.map((status) => ({
                    label: progressLabelByStatus[status] ?? status,
                    value: status,
                  })),
                ]}
              />
            </div>
            <label className="mt-3 flex items-start gap-3 text-sm leading-5">
              <input
                className="mt-1 h-4 w-4 rounded border-input text-primary"
                defaultChecked={Boolean(draft?.progressCurrentFocus)}
                name="progressCurrentFocus"
                type="checkbox"
              />
              <span>
                <span className="font-semibold">Set selected item as current focus</span>
                <span className="block text-muted-foreground">
                  Works with or without a status change.
                </span>
              </span>
            </label>
          </div>

          <div className="flex justify-end">
            <FormSubmitButton label="Save closeout" pendingLabel="Saving closeout..." />
          </div>
        </form>
      </details>
    </section>
  );
}

function TextAreaField({
  defaultValue,
  id,
  label,
  maxLength,
  name,
  placeholder,
  required = true,
}: {
  defaultValue?: string;
  id: string;
  label: string;
  maxLength: number;
  name: string;
  placeholder: string;
  required?: boolean;
}) {
  return (
    <div className="mt-3">
      <label className="field-label" htmlFor={id}>
        {label}
      </label>
      <textarea
        className={`${fieldClassName} mt-1 min-h-24 resize-y`}
        defaultValue={defaultValue ?? ""}
        id={id}
        maxLength={maxLength}
        name={name}
        placeholder={placeholder}
        required={required}
      />
    </div>
  );
}

function SelectField({
  defaultValue,
  id,
  label,
  name,
  options,
}: {
  defaultValue: string;
  id: string;
  label: string;
  name: string;
  options: { label: string; value: string }[];
}) {
  return (
    <div>
      <label className="field-label" htmlFor={id}>
        {label}
      </label>
      <select className={`${fieldClassName} mt-1`} defaultValue={defaultValue} id={id} name={name}>
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </div>
  );
}

function getTodayDateInputValue() {
  const parts = new Intl.DateTimeFormat("en", {
    day: "2-digit",
    month: "2-digit",
    timeZone: "Asia/Seoul",
    year: "numeric",
  }).formatToParts(new Date());

  const partByType = new Map(parts.map((part) => [part.type, part.value]));

  return `${partByType.get("year")}-${partByType.get("month")}-${partByType.get("day")}`;
}
