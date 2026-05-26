import { Pencil } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { ProgressItemForm } from "@/components/students/progress-item-form";
import { ProgressStatusActions } from "@/components/students/progress-status-actions";
import type { StudentDetail } from "@/lib/supabase/queries";
import {
  formatReadableDate,
  progressLabelByStatus,
  progressVariantByStatus,
} from "@/components/students/status-labels";

type StudentProgressListProps = {
  progressItems: StudentDetail["progressItems"];
  studentId: string;
};

export function StudentProgressList({ progressItems, studentId }: StudentProgressListProps) {
  if (progressItems.length === 0) {
    return (
      <div className="space-y-4">
        <ProgressItemForm studentId={studentId} />
        <section className="rounded-lg border border-border bg-card p-5">
          <h2 className="text-[18px] font-semibold leading-tight">Progress</h2>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">No progress items yet.</p>
        </section>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <ProgressItemForm studentId={studentId} />

      <section className="rounded-lg border border-border bg-card">
        <div className="border-b border-border p-5">
          <h2 className="text-[18px] font-semibold leading-tight">Progress</h2>
        </div>
        <div className="divide-y divide-border">
          {progressItems.map((item) => (
            <article key={item.id} className="grid gap-3 p-5 lg:grid-cols-[180px_minmax(0,1fr)]">
              <div className="space-y-2">
                <Badge variant={progressVariantByStatus[item.status] ?? "muted"}>
                  {progressLabelByStatus[item.status] ?? item.status}
                </Badge>
                <p className="field-label">{item.category}</p>
                <p className="field-label">{formatReadableDate(item.observedOn)}</p>
              </div>
              <div className="min-w-0">
                <div className="flex flex-wrap items-center gap-2">
                  <h3 className="text-sm font-semibold leading-5">{item.title}</h3>
                  {item.currentFocus ? <Badge variant="default">Current focus</Badge> : null}
                </div>
                <p className="mt-2 break-words text-sm leading-6 text-muted-foreground">{item.detail}</p>
                {item.tempoNote ? (
                  <p className="mt-2 break-words rounded-md border border-border bg-secondary px-3 py-2 text-sm leading-5">
                    <span className="field-label mr-2">Tempo</span>
                    {item.tempoNote}
                  </p>
                ) : null}
                <ProgressStatusActions
                  currentStatus={item.status}
                  progressItemId={item.id}
                  studentId={studentId}
                />

                <details className="mt-4 border-t border-border pt-4">
                  <summary className="inline-flex cursor-pointer list-none items-center gap-2 text-sm font-semibold text-primary outline-none transition-colors hover:text-primary/80 focus-visible:outline-2 focus-visible:outline-ring">
                    <Pencil className="h-4 w-4" aria-hidden="true" />
                    Edit progress
                  </summary>
                  <div className="mt-4">
                    <ProgressItemForm studentId={studentId} progressItem={item} variant="edit" />
                  </div>
                </details>
              </div>
            </article>
          ))}
        </div>
      </section>
    </div>
  );
}
