import Link from "next/link";
import { ArrowLeft, ArrowRight } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import type { StudentDetail } from "@/lib/supabase/queries";
import {
  assignmentLabelByStatus,
  assignmentVariantByStatus,
} from "@/components/students/status-labels";

type StudentDetailHeaderProps = {
  student: StudentDetail;
};

export function StudentDetailHeader({ student }: StudentDetailHeaderProps) {
  const assignmentVariant = assignmentVariantByStatus[student.assignmentStatus] ?? "muted";
  const assignmentLabel =
    assignmentLabelByStatus[student.assignmentStatus] ?? student.assignmentStatus;

  return (
    <header className="space-y-5">
      <Button asChild variant="ghost" className="min-h-0 px-0 py-0 hover:bg-transparent">
        <Link href="/">
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          Student roster
        </Link>
      </Button>

      <div className="grid gap-5 rounded-lg border border-border bg-card p-5 lg:grid-cols-[minmax(0,1fr)_minmax(260px,0.45fr)] lg:items-start">
        <div className="min-w-0 space-y-3">
          <p className="quiet-label">Student detail</p>
          <div className="space-y-2">
            <h1 className="text-[24px] font-semibold leading-[1.2] text-pretty">
              {student.name}
            </h1>
            <p className="max-w-2xl text-sm leading-6 text-muted-foreground text-pretty">
              {student.profileCue}
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            <Badge variant={assignmentVariant}>{assignmentLabel}</Badge>
            {student.nextPlan ? <Badge variant="muted">{student.nextPlan.priority} priority</Badge> : null}
          </div>
        </div>

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-1">
          <div>
            <p className="field-label">Current focus</p>
            <p className="mt-1 break-words text-sm leading-5">
              {student.currentFocus?.title ?? "No current focus set"}
            </p>
          </div>
          <div>
            <p className="field-label flex items-center gap-1.5">
              <ArrowRight className="h-3.5 w-3.5 text-primary" aria-hidden="true" />
              Next lesson
            </p>
            <p className="mt-1 break-words text-sm leading-5">{student.nextAction}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
