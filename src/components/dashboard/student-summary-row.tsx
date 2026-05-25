import Link from "next/link";
import { ArrowRight, AlertTriangle } from "lucide-react";

import { Badge, type BadgeProps } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import type { StudentRosterItem } from "@/lib/supabase/queries";

type StudentSummaryRowProps = {
  student: StudentRosterItem;
};

const assignmentVariantByStatus: Record<string, BadgeProps["variant"]> = {
  complete: "steady",
  in_progress: "default",
  needs_review: "attention",
  not_started: "muted",
  paused: "muted",
};

const assignmentLabelByStatus: Record<string, string> = {
  complete: "Complete",
  in_progress: "In progress",
  needs_review: "Needs review",
  not_started: "Not started",
  paused: "Paused",
};

export function StudentSummaryRow({ student }: StudentSummaryRowProps) {
  const assignmentVariant = assignmentVariantByStatus[student.assignmentStatus] ?? "muted";
  const assignmentLabel = assignmentLabelByStatus[student.assignmentStatus] ?? student.assignmentStatus;

  return (
    <article className="student-row rounded-lg border border-border bg-card p-4 transition-colors hover:border-primary/35 focus-within:border-primary/50">
      <div className="grid gap-4 xl:grid-cols-[minmax(150px,0.9fr)_minmax(0,1.1fr)_minmax(0,1.1fr)_112px_minmax(0,1.1fr)_132px] xl:items-start">
        <div className="min-w-0">
          <h3 className="truncate text-[16px] font-semibold leading-snug">{student.name}</h3>
          <p className="mt-1 line-clamp-2 text-sm leading-5 text-muted-foreground">
            {student.profileCue}
          </p>
        </div>

        <div className="min-w-0">
          <p className="field-label">Current focus</p>
          <p className="mt-1 line-clamp-2 text-sm leading-5">{student.currentFocus}</p>
        </div>

        <div className="min-w-0">
          <p className="field-label flex items-center gap-1.5">
            <AlertTriangle className="h-3.5 w-3.5 text-attention" aria-hidden="true" />
            Weak point
          </p>
          <p className="mt-1 line-clamp-2 text-sm leading-5">{student.weakPoint}</p>
        </div>

        <div>
          <p className="field-label">Assignment</p>
          <Badge className="mt-2" variant={assignmentVariant}>
            {assignmentLabel}
          </Badge>
        </div>

        <div className="min-w-0">
          <p className="field-label flex items-center gap-1.5">
            <ArrowRight className="h-3.5 w-3.5 text-primary" aria-hidden="true" />
            Next lesson
          </p>
          <p className="mt-1 line-clamp-2 text-sm leading-5">{student.nextAction}</p>
        </div>

        <div className="flex xl:justify-end">
          <Button asChild variant="secondary" className="w-full sm:w-auto">
            <Link href={`/students/${student.id}`} aria-label={`Open student ${student.name}`}>
              Open student
            </Link>
          </Button>
        </div>
      </div>
    </article>
  );
}
