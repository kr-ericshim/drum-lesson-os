import { FormSubmitButton } from "@/components/students/form-submit-button";
import type { StudentDetail } from "@/lib/supabase/queries";

type StudentProfileFormProps = {
  action: (formData: FormData) => Promise<void>;
  student?: Pick<StudentDetail, "id" | "name" | "profileCue" | "weakPoint">;
  mode: "create" | "edit";
};

const fieldClassName =
  "min-h-11 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm leading-6 shadow-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:outline-2 focus-visible:outline-ring";

export function StudentProfileForm({ action, student, mode }: StudentProfileFormProps) {
  const isCreate = mode === "create";

  return (
    <form
      action={action}
      className={isCreate ? "space-y-4 rounded-lg border border-border bg-card p-5" : "space-y-4"}
    >
      <input type="hidden" name="studentId" value={student?.id ?? ""} />
      {isCreate ? (
        <div>
          <p className="quiet-label">New student</p>
          <h1 className="mt-2 font-display text-[30px] font-medium leading-[1.1] text-pretty">
            Add student
          </h1>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-muted-foreground text-pretty">
            Start with the lesson memory fields that make the roster and Lesson Brief useful.
          </p>
        </div>
      ) : null}

      <div className="grid gap-4 md:grid-cols-2">
        <div>
          <label className="field-label" htmlFor={`${mode}-student-name`}>
            Name
          </label>
          <input
            className={`${fieldClassName} mt-1`}
            defaultValue={student?.name ?? ""}
            id={`${mode}-student-name`}
            maxLength={120}
            name="name"
            placeholder="Student name"
            required
            type="text"
          />
        </div>

        <div>
          <label className="field-label" htmlFor={`${mode}-student-weak-point`}>
            Primary weak point
          </label>
          <input
            className={`${fieldClassName} mt-1`}
            defaultValue={student?.weakPoint ?? ""}
            id={`${mode}-student-weak-point`}
            maxLength={240}
            name="primaryWeakPoint"
            placeholder="What usually needs attention?"
            required
            type="text"
          />
        </div>
      </div>

      <div>
        <label className="field-label" htmlFor={`${mode}-student-profile-cue`}>
          Profile cue
        </label>
        <textarea
          className={`${fieldClassName} mt-1 min-h-24 resize-y`}
          defaultValue={student?.profileCue ?? ""}
          id={`${mode}-student-profile-cue`}
          maxLength={240}
          name="profileCue"
          placeholder="Lesson style, motivation, context, or reminder for this student"
          required
        />
      </div>

      {!isCreate ? (
        <label className="flex items-start gap-3 text-sm leading-5">
          <input
            className="mt-1 h-4 w-4 rounded border-input text-primary"
            defaultChecked
            name="active"
            type="checkbox"
          />
          <span>
            <span className="font-semibold">Active student</span>
            <span className="block text-muted-foreground">Inactive students stay out of the roster.</span>
          </span>
        </label>
      ) : null}

      <div className="flex justify-end">
        <FormSubmitButton
          label={isCreate ? "Create student" : "Save profile"}
          pendingLabel={isCreate ? "Creating student..." : "Saving profile..."}
        />
      </div>
    </form>
  );
}
