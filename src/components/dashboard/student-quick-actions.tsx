import {
  createQuickLessonNoteAction,
  markAssignmentNeedsReviewAction,
  saveQuickNextActionAction,
} from "@/app/students/[studentId]/actions";
import { FormSubmitButton } from "@/components/students/form-submit-button";
import type { StudentRosterItem } from "@/lib/supabase/queries";

type StudentQuickActionsProps = {
  student: StudentRosterItem;
};

const fieldClassName =
  "min-h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm leading-5 shadow-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:outline-2 focus-visible:outline-ring";

export function StudentQuickActions({ student }: StudentQuickActionsProps) {
  return (
    <details className="mt-4 border-t border-border pt-3">
      <summary className="cursor-pointer text-sm font-semibold leading-5 text-primary">
        Quick actions
      </summary>
      <div className="mt-3 grid gap-3 xl:grid-cols-[minmax(0,1.2fr)_minmax(0,1fr)_180px]">
        <form action={createQuickLessonNoteAction} className="min-w-0 space-y-2">
          <input type="hidden" name="studentId" value={student.id} />
          <p className="field-label">Short note</p>
          <div className="grid gap-2 sm:grid-cols-2">
            <label className="sr-only" htmlFor={`quick-covered-${student.id}`}>
              Covered
            </label>
            <input
              className={fieldClassName}
              id={`quick-covered-${student.id}`}
              maxLength={160}
              name="coveredMaterial"
              placeholder="Covered"
              required
              type="text"
            />
            <label className="sr-only" htmlFor={`quick-note-${student.id}`}>
              Observation
            </label>
            <input
              className={fieldClassName}
              id={`quick-note-${student.id}`}
              maxLength={300}
              name="observation"
              placeholder="Observation"
              required
              type="text"
            />
            <label className="sr-only" htmlFor={`quick-practice-${student.id}`}>
              Practice assigned
            </label>
            <input
              className={fieldClassName}
              id={`quick-practice-${student.id}`}
              maxLength={300}
              name="practiceAssigned"
              placeholder="Practice assigned"
              required
              type="text"
            />
            <label className="sr-only" htmlFor={`quick-next-hint-${student.id}`}>
              First check next time
            </label>
            <input
              className={fieldClassName}
              id={`quick-next-hint-${student.id}`}
              maxLength={300}
              name="nextStepHint"
              placeholder="First check next time"
              required
              type="text"
            />
          </div>
          <FormSubmitButton label="Add note" pendingLabel="Adding..." variant="secondary" />
        </form>

        <form action={saveQuickNextActionAction} className="min-w-0 space-y-2">
          <input type="hidden" name="studentId" value={student.id} />
          <input type="hidden" name="planId" value={student.nextPlan?.id ?? ""} />
          <label className="field-label" htmlFor={`quick-next-${student.id}`}>
            Next action
          </label>
          <input
            className={fieldClassName}
            defaultValue={student.nextAction === "Set next lesson action" ? "" : student.nextAction}
            id={`quick-next-${student.id}`}
            maxLength={240}
            name="nextAction"
            placeholder="Update next lesson"
            required
            type="text"
          />
          <FormSubmitButton label="Save action" pendingLabel="Saving..." variant="secondary" />
        </form>

        <div className="min-w-0 space-y-2">
          <p className="field-label">Assignment</p>
          {student.assignmentId ? (
            <form action={markAssignmentNeedsReviewAction}>
              <input type="hidden" name="studentId" value={student.id} />
              <input type="hidden" name="assignmentId" value={student.assignmentId} />
              <FormSubmitButton label="Mark needs review" pendingLabel="Marking..." variant="secondary" />
            </form>
          ) : (
            <p className="text-sm leading-5 text-muted-foreground">No assignment to mark.</p>
          )}
        </div>
      </div>
    </details>
  );
}
