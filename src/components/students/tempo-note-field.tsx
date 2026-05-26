type TempoNoteFieldProps = {
  defaultValue?: string | null;
  fieldPrefix: string;
};

const fieldClassName =
  "min-h-11 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm leading-6 shadow-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:outline-2 focus-visible:outline-ring";

export function TempoNoteField({ defaultValue, fieldPrefix }: TempoNoteFieldProps) {
  return (
    <div className="mt-4">
      <label className="field-label" htmlFor={`${fieldPrefix}-tempoNote`}>
        Tempo note
      </label>
      <input
        className={`${fieldClassName} mt-1`}
        defaultValue={defaultValue ?? ""}
        id={`${fieldPrefix}-tempoNote`}
        maxLength={240}
        name="tempoNote"
        placeholder="Clean at 84, tense at 96"
        type="text"
      />
    </div>
  );
}
