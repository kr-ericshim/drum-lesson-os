import { saveNextLessonPlanAction } from "@/app/students/[studentId]/actions";
import { FormSubmitButton } from "@/components/students/form-submit-button";
import type { StudentDetail } from "@/lib/supabase/queries";

type NextPlanFormProps = {
  studentId: string;
  nextPlan: StudentDetail["nextPlan"];
};

const fieldClassName =
  "min-h-11 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm leading-6 shadow-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:outline-2 focus-visible:outline-ring";

export function NextPlanForm({ studentId, nextPlan }: NextPlanFormProps) {
  return (
    <details className="mt-4 border-t border-border pt-4">
      <summary className="cursor-pointer text-sm font-semibold leading-5">Edit next lesson</summary>
      <form action={saveNextLessonPlanAction} className="mt-4 space-y-4">
        <input type="hidden" name="studentId" value={studentId} />
        <input type="hidden" name="planId" value={nextPlan?.id ?? ""} />

        <div className="grid gap-3 sm:grid-cols-[minmax(0,1fr)_140px]">
          <div>
            <label className="field-label" htmlFor="nextAction">
              Next action
            </label>
            <input
              className={`${fieldClassName} mt-1`}
              defaultValue={nextPlan?.nextAction ?? ""}
              id="nextAction"
              maxLength={240}
              name="nextAction"
              placeholder="What should happen first next lesson?"
              required
              type="text"
            />
          </div>

          <div>
            <label className="field-label" htmlFor="priority">
              Priority
            </label>
            <select
              className={`${fieldClassName} mt-1`}
              defaultValue={nextPlan?.priority ?? "normal"}
              id="priority"
              name="priority"
            >
              <option value="low">Low</option>
              <option value="normal">Normal</option>
              <option value="high">High</option>
            </select>
          </div>
        </div>

        <div>
          <label className="field-label" htmlFor="plannedFor">
            Planned for
          </label>
          <input
            className={`${fieldClassName} mt-1 max-w-44`}
            defaultValue={nextPlan?.plannedFor ?? ""}
            id="plannedFor"
            name="plannedFor"
            type="date"
          />
        </div>

        <div>
          <label className="field-label" htmlFor="detail">
            Detail
          </label>
          <textarea
            className={`${fieldClassName} mt-1 min-h-24 resize-y`}
            defaultValue={nextPlan?.detail ?? ""}
            id="detail"
            maxLength={2000}
            name="detail"
            placeholder="Prep notes, tempo targets, or lesson sequence"
            required
          />
        </div>

        <div className="flex justify-end">
          <FormSubmitButton label="Save next plan" pendingLabel="Saving plan..." />
        </div>
      </form>
    </details>
  );
}
