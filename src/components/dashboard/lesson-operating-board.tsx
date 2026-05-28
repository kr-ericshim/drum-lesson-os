import Link from "next/link";
import {
  AlertTriangle,
  ArrowRight,
  CalendarClock,
  CheckCircle2,
  CircleDashed,
} from "lucide-react";

import {
  assignmentLabelByStatus,
  assignmentVariantByStatus,
  formatReadableDate,
} from "@/components/students/status-labels";
import { Badge, type BadgeProps } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import type { LessonAttentionFlag, LessonQueueItem } from "@/lib/supabase/read-models";

type LessonOperatingBoardProps = {
  items: LessonQueueItem[];
};

const boardSections: Array<{
  empty: string;
  key: LessonQueueItem["dateState"];
  label: string;
}> = [
  { key: "overdue", label: "Overdue", empty: "No overdue lesson plans." },
  { key: "today", label: "Today", empty: "No lesson plans dated today." },
  { key: "upcoming", label: "Upcoming", empty: "No upcoming dated lesson plans." },
];

const dateStateVariant: Record<LessonQueueItem["dateState"], BadgeProps["variant"]> = {
  overdue: "attention",
  today: "default",
  upcoming: "muted",
};

const attentionLabelByFlag: Record<LessonAttentionFlag, string> = {
  assignment_needs_review: "Review assignment",
  missing_current_focus: "No focus",
  missing_recent_note: "No recent note",
  overdue_plan: "Plan overdue",
  stale_focus: "Focus stale",
};

export function LessonOperatingBoard({ items }: LessonOperatingBoardProps) {
  const itemCount = items.length;

  return (
    <section className="rounded-lg border border-border bg-card" aria-labelledby="lesson-board-heading">
      <div className="border-b border-border p-5">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div className="flex items-center gap-2">
            <CalendarClock className="h-4 w-4 text-primary" aria-hidden="true" />
            <div>
              <p className="quiet-label">Lesson operating board</p>
              <h2 id="lesson-board-heading" className="mt-1 text-[20px] font-semibold leading-tight">
                Teach from the first check
              </h2>
            </div>
          </div>
          <Badge variant={itemCount > 0 ? "default" : "muted"}>{itemCount} queued</Badge>
        </div>
      </div>

      {itemCount === 0 ? (
        <p className="p-5 text-sm leading-6 text-muted-foreground">
          No dated next lesson plans yet.
        </p>
      ) : (
        <div className="divide-y divide-border">
          {boardSections.map((section) => (
            <LessonBoardSection
              key={section.key}
              empty={section.empty}
              items={items.filter((item) => item.dateState === section.key)}
              label={section.label}
            />
          ))}
        </div>
      )}
    </section>
  );
}

function LessonBoardSection({
  empty,
  items,
  label,
}: {
  empty: string;
  items: LessonQueueItem[];
  label: string;
}) {
  return (
    <div className="p-5">
      <div className="flex items-center justify-between gap-3">
        <h3 className="text-sm font-semibold leading-5">{label}</h3>
        <span className="quiet-label">{items.length}</span>
      </div>
      {items.length === 0 ? (
        <p className="mt-3 text-sm leading-5 text-muted-foreground">{empty}</p>
      ) : (
        <div className="mt-3 space-y-3">
          {items.map((item) => (
            <LessonBoardRow key={`${item.studentId}-${item.plannedFor}`} item={item} />
          ))}
        </div>
      )}
    </div>
  );
}

function LessonBoardRow({ item }: { item: LessonQueueItem }) {
  const assignmentVariant = assignmentVariantByStatus[item.assignmentStatus] ?? "muted";
  const assignmentLabel = assignmentLabelByStatus[item.assignmentStatus] ?? item.assignmentStatus;
  const studentHref = `/students/${item.studentSlug ?? item.studentId}`;

  return (
    <article className="rounded-lg border border-border bg-background p-4">
      <div className="grid gap-4 xl:grid-cols-[150px_minmax(150px,0.7fr)_minmax(0,1.4fr)_minmax(0,1fr)_128px] xl:items-start">
        <div className="space-y-2">
          <Badge variant={dateStateVariant[item.dateState]}>{formatReadableDate(item.plannedFor)}</Badge>
          <Badge variant="muted">{item.priority} priority</Badge>
        </div>

        <div className="min-w-0">
          <h4 className="truncate text-[16px] font-semibold leading-snug">{item.studentName}</h4>
          <Badge className="mt-2" variant={assignmentVariant}>
            {assignmentLabel}
          </Badge>
        </div>

        <div className="min-w-0">
          <p className="field-label flex items-center gap-1.5">
            <ArrowRight className="h-3.5 w-3.5 text-primary" aria-hidden="true" />
            First check
          </p>
          <p className="mt-1 line-clamp-2 text-sm leading-5">{item.firstCheck}</p>
        </div>

        <div className="min-w-0">
          <p className="field-label">Watch</p>
          <AttentionFlags flags={item.attentionFlags} />
        </div>

        <div className="flex xl:justify-end">
          <Button asChild variant="secondary" className="w-full whitespace-nowrap sm:w-auto">
            <Link href={studentHref}>Start lesson</Link>
          </Button>
        </div>
      </div>
    </article>
  );
}

function AttentionFlags({ flags }: { flags: LessonAttentionFlag[] }) {
  if (flags.length === 0) {
    return (
      <p className="mt-1 flex items-center gap-1.5 text-sm leading-5 text-muted-foreground">
        <CheckCircle2 className="h-3.5 w-3.5 text-accent" aria-hidden="true" />
        Ready
      </p>
    );
  }

  return (
    <div className="mt-2 flex flex-wrap gap-2">
      {flags.map((flag) => (
        <Badge key={flag} variant={flag === "overdue_plan" ? "attention" : "muted"}>
          {flag === "overdue_plan" ? (
            <AlertTriangle className="mr-1 h-3 w-3" aria-hidden="true" />
          ) : (
            <CircleDashed className="mr-1 h-3 w-3" aria-hidden="true" />
          )}
          {attentionLabelByFlag[flag]}
        </Badge>
      ))}
    </div>
  );
}
