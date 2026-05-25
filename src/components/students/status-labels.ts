import type { BadgeProps } from "@/components/ui/badge";

export const assignmentVariantByStatus: Record<string, BadgeProps["variant"]> = {
  complete: "steady",
  in_progress: "default",
  needs_review: "attention",
  not_started: "muted",
  paused: "muted",
};

export const assignmentLabelByStatus: Record<string, string> = {
  complete: "Complete",
  in_progress: "In progress",
  needs_review: "Needs review",
  not_started: "Not started",
  paused: "Paused",
};

export const progressVariantByStatus: Record<string, BadgeProps["variant"]> = {
  complete: "steady",
  in_progress: "default",
  needs_review: "attention",
  new: "muted",
  steady: "steady",
};

export const progressLabelByStatus: Record<string, string> = {
  complete: "Complete",
  in_progress: "In progress",
  needs_review: "Needs review",
  new: "New",
  steady: "Steady",
};

export function formatReadableDate(value: string | null) {
  if (!value) {
    return "No date set";
  }

  return new Intl.DateTimeFormat("en", {
    month: "short",
    day: "numeric",
    year: "numeric",
  }).format(new Date(`${value}T00:00:00`));
}
