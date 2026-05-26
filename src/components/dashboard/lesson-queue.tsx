import Link from "next/link";
import { ArrowRight, CalendarClock } from "lucide-react";

import {
  assignmentLabelByStatus,
  assignmentVariantByStatus,
  formatReadableDate,
} from "@/components/students/status-labels";
import { Badge, type BadgeProps } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import type { LessonQueueItem } from "@/lib/supabase/read-models";

type LessonQueueProps = {
  items: LessonQueueItem[];
};

const dateStateLabel: Record<LessonQueueItem["dateState"], string> = {
  overdue: "Overdue",
  today: "Today",
  upcoming: "Upcoming",
};

const dateStateVariant: Record<LessonQueueItem["dateState"], BadgeProps["variant"]> = {
  overdue: "attention",
  today: "default",
  upcoming: "muted",
};

export function LessonQueue({ items }: LessonQueueProps) {
  return (
    <section className="rounded-lg border border-border bg-card" aria-labelledby="lesson-queue-heading">
      <div className="border-b border-border p-5">
        <div className="flex items-center gap-2">
          <CalendarClock className="h-4 w-4 text-primary" aria-hidden="true" />
          <div>
            <p className="quiet-label">Lesson queue</p>
            <h2 id="lesson-queue-heading" className="mt-1 text-[20px] font-semibold leading-tight">
              Today and upcoming
            </h2>
          </div>
        </div>
      </div>

      {items.length === 0 ? (
        <p className="p-5 text-sm leading-6 text-muted-foreground">
          No dated next lesson plans yet.
        </p>
      ) : (
        <div className="divide-y divide-border">
          {items.map((item) => {
            const assignmentVariant = assignmentVariantByStatus[item.assignmentStatus] ?? "muted";
            const assignmentLabel =
              assignmentLabelByStatus[item.assignmentStatus] ?? item.assignmentStatus;
            const studentHref = `/students/${item.studentSlug ?? item.studentId}`;

            return (
              <article
                key={`${item.studentId}-${item.plannedFor}`}
                className="grid gap-4 p-5 xl:grid-cols-[160px_minmax(150px,0.7fr)_minmax(0,1.15fr)_minmax(0,1fr)_136px] xl:items-start"
              >
                <div className="flex flex-wrap items-center gap-2 xl:block xl:space-y-2">
                  <Badge variant={dateStateVariant[item.dateState]}>
                    {dateStateLabel[item.dateState]}
                  </Badge>
                  <p className="field-label">{formatReadableDate(item.plannedFor)}</p>
                  <Badge variant="muted">{item.priority} priority</Badge>
                </div>

                <div className="min-w-0">
                  <h3 className="truncate text-[16px] font-semibold leading-snug">
                    {item.studentName}
                  </h3>
                  <Badge className="mt-2" variant={assignmentVariant}>
                    {assignmentLabel}
                  </Badge>
                </div>

                <div className="min-w-0">
                  <p className="field-label flex items-center gap-1.5">
                    <ArrowRight className="h-3.5 w-3.5 text-primary" aria-hidden="true" />
                    Next lesson
                  </p>
                  <p className="mt-1 line-clamp-2 text-sm leading-5">{item.nextAction}</p>
                </div>

                <div className="min-w-0">
                  <p className="field-label">Current focus</p>
                  <p className="mt-1 line-clamp-2 text-sm leading-5">
                    {item.currentFocus?.title ?? "No current focus set"}
                  </p>
                </div>

                <div className="flex xl:justify-end">
                  <Button asChild variant="secondary" className="w-full whitespace-nowrap sm:w-auto">
                    <Link href={studentHref} aria-label={`Open student ${item.studentName}`}>
                      Open student
                    </Link>
                  </Button>
                </div>
              </article>
            );
          })}
        </div>
      )}
    </section>
  );
}
