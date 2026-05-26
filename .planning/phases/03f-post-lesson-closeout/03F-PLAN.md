# Phase 3F Post-Lesson Closeout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Let the instructor finish a lesson in one compact flow that records the note, updates the next lesson action, refreshes assignment review, and optionally adjusts progress.

**Architecture:** Reuse the existing server actions where possible, then add one closeout-specific action that performs the small multi-table write in a predictable order. Keep the closeout UI on the student detail page so the instructor does not need a new route.

**Tech Stack:** Next.js App Router, TypeScript, Supabase/Postgres, Zod, Tailwind CSS v4, shadcn/ui primitives.

---

## Scope

Included:

- A `Closeout lesson` section on student detail.
- One form that captures:
  - lesson date
  - covered material
  - observations
  - practice assigned
  - next lesson action
  - next lesson detail
  - planned-for date
  - priority
  - assignment title/status/detail/due date
  - optional progress item status/current-focus update
- Save creates a lesson note.
- Save updates or creates the next lesson plan.
- Save updates or creates the active assignment when assignment fields are filled.
- Save can update one selected progress item status and current-focus flag.

Out of scope:

- AI-generated summaries.
- Audio/video attachments.
- Student-facing homework delivery.
- Full assignment history.
- Complex transaction UI or conflict resolution.

## Requirements Covered

- `CLOSE-01`
- `CLOSE-02`
- `CLOSE-03`

## Files To Create

- `src/components/students/lesson-closeout-form.tsx`
  - Compact closeout form on the detail page.

- `src/lib/students/closeout-schema.test.mts`
  - Tests focused on the multi-table closeout payload.

## Files To Modify

- `src/lib/students/editing-schemas.ts`
  - Add `lessonCloseoutInputSchema`.
  - Reuse existing date, priority, assignment status, and progress status constants.

- `src/app/students/[studentId]/actions.ts`
  - Add `closeoutLessonAction`.
  - Use existing helper checks for demo student ownership.

- `src/components/students/student-detail-tabs.tsx`
  - Add closeout section near the top of Summary or as a compact section above tabs.

- `src/components/students/student-summary-panel.tsx`
  - Ensure closeout does not duplicate existing forms in a confusing way.

- `src/lib/supabase/read-models.test.mts`
  - Add a regression showing closeout-updated note/assignment/next plan become the next Lesson Brief source.

- `README.md`
  - Add Phase 3F closeout smoke check.

## Data Contract

Required closeout fields:

- `studentId`: UUID.
- `lessonDate`: valid `YYYY-MM-DD`.
- `coveredMaterial`: 1-2000 characters.
- `observations`: 1-2000 characters.
- `practiceAssigned`: 1-2000 characters.
- `nextStepHint`: 1-1000 characters.
- `nextAction`: 1-240 characters.
- `nextPlanDetail`: 1-2000 characters.
- `priority`: `low`, `normal`, or `high`.

Optional closeout fields:

- `plannedFor`: nullable date.
- `assignmentId`: optional UUID.
- `assignmentTitle`: optional unless assignment status/detail is provided.
- `assignmentStatus`: optional assignment status.
- `assignmentDueDate`: nullable date.
- `assignmentDetail`: optional unless assignment title/status is provided.
- `progressItemId`: optional UUID.
- `progressStatus`: optional progress status.
- `progressCurrentFocus`: boolean.

Write order:

1. Confirm the student belongs to the demo instructor.
2. Insert `lesson_notes`.
3. Update or insert `next_lesson_plans`.
4. If assignment fields are present, update or insert `assignments`.
5. If a progress item is selected, update its status/current-focus state using the same focus-clearing rules as `saveProgressItemAction`.
6. Revalidate `/` and `/students/{studentId}`.

## Tasks

### Task 03F-01: Add Closeout Schema

- [x] Add `lessonCloseoutInputSchema`.
- [x] Add tests for required note/next-plan fields.
- [x] Add tests for optional assignment block behavior.
- [x] Add tests for optional progress update behavior.
- [x] Run `npm test`.

### Task 03F-02: Add Closeout Server Action

- [x] Add `closeoutLessonAction`.
- [x] Use the existing demo-student ownership helper.
- [x] Insert a lesson note first.
- [x] Save next lesson plan second.
- [x] Save assignment only when assignment fields are present.
- [x] Save progress only when a progress item id is present.
- [x] Revalidate dashboard and detail routes.

### Task 03F-03: Add Closeout UI

- [x] Create `LessonCloseoutForm`.
- [x] Place it near the top of the student detail workflow.
- [x] Keep it compact enough for use right after a lesson.
- [x] Use existing status/priority labels.
- [x] Avoid hiding the existing Summary, Progress, and Notes editing controls.

### Task 03F-04: Verify Briefing Refresh

- [x] Submit closeout with a new observation.
- [x] Confirm Notes tab shows the new note newest-first.
- [x] Confirm Lesson Brief latest observation uses the new note.
- [x] Confirm next lesson action in header, Summary, queue, and dashboard updates.
- [x] Confirm assignment review cue updates when assignment fields are saved.

## Verification

Run:

```bash
npm test
npm run build
npm run lint
rg "SERVICE_ROLE|service_role" src .env.example
```

Browser smoke:

1. Open a seeded student detail page.
2. Submit a closeout with lesson note, next action, and assignment review fields.
3. Refresh the detail page and confirm Lesson Brief reflects the closeout.
4. Refresh dashboard and confirm queue/roster reflect the next action and assignment status.
5. Submit a closeout that changes current focus and confirm only one Progress item has the focus badge.
6. Check 320px mobile width for form overflow.

## Completion Criteria

Phase 3F is complete when one compact closeout flow updates lesson note, next lesson, assignment review, and optional progress context without adding portal, AI, media, or scheduling behavior.
