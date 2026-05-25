import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import { StudentSummaryRow } from "@/components/dashboard/student-summary-row";
import type { StudentRosterItem } from "@/lib/supabase/queries";

type StudentRosterPreviewProps = {
  students: StudentRosterItem[];
  isLoading?: boolean;
  error?: string | null;
  setupMissing?: boolean;
};

export function StudentRosterPreview({
  students,
  isLoading = false,
  error = null,
  setupMissing = false,
}: StudentRosterPreviewProps) {
  return (
    <section className="space-y-4" aria-labelledby="student-roster-heading">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="quiet-label">Student roster</p>
          <h2 id="student-roster-heading" className="mt-2 text-[22px] font-semibold leading-[1.2] text-pretty">
            Student roster
          </h2>
        </div>
        <p className="max-w-sm text-sm leading-5 text-muted-foreground">
          Open a student to review progress, traits, notes, and next lesson cues.
        </p>
      </div>

      <Separator />

      {isLoading ? (
        <div className="space-y-3" aria-label="Loading student roster">
          <Skeleton className="h-28 w-full" />
          <Skeleton className="h-28 w-full" />
          <Skeleton className="h-28 w-full" />
        </div>
      ) : null}

      {!isLoading && error ? (
        <div className="rounded-lg border border-destructive/30 bg-card p-5">
          <h3 className="text-[18px] font-semibold text-destructive text-pretty">
            Student data could not be loaded
          </h3>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">
            Check Supabase environment variables and database access.
          </p>
          <p className="mt-3 break-words text-xs leading-5 text-muted-foreground">{error}</p>
        </div>
      ) : null}

      {!isLoading && !error && students.length === 0 ? (
        <div className="rounded-lg border border-border bg-card p-5">
          <h3 className="text-[18px] font-semibold text-pretty">
            {setupMissing ? "Supabase setup needed" : "No active students yet"}
          </h3>
          <p className="mt-2 text-sm leading-6 text-muted-foreground text-pretty">
            {setupMissing
              ? "Add environment variables and run the seed step before loading student records."
              : "Add seed data or create students later to review lesson context here."}
          </p>
        </div>
      ) : null}

      {!isLoading && !error && students.length > 0 ? (
        <div className="space-y-3">
          {students.map((student) => (
            <StudentSummaryRow key={student.id} student={student} />
          ))}
        </div>
      ) : null}
    </section>
  );
}
