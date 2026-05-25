import { Separator } from "@/components/ui/separator";
import type { StudentDetail } from "@/lib/supabase/queries";
import { formatReadableDate } from "@/components/students/status-labels";
import { LessonNoteForm } from "@/components/students/lesson-note-form";

type StudentNotesListProps = {
  notes: StudentDetail["recentNotes"];
  studentId: string;
};

export function StudentNotesList({ notes, studentId }: StudentNotesListProps) {
  return (
    <div className="space-y-4">
      <LessonNoteForm studentId={studentId} />

      <section className="rounded-lg border border-border bg-card">
        <div className="border-b border-border p-5">
          <h2 className="text-[18px] font-semibold leading-tight">Notes</h2>
          <p className="mt-1 text-sm leading-5 text-muted-foreground">
            Latest three lesson notes, newest first.
          </p>
        </div>
        {notes.length === 0 ? (
          <p className="p-5 text-sm leading-6 text-muted-foreground">No lesson notes yet.</p>
        ) : (
          <div className="divide-y divide-border">
            {notes.map((note) => (
              <article key={note.id} className="space-y-4 p-5">
                <div>
                  <p className="field-label">Lesson date</p>
                  <h3 className="mt-1 text-sm font-semibold leading-5">
                    {formatReadableDate(note.lessonDate)}
                  </h3>
                </div>

                <Separator />

                <div className="grid gap-4 md:grid-cols-2">
                  <NoteField label="Covered" value={note.coveredMaterial} />
                  <NoteField label="Observations" value={note.observations} />
                  <NoteField label="Practice" value={note.practiceAssigned} />
                  <NoteField label="Next hint" value={note.nextStepHint} />
                </div>
              </article>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function NoteField({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="field-label">{label}</p>
      <p className="mt-1 text-sm leading-6 text-muted-foreground">{value}</p>
    </div>
  );
}
