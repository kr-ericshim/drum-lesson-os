import { AlertTriangle, ArrowRight, ClipboardList, Eye } from "lucide-react";
import type { ReactNode } from "react";

import { Badge } from "@/components/ui/badge";
import type { StudentDetail } from "@/lib/supabase/queries";

type LessonBriefProps = {
  student: StudentDetail;
};

export function LessonBrief({ student }: LessonBriefProps) {
  const brief = student.lessonBrief;

  return (
    <section className="rounded-lg border border-border bg-card p-5" aria-labelledby="lesson-brief-heading">
      <div className="flex items-center gap-2">
        <ClipboardList className="h-4 w-4 text-primary" aria-hidden="true" />
        <div>
          <p className="quiet-label">Lesson brief</p>
          <h2 id="lesson-brief-heading" className="mt-1 text-[20px] font-semibold leading-tight">
            {student.name}
          </h2>
        </div>
      </div>

      <div className="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <BriefField label="Profile cue" value={brief.profileCue} />
        <BriefField
          label="Current focus"
          value={brief.currentFocus?.title ?? "No current focus set"}
          badge={brief.currentFocus ? "Progress focus" : undefined}
        />
        <BriefField
          icon={<AlertTriangle className="h-3.5 w-3.5 text-attention" aria-hidden="true" />}
          label="Primary weak point"
          value={brief.weakPoint}
        />
        <BriefField
          icon={<ArrowRight className="h-3.5 w-3.5 text-primary" aria-hidden="true" />}
          label="Next lesson"
          value={brief.nextAction}
        />
      </div>

      <div className="mt-4 grid gap-4 lg:grid-cols-3">
        <BriefField label="Assignment review" value={brief.assignmentReviewCue} />
        <BriefField
          icon={<Eye className="h-3.5 w-3.5 text-primary" aria-hidden="true" />}
          label="Last observation"
          value={brief.latestObservation}
        />
        <BriefField label="First check" value={brief.firstCheck} />
      </div>
    </section>
  );
}

function BriefField({
  badge,
  icon,
  label,
  value,
}: {
  badge?: string;
  icon?: ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div className="min-w-0 border-t border-border pt-3">
      <div className="flex flex-wrap items-center gap-2">
        <p className="field-label flex items-center gap-1.5">
          {icon}
          {label}
        </p>
        {badge ? <Badge variant="muted">{badge}</Badge> : null}
      </div>
      <p className="mt-2 text-sm leading-5 text-pretty">{value}</p>
    </div>
  );
}
