import { saveStudentTraitAction } from "@/app/students/[studentId]/actions";
import { FormSubmitButton } from "@/components/students/form-submit-button";
import { studentTraitTypes } from "@/lib/students/editing-schemas";
import type { StudentDetail } from "@/lib/supabase/queries";

type StudentTraitsEditorProps = {
  studentId: string;
  traits: StudentDetail["traits"];
};

const fieldClassName =
  "min-h-11 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm leading-6 shadow-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:outline-2 focus-visible:outline-ring";

const traitTypeLabels: Record<(typeof studentTraitTypes)[number], string> = {
  caution: "Caution",
  learning_style: "Learning style",
  musical_preference: "Musical preference",
  practice_habit: "Practice habit",
  strength: "Strength",
  weak_point: "Weak point",
};

export function StudentTraitsEditor({ studentId, traits }: StudentTraitsEditorProps) {
  return (
    <details className="border-t border-border pt-4">
      <summary className="cursor-pointer text-sm font-semibold leading-5">Edit all traits</summary>
      <p className="mt-2 text-sm leading-5 text-muted-foreground">
        Tune the teaching cues without moving away from the lesson summary.
      </p>

      <div className="mt-4 space-y-4">
        <div className="space-y-3">
          {traits.map((trait) => (
            <TraitForm key={trait.id} studentId={studentId} trait={trait} />
          ))}
        </div>

        <div className="border-t border-border pt-4">
          <h3 className="text-sm font-semibold leading-5">Add trait</h3>
          <p className="mt-1 text-sm leading-5 text-muted-foreground">
            Capture the teaching cue that will matter next lesson.
          </p>
          <TraitForm studentId={studentId} />
        </div>
      </div>
    </details>
  );
}

function TraitForm({
  studentId,
  trait,
}: {
  studentId: string;
  trait?: StudentDetail["traits"][number];
}) {
  const prefix = trait ? `trait-${trait.id}` : "new-trait";

  return (
    <form
      action={saveStudentTraitAction}
      className={
        trait
          ? "space-y-3 border-t border-border pt-4 first:border-t-0 first:pt-0"
          : "mt-4 space-y-3"
      }
    >
      <input type="hidden" name="studentId" value={studentId} />
      <input type="hidden" name="traitId" value={trait?.id ?? ""} />

      <div className="grid gap-3 sm:grid-cols-[160px_minmax(0,1fr)]">
        <div>
          <label className="field-label" htmlFor={`${prefix}-type`}>
            Trait type
          </label>
          <select
            className={`${fieldClassName} mt-1`}
            defaultValue={trait?.type ?? "learning_style"}
            id={`${prefix}-type`}
            name="type"
          >
            {studentTraitTypes.map((type) => (
              <option key={type} value={type}>
                {traitTypeLabels[type]}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="field-label" htmlFor={`${prefix}-label`}>
            Cue label
          </label>
          <input
            className={`${fieldClassName} mt-1`}
            defaultValue={trait?.label ?? ""}
            id={`${prefix}-label`}
            maxLength={120}
            name="label"
            placeholder="Short memory cue"
            required
            type="text"
          />
        </div>
      </div>

      <div>
        <label className="field-label" htmlFor={`${prefix}-detail`}>
          Lesson detail
        </label>
        <textarea
          className={`${fieldClassName} mt-1 min-h-20 resize-y`}
          defaultValue={trait?.detail ?? ""}
          id={`${prefix}-detail`}
          maxLength={1000}
          name="detail"
          placeholder="How this changes the lesson approach"
          required
        />
      </div>

      <div className="flex justify-end">
        <FormSubmitButton
          label={trait ? "Save trait" : "Add trait"}
          pendingLabel={trait ? "Saving trait..." : "Adding trait..."}
          variant={trait ? "secondary" : "default"}
        />
      </div>
    </form>
  );
}
