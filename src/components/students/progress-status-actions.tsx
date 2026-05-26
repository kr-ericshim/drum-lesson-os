import { ArrowRight } from "lucide-react";

import { saveProgressItemStatusAction } from "@/app/students/[studentId]/actions";
import { Button } from "@/components/ui/button";
import { progressLabelByStatus } from "@/components/students/status-labels";
import { progressStatusTransitions } from "@/lib/students/editing-schemas";

type ProgressStatusActionsProps = {
  currentStatus: string;
  progressItemId: string;
  studentId: string;
};

export function ProgressStatusActions({
  currentStatus,
  progressItemId,
  studentId,
}: ProgressStatusActionsProps) {
  const nextStatuses =
    progressStatusTransitions[currentStatus as keyof typeof progressStatusTransitions] ?? [];

  if (nextStatuses.length === 0) {
    return null;
  }

  return (
    <div className="mt-4 flex flex-wrap items-center gap-2">
      <p className="field-label w-full sm:w-auto">Quick status</p>
      {nextStatuses.map((nextStatus) => (
        <form action={saveProgressItemStatusAction} key={nextStatus}>
          <input type="hidden" name="studentId" value={studentId} />
          <input type="hidden" name="progressItemId" value={progressItemId} />
          <input type="hidden" name="nextStatus" value={nextStatus} />
          <Button className="min-h-11 px-3 py-2" type="submit" variant="secondary">
            <ArrowRight className="h-4 w-4" aria-hidden="true" />
            {progressLabelByStatus[nextStatus] ?? nextStatus}
          </Button>
        </form>
      ))}
    </div>
  );
}
