import { AlertTriangle, ClipboardList } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { NextPlanForm } from "@/components/students/next-plan-form";
import type { StudentDetail } from "@/lib/supabase/queries";
import {
  assignmentLabelByStatus,
  assignmentVariantByStatus,
  formatReadableDate,
  progressLabelByStatus,
  progressVariantByStatus,
} from "@/components/students/status-labels";

type StudentSummaryPanelProps = {
  student: StudentDetail;
};

export function StudentSummaryPanel({ student }: StudentSummaryPanelProps) {
  const weakPointTraits = student.traits.filter((trait) => trait.type === "weak_point");
  const otherTraits = student.traits.filter((trait) => trait.type !== "weak_point");
  const currentProgress = student.progressItems.filter((item) => item.currentFocus);
  const progressHighlights =
    currentProgress.length > 0 ? currentProgress : student.progressItems.slice(0, 3);
  const assignmentVariant = assignmentVariantByStatus[student.assignmentStatus] ?? "muted";
  const assignmentLabel =
    assignmentLabelByStatus[student.assignmentStatus] ?? student.assignmentStatus;

  return (
    <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(280px,0.48fr)]">
      <section className="space-y-4 rounded-lg border border-border bg-card p-5">
        <div className="flex items-center gap-2">
          <ClipboardList className="h-4 w-4 text-primary" aria-hidden="true" />
          <h2 className="text-[18px] font-semibold leading-tight">Current progress</h2>
        </div>

        {progressHighlights.length > 0 ? (
          <div className="divide-y divide-border">
            {progressHighlights.map((item) => (
              <article key={item.id} className="py-3 first:pt-0 last:pb-0">
                <div className="flex flex-wrap items-center gap-2">
                  <Badge variant={progressVariantByStatus[item.status] ?? "muted"}>
                    {progressLabelByStatus[item.status] ?? item.status}
                  </Badge>
                  <span className="field-label">{item.category}</span>
                  <span className="field-label">{formatReadableDate(item.observedOn)}</span>
                </div>
                <h3 className="mt-2 text-sm font-semibold leading-5">{item.title}</h3>
                <p className="mt-1 text-sm leading-5 text-muted-foreground">{item.detail}</p>
              </article>
            ))}
          </div>
        ) : (
          <p className="text-sm leading-6 text-muted-foreground">No progress items yet.</p>
        )}
      </section>

      <div className="space-y-4">
        <section className="rounded-lg border border-border bg-card p-5">
          <h2 className="text-[18px] font-semibold leading-tight">Traits</h2>
          {otherTraits.length > 0 ? (
            <div className="mt-3 space-y-3">
              {otherTraits.map((trait) => (
                <div key={trait.id}>
                  <p className="field-label">{trait.type.replaceAll("_", " ")}</p>
                  <p className="mt-1 text-sm font-semibold leading-5">{trait.label}</p>
                  <p className="mt-1 text-sm leading-5 text-muted-foreground">{trait.detail}</p>
                </div>
              ))}
            </div>
          ) : (
            <p className="mt-2 text-sm leading-6 text-muted-foreground">No traits recorded yet.</p>
          )}
        </section>

        <section className="rounded-lg border border-border bg-card p-5">
          <div className="flex items-center gap-2">
            <AlertTriangle className="h-4 w-4 text-attention" aria-hidden="true" />
            <h2 className="text-[18px] font-semibold leading-tight">Weak points</h2>
          </div>
          <p className="mt-3 text-sm leading-5">{student.weakPoint}</p>
          {weakPointTraits.length > 0 ? (
            <div className="mt-3 space-y-3">
              {weakPointTraits.map((trait) => (
                <div key={trait.id}>
                  <p className="text-sm font-semibold leading-5">{trait.label}</p>
                  <p className="mt-1 text-sm leading-5 text-muted-foreground">{trait.detail}</p>
                </div>
              ))}
            </div>
          ) : null}
        </section>

        <section className="rounded-lg border border-border bg-card p-5">
          <h2 className="text-[18px] font-semibold leading-tight">Assignment</h2>
          <div className="mt-3 flex flex-wrap items-center gap-2">
            <Badge variant={assignmentVariant}>{assignmentLabel}</Badge>
            {student.assignment?.dueDate ? (
              <span className="field-label">Due {formatReadableDate(student.assignment.dueDate)}</span>
            ) : null}
          </div>
          <p className="mt-3 text-sm font-semibold leading-5">
            {student.assignment?.title ?? "No active assignment title"}
          </p>
          <p className="mt-1 text-sm leading-5 text-muted-foreground">
            {student.assignment?.detail || "No assignment detail recorded yet."}
          </p>
        </section>

        <section className="rounded-lg border border-border bg-card p-5">
          <h2 className="text-[18px] font-semibold leading-tight">Next lesson</h2>
          <p className="mt-3 text-sm font-semibold leading-5">{student.nextAction}</p>
          <p className="mt-1 text-sm leading-5 text-muted-foreground">
            {student.nextPlan?.detail || "No next lesson detail recorded yet."}
          </p>
          <NextPlanForm studentId={student.id} nextPlan={student.nextPlan} />
        </section>
      </div>
    </div>
  );
}
