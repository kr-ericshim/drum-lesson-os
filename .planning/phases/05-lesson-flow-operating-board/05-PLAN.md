# Phase 5 Lesson Flow Operating Board Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Use `superpowers:test-driven-development` for behavior changes and `superpowers:verification-before-completion` before closeout.

**Goal:** Turn the existing dashboard Lesson Queue and student Lesson Brief/Closeout into one clear lesson-flow surface for pre-lesson triage, in-lesson checks, and post-lesson closeout.

**Architecture:** Keep the existing Supabase tables and server-action model. Extend the read model with operating-board fields, replace the dashboard queue presentation with a grouped operating board, and add a client-side in-lesson checklist/draft panel on the student detail page that can prefill the existing closeout form. No new domain tables are required for this phase.

**Tech Stack:** Next.js App Router, TypeScript, React client components where local draft state is needed, Supabase/Postgres, Zod, Tailwind CSS v4, shadcn-style local UI primitives, Node test runner.

---

## Product Direction

Phase 5 should make the app feel like a real lesson cockpit without widening into student portals, scheduling automation, billing, AI summaries, or media analysis.

The new flow:

1. The instructor opens the dashboard before teaching.
2. The operating board shows overdue, today, and upcoming lesson work with the first check visible.
3. The instructor opens a student and uses a short in-lesson checklist while teaching.
4. The checklist creates a closeout draft.
5. The existing closeout save still writes the durable lesson note, next lesson plan, assignment cue, and optional progress update.

## Scope

Included:

- Upgrade `LessonQueue` into an action-first `LessonOperatingBoard`.
- Add `firstCheck` and `attentionFlags` to each lesson queue item.
- Group queue items into `Overdue`, `Today`, and `Upcoming`.
- Keep each board row dense and scannable on desktop and 320px mobile.
- Add a student-detail `LessonFlowWorkspace` that combines:
  - existing `LessonBrief`
  - new in-lesson checklist/draft panel
  - existing closeout form
- Add a `LessonRunPanel` with session-local draft state for:
  - covered material
  - observation
  - practice assigned
  - next step hint
  - optional progress item to keep in focus
  - optional "stuck" marker wording
- Let `LessonRunPanel` send a draft into `LessonCloseoutForm` without saving partial data.
- Preserve the closeout RPC as the only durable post-lesson write path for the combined closeout.

Out of scope:

- No new Supabase tables for temporary in-lesson drafts.
- No student portal or student login.
- No attendance, billing, calendar sync, reminders, or messaging.
- No AI summaries or audio/video analysis.
- No full syllabus/curriculum builder.
- No route redesign beyond the dashboard and student detail surfaces.

## Requirements Added

- `FLOW-01`: Instructor can see the first action to check for each queued lesson from the dashboard.
- `FLOW-02`: Instructor can tell which queued lessons are overdue, today, or upcoming without reading every date.
- `FLOW-03`: Instructor can record short in-lesson working notes before committing the final closeout.
- `FLOW-04`: Instructor can turn in-lesson working notes into a closeout draft without retyping.
- `FLOW-05`: Existing closeout remains the durable save path and keeps dashboard/detail state aligned after refresh.

## Files To Create

- `src/components/dashboard/lesson-operating-board.tsx`
  - Replaces the visible dashboard queue component.
  - Groups `LessonQueueItem[]` by `dateState`.
  - Renders one action-first row per queued lesson.

- `src/components/students/lesson-flow-workspace.tsx`
  - Client component that owns closeout draft state.
  - Renders `LessonBrief`, `LessonRunPanel`, and `LessonCloseoutForm`.

- `src/components/students/lesson-run-panel.tsx`
  - Client component for in-lesson working notes and checklist actions.
  - Does not write to Supabase.

- `src/lib/students/lesson-closeout-draft.ts`
  - Pure helper and type for converting in-lesson working notes into closeout defaults.
  - Keeps `nextStepHint` and `nextAction` aligned unless the instructor edits the closeout form.

- `src/lib/students/lesson-closeout-draft.test.mts`
  - Node tests for draft fallback and `nextAction` alignment.

- `src/lib/students/status-options.ts`
  - Schema-free option constants that client components can import without pulling Zod into the client bundle.

## Files To Modify

- `src/app/page.tsx`
  - Import and render `LessonOperatingBoard` instead of `LessonQueue`.

- `src/app/students/[studentId]/page.tsx`
  - Render `LessonFlowWorkspace` in place of separate `LessonBrief` and `LessonCloseoutForm`.

- `src/components/students/lesson-closeout-form.tsx`
  - Convert to a client-compatible component if needed.
  - Accept an optional `draft` prop.
  - Use draft values as defaults for closeout fields.
  - Auto-open the closeout details region when a draft is sent from the run panel.
  - Import option constants from `src/lib/students/status-options.ts`, not from the Zod schema module.

- `src/lib/supabase/read-models.ts`
  - Add `firstCheck` and `attentionFlags` to `LessonQueueItem`.
  - Add a pure `buildAttentionFlags` helper.
  - Keep sorting stable.

- `src/lib/students/editing-schemas.ts`
  - Import option constants from `src/lib/students/status-options.ts`.
  - Keep validation schemas server/shared-safe.

- `src/lib/supabase/read-models.test.mts`
  - Cover board fields and attention flags.

- `README.md`
  - Add Phase 5 smoke checks.

Optional if the implementation exposes new requirement tracking:

- `.planning/REQUIREMENTS.md`
  - Add `FLOW-01` through `FLOW-05`.

- `.planning/ROADMAP.md`
  - Add Phase 5 as planned or in progress.

- `.planning/STATE.md`
  - Update current position only when Phase 5 execution begins.

## Data Contract

No database migration is planned.

`LessonQueueItem` should become:

```ts
export type LessonAttentionFlag =
  | "assignment_needs_review"
  | "missing_current_focus"
  | "missing_recent_note"
  | "overdue_plan"
  | "stale_focus";

export type LessonQueueItem = {
  studentId: string;
  studentSlug?: string;
  studentName: string;
  currentFocus: ProgressFocusSummary | null;
  assignmentStatus: string;
  nextAction: string;
  priority: string;
  plannedFor: string;
  dateState: "overdue" | "today" | "upcoming";
  firstCheck: string;
  attentionFlags: LessonAttentionFlag[];
};
```

`LessonCloseoutDraft` should live near the student lesson-flow components:

```ts
export type LessonCloseoutDraft = {
  coveredMaterial: string;
  observations: string;
  practiceAssigned: string;
  nextStepHint: string;
  nextAction: string;
  progressItemId?: string;
  progressCurrentFocus?: boolean;
};
```

Draft rule:

- `nextStepHint` fills the new lesson note's first-check hint.
- `nextAction` fills the next lesson plan action.
- `LessonRunPanel` should initialize both from the same in-lesson "Next hint" value so the dashboard operating board and student Lesson Brief do not split after save.
- The instructor can still edit either field in Closeout before saving.

## Detailed Tasks

### Task 05-01: Extend The Lesson Queue Read Model

**Files:**

- Modify: `src/lib/supabase/read-models.ts`
- Modify: `src/lib/supabase/read-models.test.mts`

- [ ] **Step 1: Add failing tests for operating-board fields**

Add tests that prove `mapLessonQueue` includes `firstCheck` and `attentionFlags`.

```ts
test("mapLessonQueue exposes first check and attention flags", () => {
  const [student] = mapStudentRoster(
    [
      {
        id: "student-1",
        slug: "kim-daniel",
        name: "Kim Daniel",
        profile_cue: "Needs demonstration before notation.",
        primary_weak_point: "Rushing fills",
        progress_items: [],
        assignments: [
          {
            id: "assignment-1",
            status: "needs_review",
            created_at: "2026-05-20T00:00:00Z",
            title: "Paradiddle grid",
            due_date: null,
            detail: "Check accents slowly.",
          },
        ],
        lesson_notes: [],
        next_lesson_plans: [
          {
            id: "plan-1",
            next_action: "Check paradiddle accents first",
            priority: "high",
            created_at: "2026-05-20T00:00:00Z",
            updated_at: "2026-05-20T00:00:00Z",
            planned_for: "2026-05-27",
            detail: "Start at 72 bpm.",
          },
        ],
      },
    ],
    "2026-05-28",
  );

  const [queueItem] = mapLessonQueue([student], "2026-05-28");

  assert.equal(queueItem.firstCheck, "Check paradiddle accents first");
  assert.deepEqual(queueItem.attentionFlags, [
    "assignment_needs_review",
    "missing_current_focus",
    "missing_recent_note",
    "overdue_plan",
  ]);
});
```

Add a second test for stale current focus:

```ts
test("mapLessonQueue flags stale current focus after two weeks", () => {
  const [student] = mapStudentRoster(
    [
      {
        id: "student-2",
        slug: "park-minjun",
        name: "Park Minjun",
        profile_cue: "Learns by call and response.",
        primary_weak_point: "Ghost notes disappear in grooves",
        progress_items: [
          {
            id: "progress-1",
            category: "rudiment",
            status: "in_progress",
            title: "Ghost note control",
            current_focus: true,
            observed_on: "2026-05-01",
            detail: "Keep taps low under backbeat.",
            tempo_note: "Clean at 70.",
          },
        ],
        assignments: [],
        lesson_notes: [{ lesson_date: "2026-05-20" }],
        next_lesson_plans: [
          {
            id: "plan-2",
            next_action: "Listen for ghost notes under groove",
            priority: "normal",
            created_at: "2026-05-20T00:00:00Z",
            updated_at: "2026-05-20T00:00:00Z",
            planned_for: "2026-05-28",
            detail: "Use 8th-note groove.",
          },
        ],
      },
    ],
    "2026-05-28",
  );

  const [queueItem] = mapLessonQueue([student], "2026-05-28");

  assert.equal(queueItem.firstCheck, "Listen for ghost notes under groove");
  assert.deepEqual(queueItem.attentionFlags, ["stale_focus"]);
});
```

- [ ] **Step 2: Run the focused test and confirm failure**

Run:

```bash
npm test -- src/lib/supabase/read-models.test.mts
```

Expected:

- Fails because `LessonQueueItem.firstCheck` and `LessonQueueItem.attentionFlags` do not exist.

- [ ] **Step 3: Add read-model types and helper**

In `src/lib/supabase/read-models.ts`, add:

```ts
export type LessonAttentionFlag =
  | "assignment_needs_review"
  | "missing_current_focus"
  | "missing_recent_note"
  | "overdue_plan"
  | "stale_focus";
```

Update `LessonQueueItem`:

```ts
export type LessonQueueItem = {
  studentId: string;
  studentSlug?: string;
  studentName: string;
  currentFocus: ProgressFocusSummary | null;
  assignmentStatus: string;
  nextAction: string;
  priority: string;
  plannedFor: string;
  dateState: "overdue" | "today" | "upcoming";
  firstCheck: string;
  attentionFlags: LessonAttentionFlag[];
};
```

Add helper functions:

```ts
const staleFocusWindowDays = 14;

function buildLessonQueueFirstCheck(student: StudentRosterItem) {
  return student.nextAction || student.currentFocus?.title || "Set next lesson action";
}

function buildAttentionFlags(
  student: StudentRosterItem,
  plannedFor: string,
  todayDate: string,
): LessonAttentionFlag[] {
  const flags: LessonAttentionFlag[] = [];

  if (student.assignmentStatus === "needs_review") {
    flags.push("assignment_needs_review");
  }

  if (!student.currentFocus) {
    flags.push("missing_current_focus");
  }

  if (!student.hasRecentNote) {
    flags.push("missing_recent_note");
  }

  if (plannedFor < todayDate) {
    flags.push("overdue_plan");
  }

  if (student.currentFocus && isStaleLessonDate(student.currentFocus.observedOn, todayDate)) {
    flags.push("stale_focus");
  }

  return flags;
}

function isStaleLessonDate(lessonDate: string, todayDate: string) {
  const lessonTime = Date.parse(`${lessonDate}T00:00:00Z`);
  const todayTime = Date.parse(`${todayDate}T00:00:00Z`);

  if (Number.isNaN(lessonTime) || Number.isNaN(todayTime)) {
    return false;
  }

  const dayDifference = Math.floor((todayTime - lessonTime) / 86_400_000);

  return dayDifference > staleFocusWindowDays;
}
```

- [ ] **Step 4: Wire helper into `mapLessonQueue`**

Inside `mapLessonQueue`, return the new fields:

```ts
return {
  studentId: student.id,
  ...(student.slug ? { studentSlug: student.slug } : {}),
  studentName: student.name,
  currentFocus: student.currentFocus,
  assignmentStatus: student.assignmentStatus,
  nextAction: student.nextAction,
  priority: student.nextPlan?.priority ?? "normal",
  plannedFor,
  dateState: getDateState(plannedFor, todayDate),
  firstCheck: buildLessonQueueFirstCheck(student),
  attentionFlags: buildAttentionFlags(student, plannedFor, todayDate),
};
```

- [ ] **Step 5: Run focused and full tests**

Run:

```bash
npm test -- src/lib/supabase/read-models.test.mts
npm test
```

Expected:

- Focused read-model test passes.
- Full test suite passes.

- [ ] **Step 6: Commit Task 05-01**

Run:

```bash
git add src/lib/supabase/read-models.ts src/lib/supabase/read-models.test.mts
git commit -m "feat: add lesson operating board read model"
```

### Task 05-02: Replace Lesson Queue With Operating Board

**Files:**

- Create: `src/components/dashboard/lesson-operating-board.tsx`
- Modify: `src/app/page.tsx`
- Optional delete after replacement: `src/components/dashboard/lesson-queue.tsx`

- [ ] **Step 1: Create the operating board component**

Create `src/components/dashboard/lesson-operating-board.tsx`:

```tsx
import Link from "next/link";
import { AlertTriangle, ArrowRight, CalendarClock, CheckCircle2, CircleDashed } from "lucide-react";

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
  key: LessonQueueItem["dateState"];
  label: string;
  empty: string;
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
          <Badge variant={itemCount > 0 ? "default" : "muted"}>
            {itemCount} queued
          </Badge>
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
        <CheckCircle2 className="h-3.5 w-3.5 text-steady" aria-hidden="true" />
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
```

- [ ] **Step 2: Render it from the dashboard**

In `src/app/page.tsx`, replace the import:

```ts
import { LessonOperatingBoard } from "@/components/dashboard/lesson-operating-board";
```

Replace:

```tsx
<LessonQueue items={lessonQueue} />
```

with:

```tsx
<LessonOperatingBoard items={lessonQueue} />
```

- [ ] **Step 3: Remove the old queue only after import replacement**

If `rg "LessonQueue" src` returns no app usage, delete:

```text
src/components/dashboard/lesson-queue.tsx
```

Keep the `LessonQueueItem` type name in `read-models.ts` because the type still describes queued lesson work.

- [ ] **Step 4: Run static checks**

Run:

```bash
npm run lint
npm run build
```

Expected:

- No unused `LessonQueue` import.
- Build passes with `LessonOperatingBoard`.

- [ ] **Step 5: Browser smoke the dashboard**

Start the app if needed:

```bash
npm run dev
```

Verify with Browser plugin:

- Desktop dashboard renders `Lesson operating board`.
- Board contains `Overdue`, `Today`, and `Upcoming` groups.
- Each row exposes `First check`.
- `Start lesson` opens the expected `/students/{slug}` route.
- 320px mobile width has no horizontal overflow or overlapping text.

- [ ] **Step 6: Commit Task 05-02**

Run:

```bash
git add src/app/page.tsx src/components/dashboard/lesson-operating-board.tsx
git add -u src/components/dashboard/lesson-queue.tsx
git commit -m "feat: add lesson operating board"
```

### Task 05-03: Add Student Lesson Flow Workspace

**Files:**

- Create: `src/components/students/lesson-flow-workspace.tsx`
- Create: `src/components/students/lesson-run-panel.tsx`
- Create: `src/lib/students/lesson-closeout-draft.ts`
- Create: `src/lib/students/lesson-closeout-draft.test.mts`
- Create: `src/lib/students/status-options.ts`
- Modify: `src/components/students/lesson-closeout-form.tsx`
- Modify: `src/app/students/[studentId]/page.tsx`
- Modify: `src/lib/students/editing-schemas.ts`

- [ ] **Step 1: Create the closeout draft helper and test**

Create `src/lib/students/lesson-closeout-draft.ts`:

```ts
export type LessonCloseoutDraft = {
  coveredMaterial: string;
  observations: string;
  practiceAssigned: string;
  nextStepHint: string;
  nextAction: string;
  progressItemId?: string;
  progressCurrentFocus?: boolean;
};

export type LessonCloseoutDraftInput = {
  coveredMaterial: string;
  observation: string;
  practiceAssigned: string;
  nextStepHint: string;
  selectedChecklistLabels: string[];
  fallbackFirstCheck: string;
  fallbackObservation: string;
  fallbackPracticeAssigned: string;
  progressItemId?: string;
  progressCurrentFocus: boolean;
};

export function buildLessonCloseoutDraft(input: LessonCloseoutDraftInput): LessonCloseoutDraft {
  const checklistSummary = input.selectedChecklistLabels.join("; ");
  const nextHint = input.nextStepHint || input.fallbackFirstCheck;

  return {
    coveredMaterial: input.coveredMaterial || checklistSummary || input.fallbackFirstCheck,
    observations: input.observation || checklistSummary || input.fallbackObservation,
    practiceAssigned: input.practiceAssigned || input.fallbackPracticeAssigned,
    nextStepHint: nextHint,
    nextAction: nextHint,
    progressItemId: input.progressItemId || undefined,
    progressCurrentFocus: input.progressCurrentFocus,
  };
}
```

Create `src/lib/students/lesson-closeout-draft.test.mts`:

```ts
import assert from "node:assert/strict";
import test from "node:test";

import { buildLessonCloseoutDraft } from "./lesson-closeout-draft.ts";

test("buildLessonCloseoutDraft keeps next hint and next action aligned", () => {
  const draft = buildLessonCloseoutDraft({
    coveredMaterial: "",
    observation: "Fill rushed after bar 4.",
    practiceAssigned: "",
    nextStepHint: "Check fill at 72 bpm before groove.",
    selectedChecklistLabels: ["First check", "Weak point"],
    fallbackFirstCheck: "Review paradiddle accents.",
    fallbackObservation: "No recent observation recorded.",
    fallbackPracticeAssigned: "Paradiddle grid needs review: slow accents.",
    progressItemId: "progress-1",
    progressCurrentFocus: true,
  });

  assert.equal(draft.nextStepHint, "Check fill at 72 bpm before groove.");
  assert.equal(draft.nextAction, "Check fill at 72 bpm before groove.");
  assert.equal(draft.observations, "Fill rushed after bar 4.");
  assert.equal(draft.practiceAssigned, "Paradiddle grid needs review: slow accents.");
  assert.equal(draft.progressItemId, "progress-1");
  assert.equal(draft.progressCurrentFocus, true);
});

test("buildLessonCloseoutDraft falls back to checked items and first check", () => {
  const draft = buildLessonCloseoutDraft({
    coveredMaterial: "",
    observation: "",
    practiceAssigned: "",
    nextStepHint: "",
    selectedChecklistLabels: ["First check", "Assignment review"],
    fallbackFirstCheck: "Review ghost notes first.",
    fallbackObservation: "Last note was about ghost note balance.",
    fallbackPracticeAssigned: "Practice groove slowly.",
    progressItemId: "",
    progressCurrentFocus: false,
  });

  assert.equal(draft.coveredMaterial, "First check; Assignment review");
  assert.equal(draft.observations, "First check; Assignment review");
  assert.equal(draft.nextStepHint, "Review ghost notes first.");
  assert.equal(draft.nextAction, "Review ghost notes first.");
  assert.equal(draft.progressItemId, undefined);
});
```

- [ ] **Step 2: Run the draft helper test**

Run:

```bash
node --disable-warning=ExperimentalWarning --disable-warning=MODULE_TYPELESS_PACKAGE_JSON --experimental-strip-types --test src/lib/students/lesson-closeout-draft.test.mts
```

Expected:

- Passes and proves the draft keeps note hint and next plan action aligned.

- [ ] **Step 3: Create the schema-free status option module**

Create `src/lib/students/status-options.ts`:

```ts
export const nextPlanPriorities = ["low", "normal", "high"] as const;
export const progressItemCategories = [
  "book",
  "song",
  "rudiment",
  "genre",
  "technique",
  "session",
  "assignment",
] as const;
export const progressItemStatuses = [
  "new",
  "in_progress",
  "needs_review",
  "steady",
  "complete",
] as const;
export const assignmentStatuses = [
  "not_started",
  "in_progress",
  "needs_review",
  "complete",
  "paused",
] as const;
export const studentTraitTypes = [
  "strength",
  "weak_point",
  "practice_habit",
  "learning_style",
  "musical_preference",
  "caution",
] as const;
```

Update `src/lib/students/editing-schemas.ts` to import those constants and remove the local exported definitions:

```ts
import { z } from "zod";

import {
  assignmentStatuses,
  nextPlanPriorities,
  progressItemCategories,
  progressItemStatuses,
  studentTraitTypes,
} from "@/lib/students/status-options";

export {
  assignmentStatuses,
  nextPlanPriorities,
  progressItemCategories,
  progressItemStatuses,
  studentTraitTypes,
};
```

- [ ] **Step 4: Create the shared workspace**

Create `src/components/students/lesson-flow-workspace.tsx`:

```tsx
"use client";

import { useState } from "react";

import { LessonBrief } from "@/components/students/lesson-brief";
import { LessonCloseoutForm } from "@/components/students/lesson-closeout-form";
import { LessonRunPanel } from "@/components/students/lesson-run-panel";
import type { LessonCloseoutDraft } from "@/lib/students/lesson-closeout-draft";
import type { StudentDetail } from "@/lib/supabase/queries";

type LessonFlowWorkspaceProps = {
  student: StudentDetail;
};

export function LessonFlowWorkspace({ student }: LessonFlowWorkspaceProps) {
  const [draft, setDraft] = useState<LessonCloseoutDraft | null>(null);
  const [draftVersion, setDraftVersion] = useState(0);

  function handleDraftReady(nextDraft: LessonCloseoutDraft) {
    setDraft(nextDraft);
    setDraftVersion((current) => current + 1);
  }

  return (
    <section className="space-y-6" aria-label={`${student.name} lesson flow`}>
      <LessonBrief student={student} />
      <LessonRunPanel student={student} onDraftReady={handleDraftReady} />
      <LessonCloseoutForm key={draftVersion} draft={draft} student={student} />
    </section>
  );
}
```

- [ ] **Step 5: Create the run panel component**

Create `src/components/students/lesson-run-panel.tsx`:

```tsx
"use client";

import { ClipboardCheck, ListChecks } from "lucide-react";
import { useMemo, useState } from "react";

import { Button } from "@/components/ui/button";
import {
  buildLessonCloseoutDraft,
  type LessonCloseoutDraft,
} from "@/lib/students/lesson-closeout-draft";
import type { StudentDetail } from "@/lib/supabase/queries";

type LessonRunPanelProps = {
  onDraftReady: (draft: LessonCloseoutDraft) => void;
  student: StudentDetail;
};

const fieldClassName =
  "min-h-11 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm leading-6 shadow-sm outline-none transition-colors placeholder:text-muted-foreground focus-visible:border-ring focus-visible:outline-2 focus-visible:outline-ring";

export function LessonRunPanel({ onDraftReady, student }: LessonRunPanelProps) {
  const checklist = useMemo(() => buildChecklist(student), [student]);
  const [checkedItems, setCheckedItems] = useState<Record<string, boolean>>({});
  const [coveredMaterial, setCoveredMaterial] = useState("");
  const [observation, setObservation] = useState("");
  const [practiceAssigned, setPracticeAssigned] = useState("");
  const [nextStepHint, setNextStepHint] = useState(student.lessonBrief.firstCheck);
  const [progressItemId, setProgressItemId] = useState(student.currentFocus?.id ?? "");
  const [progressCurrentFocus, setProgressCurrentFocus] = useState(Boolean(student.currentFocus));

  const selectedChecklistLabels = checklist
    .filter((item) => checkedItems[item.id])
    .map((item) => item.label);

  function sendDraftToCloseout() {
    onDraftReady(buildLessonCloseoutDraft({
      coveredMaterial,
      observation,
      practiceAssigned,
      nextStepHint,
      selectedChecklistLabels,
      fallbackFirstCheck: student.lessonBrief.firstCheck,
      fallbackObservation: student.lessonBrief.latestObservation,
      fallbackPracticeAssigned: student.assignment?.detail || student.lessonBrief.assignmentReviewCue,
      progressItemId,
      progressCurrentFocus,
    }));
  }

  return (
    <section className="rounded-lg border border-border bg-card p-5" aria-labelledby="lesson-run-heading">
      <div className="flex items-center gap-2">
        <ListChecks className="h-4 w-4 text-primary" aria-hidden="true" />
        <div>
          <p className="quiet-label">During lesson</p>
          <h2 id="lesson-run-heading" className="mt-1 text-[20px] font-semibold leading-tight">
            Run the lesson
          </h2>
        </div>
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)]">
        <div>
          <p className="field-label">Checklist</p>
          <div className="mt-3 space-y-2">
            {checklist.map((item) => (
              <label
                className="flex items-start gap-3 rounded-lg border border-border bg-background p-3 text-sm leading-5"
                key={item.id}
              >
                <input
                  checked={Boolean(checkedItems[item.id])}
                  className="mt-1 h-4 w-4 rounded border-input text-primary"
                  onChange={(event) =>
                    setCheckedItems((current) => ({
                      ...current,
                      [item.id]: event.target.checked,
                    }))
                  }
                  type="checkbox"
                />
                <span>
                  <span className="font-semibold">{item.label}</span>
                  <span className="block text-muted-foreground">{item.detail}</span>
                </span>
              </label>
            ))}
          </div>
        </div>

        <div className="space-y-3">
          <TextAreaField
            label="Covered"
            onChange={setCoveredMaterial}
            placeholder="What actually happened in the lesson?"
            value={coveredMaterial}
          />
          <TextAreaField
            label="Observation"
            onChange={setObservation}
            placeholder="What changed, clicked, or got stuck?"
            value={observation}
          />
          <TextAreaField
            label="Practice assigned"
            onChange={setPracticeAssigned}
            placeholder="What should they practice this week?"
            value={practiceAssigned}
          />
          <TextAreaField
            label="Next hint"
            onChange={setNextStepHint}
            placeholder="First thing to check next time"
            value={nextStepHint}
          />

          <div className="grid gap-3 sm:grid-cols-[minmax(0,1fr)_180px]">
            <div>
              <label className="field-label" htmlFor={`run-progress-${student.id}`}>
                Progress focus
              </label>
              <select
                className={`${fieldClassName} mt-1`}
                id={`run-progress-${student.id}`}
                onChange={(event) => setProgressItemId(event.target.value)}
                value={progressItemId}
              >
                <option value="">No progress focus draft</option>
                {student.progressItems.map((item) => (
                  <option key={item.id} value={item.id}>
                    {item.title}
                  </option>
                ))}
              </select>
            </div>
            <label className="mt-6 flex items-start gap-3 text-sm leading-5">
              <input
                checked={progressCurrentFocus}
                className="mt-1 h-4 w-4 rounded border-input text-primary"
                onChange={(event) => setProgressCurrentFocus(event.target.checked)}
                type="checkbox"
              />
              <span>Keep as current focus</span>
            </label>
          </div>

          <div className="flex justify-end">
            <Button onClick={sendDraftToCloseout} type="button">
              <ClipboardCheck className="mr-2 h-4 w-4" aria-hidden="true" />
              Use in closeout
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}

function buildChecklist(student: StudentDetail) {
  return [
    {
      id: "first-check",
      label: "First check",
      detail: student.lessonBrief.firstCheck,
    },
    {
      id: "assignment",
      label: "Assignment review",
      detail: student.lessonBrief.assignmentReviewCue,
    },
    {
      id: "weak-point",
      label: "Weak point",
      detail: student.lessonBrief.weakPoint,
    },
    {
      id: "next-action",
      label: "Next action",
      detail: student.lessonBrief.nextAction,
    },
  ];
}

function TextAreaField({
  label,
  onChange,
  placeholder,
  value,
}: {
  label: string;
  onChange: (value: string) => void;
  placeholder: string;
  value: string;
}) {
  return (
    <label className="block">
      <span className="field-label">{label}</span>
      <textarea
        className={`${fieldClassName} mt-1 min-h-20 resize-y`}
        maxLength={2000}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
        value={value}
      />
    </label>
  );
}
```

- [ ] **Step 6: Update closeout form props for draft defaults**

At the top of `src/components/students/lesson-closeout-form.tsx`, add:

```tsx
"use client";
```

Import the draft type:

```ts
import type { LessonCloseoutDraft } from "@/lib/students/lesson-closeout-draft";
```

Change option imports to use the schema-free module:

```ts
import {
  assignmentStatuses,
  nextPlanPriorities,
  progressItemStatuses,
} from "@/lib/students/status-options";
```

Change props:

```ts
type LessonCloseoutFormProps = {
  draft?: LessonCloseoutDraft | null;
  student: StudentDetail;
};
```

Change function signature:

```tsx
export function LessonCloseoutForm({ draft = null, student }: LessonCloseoutFormProps) {
```

Change `<details>`:

```tsx
<details className="mt-4 border-t border-border pt-4" open={Boolean(draft)}>
```

Apply draft defaults:

```tsx
<TextAreaField
  defaultValue={draft?.coveredMaterial ?? ""}
  id="closeout-covered"
  label="Covered"
  maxLength={2000}
  name="coveredMaterial"
  placeholder="What happened today?"
/>
```

```tsx
<TextAreaField
  defaultValue={draft?.observations ?? ""}
  id="closeout-observations"
  label="Observation"
  maxLength={2000}
  name="observations"
  placeholder="What changed or got stuck?"
/>
```

```tsx
<TextAreaField
  defaultValue={draft?.practiceAssigned ?? ""}
  id="closeout-practice"
  label="Practice assigned"
  maxLength={2000}
  name="practiceAssigned"
  placeholder="What should they practice?"
/>
```

```tsx
<TextAreaField
  defaultValue={draft?.nextStepHint ?? ""}
  id="closeout-next-hint"
  label="Next hint"
  maxLength={1000}
  name="nextStepHint"
  placeholder="First thing to check next time"
/>
```

Set the next action default so the dashboard operating board and student detail stay aligned after save:

```tsx
<input
  className={`${fieldClassName} mt-1`}
  defaultValue={draft?.nextAction ?? student.nextPlan?.nextAction ?? ""}
  id="closeout-next-action"
  maxLength={240}
  name="nextAction"
  placeholder="What should happen first next lesson?"
  required
  type="text"
/>
```

Set the progress item default:

```tsx
<SelectField
  defaultValue={draft?.progressItemId ?? ""}
  id="closeout-progress-item"
  label="Progress item"
  name="progressItemId"
  options={[
    { label: "Skip progress update", value: "" },
    ...student.progressItems.map((item) => ({
      label: item.title,
      value: item.id,
    })),
  ]}
/>
```

Set the current-focus checkbox default:

```tsx
<input
  className="mt-1 h-4 w-4 rounded border-input text-primary"
  defaultChecked={Boolean(draft?.progressCurrentFocus)}
  name="progressCurrentFocus"
  type="checkbox"
/>
```

- [ ] **Step 7: Render workspace from the student detail page**

In `src/app/students/[studentId]/page.tsx`, remove:

```ts
import { LessonBrief } from "@/components/students/lesson-brief";
import { LessonCloseoutForm } from "@/components/students/lesson-closeout-form";
```

Add:

```ts
import { LessonFlowWorkspace } from "@/components/students/lesson-flow-workspace";
```

Replace:

```tsx
<LessonBrief student={studentResult.data} />
<LessonCloseoutForm student={studentResult.data} />
```

with:

```tsx
<LessonFlowWorkspace student={studentResult.data} />
```

- [ ] **Step 8: Run static checks**

Run:

```bash
npm run lint
npm run build
```

Expected:

- No server/client component import errors.
- Build passes with the closeout server action imported from the client-compatible closeout form.

- [ ] **Step 9: Browser smoke the student lesson flow**

With the app running:

1. Open `/students/{slug}`.
2. Confirm `Lesson brief`, `Run the lesson`, and `Closeout lesson` appear in order.
3. Check two checklist items in `Run the lesson`.
4. Fill `Observation` and `Next hint`.
5. Click `Use in closeout`.
6. Confirm the closeout form opens.
7. Confirm closeout `Observation` and `Next hint` contain the draft values.
8. Confirm both `Next hint` and `Next action` use the draft next-hint value unless edited.
9. Submit closeout with valid required fields.
10. Refresh.
11. Confirm dashboard operating board `First check`, header, Lesson Brief, Notes, and Progress/current-focus surfaces agree.
12. Repeat viewport check at 320px width.

- [ ] **Step 10: Commit Task 05-03**

Run:

```bash
git add 'src/app/students/[studentId]/page.tsx' src/components/students/lesson-flow-workspace.tsx src/components/students/lesson-run-panel.tsx src/components/students/lesson-closeout-form.tsx src/lib/students/lesson-closeout-draft.ts src/lib/students/lesson-closeout-draft.test.mts src/lib/students/status-options.ts src/lib/students/editing-schemas.ts
git commit -m "feat: add in-lesson run panel"
```

### Task 05-04: Documentation And Planning State

**Files:**

- Modify: `README.md`
- Modify: `.planning/REQUIREMENTS.md`
- Modify: `.planning/ROADMAP.md`
- Modify: `.planning/STATE.md`
- Create: `.planning/phases/05-lesson-flow-operating-board/05-CHECKPOINT.md`

- [ ] **Step 1: Add README smoke checks**

Add a Phase 5 section to `README.md`:

```md
### Phase 5 Lesson Flow Smoke Check

With Supabase env, auth user binding, and migrations through `0014` applied:

1. Sign in as the instructor.
2. Open `/` and confirm the lesson operating board groups overdue, today, and upcoming plans.
3. Confirm each queued lesson shows a first check and attention flags.
4. Open a student from `Start lesson`.
5. Use `Run the lesson` to draft an observation and next hint.
6. Send the draft into Closeout.
7. Save closeout and refresh.
8. Confirm dashboard, Lesson Brief, Notes, and Progress/current focus agree.
9. Check desktop and 320px mobile width for text overlap.
```

- [ ] **Step 2: Add requirements**

In `.planning/REQUIREMENTS.md`, add a `Lesson Flow` section:

```md
### Lesson Flow

- [x] **FLOW-01**: Instructor can see the first action to check for each queued lesson from the dashboard.
- [x] **FLOW-02**: Instructor can tell which queued lessons are overdue, today, or upcoming without reading every date.
- [x] **FLOW-03**: Instructor can record short in-lesson working notes before committing the final closeout.
- [x] **FLOW-04**: Instructor can turn in-lesson working notes into a closeout draft without retyping.
- [x] **FLOW-05**: Existing closeout remains the durable save path and keeps dashboard/detail state aligned after refresh.
```

Add traceability rows:

```md
| FLOW-01 | Phase 5 | Complete |
| FLOW-02 | Phase 5 | Complete |
| FLOW-03 | Phase 5 | Complete |
| FLOW-04 | Phase 5 | Complete |
| FLOW-05 | Phase 5 | Complete |
```

- [ ] **Step 3: Add roadmap phase**

In `.planning/ROADMAP.md`, add:

```md
- [x] **Phase 5: Lesson Flow Operating Board** - Connect dashboard triage, in-lesson checks, and closeout drafting into one lesson-flow surface. (completed 2026-05-28)
```

Add phase details:

```md
### Phase 5: Lesson Flow Operating Board

**Goal**: The instructor can run a lesson from the dashboard queue through in-lesson checks into closeout without retyping the same context.
**Mode:** mvp-polish
**UI hint**: yes
**Depends on**: Phase 4
**Requirements**: [FLOW-01, FLOW-02, FLOW-03, FLOW-04, FLOW-05]
**Success Criteria**:

  1. Dashboard queue shows first check and attention flags.
  2. Queue items are grouped into overdue, today, and upcoming.
  3. Student detail has a run-the-lesson panel between brief and closeout.
  4. Run panel drafts can prefill closeout fields.
  5. Closeout remains the only durable combined save path.
  6. Desktop and 320px mobile layouts remain readable and free of text overlap.

Plans:

- [x] 05: Add lesson operating board and in-lesson run panel. (completed 2026-05-28)
```

If implementation completes on a later date, use the date from `date +%F` in place of `2026-05-28`.

- [ ] **Step 4: Add checkpoint**

Create `.planning/phases/05-lesson-flow-operating-board/05-CHECKPOINT.md`:

```md
# 05 Checkpoint: Lesson Flow Operating Board

**Date:** 2026-05-28
**Status:** Complete

## Implemented

- Dashboard Lesson Queue became an action-first Lesson Operating Board.
- Board groups overdue, today, and upcoming lesson plans.
- Board rows show first check and attention flags.
- Student detail now has a Run the Lesson panel between Lesson Brief and Closeout.
- Run panel drafts can prefill Closeout without saving partial data.
- Closeout remains the durable save path.

## Verification

- `npm test` -> passed.
- `npm run build` -> passed.
- `npm run lint` -> passed.
- Browser desktop dashboard operating board smoke -> passed.
- Browser 320px dashboard operating board smoke -> passed.
- Browser student detail run-panel to closeout draft smoke -> passed.
- Browser closeout save and refresh consistency smoke -> passed.

## Remaining Follow-Up

None for Phase 5.
```

- [ ] **Step 5: Commit documentation**

Run:

```bash
git add README.md .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md .planning/phases/05-lesson-flow-operating-board/05-CHECKPOINT.md
git commit -m "docs: close lesson flow operating board phase"
```

## Verification

Run before claiming completion:

```bash
npm test
npm run build
npm run lint
git diff --check
```

Browser verification:

1. Dashboard at desktop width shows `Lesson operating board`.
2. Dashboard at 320px width has no horizontal overflow.
3. Operating board groups show overdue, today, and upcoming counts.
4. A queued student row shows first check and attention flags.
5. `Start lesson` opens the student detail page.
6. Student detail shows Lesson Brief, Run the Lesson, Closeout Lesson, then tabs.
7. Run panel draft prepopulates closeout fields.
8. Closeout submit persists after refresh.
9. Dashboard and student detail agree on next action, latest note, and current focus after save.

Search checks:

```bash
git diff -- src README.md | rg "portal|payment|invoice|attendance|calendar sync|AI summary|audio|video"
git diff --name-only -- supabase/migrations
```

Expected:

- First command has no matches. Exit code 1 from `rg` is acceptable when there are no matches.
- Second command prints nothing because Phase 5 adds no migration.

## Completion Criteria

Phase 5 is complete when the instructor can start from the dashboard operating board, open a student, run the lesson with a short checklist/draft, send that draft into closeout, save once, refresh, and see consistent dashboard/detail state at desktop and 320px mobile widths.

## Plan Self-Review

- Spec coverage: `FLOW-01` and `FLOW-02` are covered by Tasks 05-01 and 05-02. `FLOW-03` and `FLOW-04` are covered by Task 05-03. `FLOW-05` is covered by Tasks 05-03 and verification.
- Placeholder scan: No `TBD`, `TODO`, or implementation-later placeholders remain in this plan.
- Type consistency: `LessonAttentionFlag`, `LessonQueueItem`, and `LessonCloseoutDraft` are defined before use and reused consistently across tasks. Draft `nextStepHint` and `nextAction` are intentionally aligned by `buildLessonCloseoutDraft`.
- Scope check: The plan stays within dashboard, student detail, read-model tests, draft helper tests, and docs. It avoids new tables and excluded product domains.
