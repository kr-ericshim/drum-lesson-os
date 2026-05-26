import { saveProgressItemAction } from "@/app/students/[studentId]/actions";
import { FormSubmitButton } from "@/components/students/form-submit-button";
import { progressLabelByStatus } from "@/components/students/status-labels";
import { TempoNoteField } from "@/components/students/tempo-note-field";
import {
  progressItemCategories,
  progressItemStatuses,
} from "@/lib/students/editing-schemas";
import type { StudentDetail } from "@/lib/supabase/queries";

type ProgressItemFormProps = {
  studentId: string;
  progressItem?: StudentDetail["progressItems"][number];
  variant?: "add" | "edit";
};

const fieldClassName =
  "min-h-11 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm leading-6 shadow-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:outline-2 focus-visible:outline-ring";

const categoryLabels: Record<(typeof progressItemCategories)[number], string> = {
  assignment: "Assignment",
  book: "Book",
  genre: "Genre",
  rudiment: "Rudiment",
  session: "Session",
  song: "Song",
  technique: "Technique",
};

export function ProgressItemForm({
  studentId,
  progressItem,
  variant = "add",
}: ProgressItemFormProps) {
  const fieldPrefix = progressItem ? `progress-${progressItem.id}` : "new-progress";
  const isEdit = variant === "edit";

  return (
    <form
      action={saveProgressItemAction}
      className={isEdit ? "space-y-4" : "rounded-lg border border-border bg-card p-5"}
    >
      <input type="hidden" name="studentId" value={studentId} />
      <input type="hidden" name="progressItemId" value={progressItem?.id ?? ""} />

      {!isEdit ? (
        <div>
          <h2 className="text-[18px] font-semibold leading-tight">Add progress item</h2>
          <p className="mt-1 text-sm leading-5 text-muted-foreground">
            Track the lesson target, status, and teaching note for this student.
          </p>
        </div>
      ) : null}

      <div className={isEdit ? "grid gap-4 md:grid-cols-2" : "mt-5 grid gap-4 md:grid-cols-2"}>
        <SelectField
          defaultValue={progressItem?.category ?? "technique"}
          id={`${fieldPrefix}-category`}
          label="Category"
          name="category"
          options={progressItemCategories.map((category) => ({
            label: categoryLabels[category],
            value: category,
          }))}
        />
        <SelectField
          defaultValue={progressItem?.status ?? "in_progress"}
          id={`${fieldPrefix}-status`}
          label="Status"
          name="status"
          options={progressItemStatuses.map((status) => ({
            label: progressLabelByStatus[status] ?? status,
            value: status,
          }))}
        />
        <div>
          <label className="field-label" htmlFor={`${fieldPrefix}-title`}>
            Title
          </label>
          <input
            className={`${fieldClassName} mt-1`}
            defaultValue={progressItem?.title ?? ""}
            id={`${fieldPrefix}-title`}
            maxLength={240}
            name="title"
            placeholder="Book page, song section, rudiment, or technique"
            required
            type="text"
          />
        </div>
        <div>
          <label className="field-label" htmlFor={`${fieldPrefix}-observedOn`}>
            Observed on
          </label>
          <input
            className={`${fieldClassName} mt-1`}
            defaultValue={progressItem?.observedOn ?? getTodayDateInputValue()}
            id={`${fieldPrefix}-observedOn`}
            name="observedOn"
            required
            type="date"
          />
        </div>
      </div>

      <div className="mt-4">
        <label className="field-label" htmlFor={`${fieldPrefix}-detail`}>
          Detail
        </label>
        <textarea
          className={`${fieldClassName} mt-1 min-h-24 resize-y`}
          defaultValue={progressItem?.detail ?? ""}
          id={`${fieldPrefix}-detail`}
          maxLength={2000}
          name="detail"
          placeholder="What changed, what needs review, or what to practice next"
          required
        />
      </div>

      <TempoNoteField defaultValue={progressItem?.tempoNote} fieldPrefix={fieldPrefix} />

      <div className="mt-4 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <label className="flex items-start gap-3 text-sm leading-5">
          <input
            className="mt-1 h-4 w-4 rounded border-input text-primary"
            defaultChecked={progressItem?.currentFocus ?? false}
            name="currentFocus"
            type="checkbox"
          />
          <span>
            <span className="font-semibold">Current focus</span>
            <span className="block text-muted-foreground">
              Sets this as the single highlighted progress item for the student.
            </span>
          </span>
        </label>

        <FormSubmitButton
          label={isEdit ? "Save progress" : "Add progress"}
          pendingLabel={isEdit ? "Saving progress..." : "Adding progress..."}
        />
      </div>
    </form>
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
