import { saveAssignmentAction } from "@/app/students/[studentId]/actions";
import { FormSubmitButton } from "@/components/students/form-submit-button";
import { assignmentLabelByStatus } from "@/components/students/status-labels";
import { assignmentStatuses } from "@/lib/students/editing-schemas";
import type { StudentDetail } from "@/lib/supabase/queries";

type AssignmentFormProps = {
  studentId: string;
  assignment: StudentDetail["assignment"];
};

const fieldClassName =
  "min-h-11 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm leading-6 shadow-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:outline-2 focus-visible:outline-ring";

export function AssignmentForm({ studentId, assignment }: AssignmentFormProps) {
  const isEdit = Boolean(assignment?.id);

  return (
    <details className="mt-4 border-t border-border pt-4">
      <summary className="cursor-pointer text-sm font-semibold leading-5">
        {isEdit ? "Edit assignment" : "Add assignment"}
      </summary>
      <p className="mt-2 text-sm leading-5 text-muted-foreground">
        Keep the homework review cue aligned with the dashboard and Lesson Brief.
      </p>

      <form action={saveAssignmentAction} className="mt-4 space-y-4">
        <input type="hidden" name="studentId" value={studentId} />
        <input type="hidden" name="assignmentId" value={assignment?.id ?? ""} />

        <div className="grid gap-3 sm:grid-cols-[minmax(0,1fr)_160px]">
          <div>
            <label className="field-label" htmlFor="assignment-title">
              Assignment title
            </label>
            <input
              className={`${fieldClassName} mt-1`}
              defaultValue={assignment?.title ?? ""}
              id="assignment-title"
              maxLength={160}
              name="title"
              placeholder="Practice task to check next"
              required
              type="text"
            />
          </div>

          <div>
            <label className="field-label" htmlFor="assignment-status">
              Status
            </label>
            <select
              className={`${fieldClassName} mt-1`}
              defaultValue={assignment?.status ?? "in_progress"}
              id="assignment-status"
              name="status"
            >
              {assignmentStatuses.map((status) => (
                <option key={status} value={status}>
                  {assignmentLabelByStatus[status] ?? status}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div>
          <label className="field-label" htmlFor="assignment-due-date">
            Due date
          </label>
          <input
            className={`${fieldClassName} mt-1 max-w-44`}
            defaultValue={assignment?.dueDate ?? ""}
            id="assignment-due-date"
            name="dueDate"
            type="date"
          />
        </div>

        <div>
          <label className="field-label" htmlFor="assignment-detail">
            Assignment detail
          </label>
          <textarea
            className={`${fieldClassName} mt-1 min-h-24 resize-y`}
            defaultValue={assignment?.detail ?? ""}
            id="assignment-detail"
            maxLength={1000}
            name="detail"
            placeholder="What to practice, how much, and what to review first"
            required
          />
        </div>

        <div className="flex justify-end">
          <FormSubmitButton
            label={isEdit ? "Save assignment" : "Add assignment"}
            pendingLabel={isEdit ? "Saving assignment..." : "Adding assignment..."}
            variant={isEdit ? "secondary" : "default"}
          />
        </div>
      </form>
    </details>
  );
}
