import { createLessonNoteAction } from "@/app/students/[studentId]/actions";
import { FormSubmitButton } from "@/components/students/form-submit-button";

type LessonNoteFormProps = {
  studentId: string;
};

const fieldClassName =
  "min-h-11 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm leading-6 shadow-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:outline-2 focus-visible:outline-ring";

const textareaClassName = `${fieldClassName} min-h-24 resize-y`;

export function LessonNoteForm({ studentId }: LessonNoteFormProps) {
  return (
    <form action={createLessonNoteAction} className="rounded-lg border border-border bg-card p-5">
      <input type="hidden" name="studentId" value={studentId} />

      <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h2 className="text-[18px] font-semibold leading-tight">Add lesson note</h2>
          <p className="mt-1 text-sm leading-5 text-muted-foreground">
            Capture what happened today and what should carry into the next lesson.
          </p>
        </div>
        <div className="w-full sm:w-44">
          <label className="field-label" htmlFor="lessonDate">
            Lesson date
          </label>
          <input
            className={`${fieldClassName} mt-1`}
            defaultValue={getTodayDateInputValue()}
            id="lessonDate"
            name="lessonDate"
            required
            type="date"
          />
        </div>
      </div>

      <div className="mt-5 grid gap-4 md:grid-cols-2">
        <TextAreaField
          label="Covered"
          name="coveredMaterial"
          placeholder="Groove, song section, rudiment, or exercise"
        />
        <TextAreaField
          label="Observations"
          name="observations"
          placeholder="Timing, coordination, reading, confidence, or habits"
        />
        <TextAreaField
          label="Practice"
          name="practiceAssigned"
          placeholder="Concrete practice task for the week"
        />
        <TextAreaField
          label="Next hint"
          name="nextStepHint"
          placeholder="What to check first next time"
        />
      </div>

      <div className="mt-5 flex justify-end">
        <FormSubmitButton label="Save note" pendingLabel="Saving note..." />
      </div>
    </form>
  );
}

function TextAreaField({
  label,
  name,
  placeholder,
}: {
  label: string;
  name: string;
  placeholder: string;
}) {
  return (
    <div>
      <label className="field-label" htmlFor={name}>
        {label}
      </label>
      <textarea
        className={`${textareaClassName} mt-1`}
        id={name}
        maxLength={2000}
        name={name}
        placeholder={placeholder}
        required
      />
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
