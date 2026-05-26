# Phase 3E Assignment Review Editing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Let the instructor create and update a student's current homework/practice assignment, then surface the review state in the dashboard, Lesson Brief, and Summary.

**Architecture:** Extend the existing student detail server-action pattern with assignment schemas and demo RLS. Keep assignments instructor-facing only; no student portal, notifications, or external reminders.

**Tech Stack:** Next.js App Router, TypeScript, Supabase/Postgres, Zod, Tailwind CSS v4, shadcn/ui primitives.

---

## Scope

Included:

- Create an assignment for a student.
- Update assignment title, status, due date, and detail.
- Keep status values aligned with the database:
  - `not_started`
  - `in_progress`
  - `needs_review`
  - `complete`
  - `paused`
- Make Lesson Brief assignment review cue reflect the saved assignment.
- Keep Today/Upcoming queue and roster assignment badges in sync.

Out of scope:

- Student portal.
- Practice submission.
- Assignment history timeline.
- Reminders, messages, due-date notifications, or calendar automation.
- Delete flows.

## Requirements Covered

- `NEXT-01`
- `NEXT-02`

## Files To Create

- `supabase/migrations/0007_demo_assignment_write_policy.sql`
  - Temporary anon insert/update policy for seeded-demo `assignments`.
  - DB-level blank/length checks for assignment text fields.

- `src/components/students/assignment-form.tsx`
  - Compact create/update assignment form for the Summary tab.

## Files To Modify

- `src/lib/students/editing-schemas.ts`
  - Add `assignmentStatuses`.
  - Add `assignmentInputSchema`.

- `src/lib/students/editing-schemas.test.mts`
  - Add assignment validation coverage.

- `src/lib/supabase/read-models.ts`
  - Add `id` to `AssignmentContextRow` and `StudentAssignment`.

- `src/lib/supabase/queries.ts`
  - Select assignment `id`.

- `src/app/students/[studentId]/actions.ts`
  - Add `saveAssignmentAction`.

- `src/components/students/student-summary-panel.tsx`
  - Render `AssignmentForm` in the existing Assignment panel.

- `README.md`
  - Add Phase 3E smoke check and demo policy note.

## Data Contract

Assignment input:

- `studentId`: required UUID.
- `assignmentId`: optional UUID for update.
- `title`: required, 1-160 characters after trim.
- `status`: one of the assignment statuses listed above.
- `dueDate`: optional `YYYY-MM-DD`.
- `detail`: required, 1-1000 characters after trim.

Behavior:

- If `assignmentId` exists, update that assignment for the current demo instructor and student.
- If `assignmentId` is blank, insert a new assignment for the current demo instructor and student.
- Pick latest assignment in read models by `created_at`, preserving current behavior.
- Revalidate `/` and `/students/{studentId}` after save because assignment badges appear on both screens.

## Tasks

### Task 03E-01: Add Assignment Validation And Types

- [x] Add assignment status constants and schema in `editing-schemas.ts`.
- [x] Add tests for valid create payload, valid update payload, blank title, blank detail, invalid status, invalid due date, and invalid UUID.
- [x] Run `npm test`.

### Task 03E-02: Add Demo Assignment Write Policy

- [x] Create `0007_demo_assignment_write_policy.sql`.
- [x] Add anon insert/update policies scoped to the seeded demo instructor id.
- [x] Limit direct writes to the fields used by the form.
- [x] Add DB checks for non-blank title/detail and conservative text lengths.
- [x] Run `supabase db push --linked --dry-run`.
- [x] Apply only after explicit approval.

### Task 03E-03: Add Read Model Assignment Id

- [x] Select assignment `id` in `src/lib/supabase/queries.ts`.
- [x] Add `id` to `AssignmentContextRow` and `StudentAssignment`.
- [x] Update read-model tests so selected assignment id is preserved.
- [x] Confirm existing dashboard and Lesson Brief tests still pass.

### Task 03E-04: Add Assignment Form And Action

- [x] Add `saveAssignmentAction` to the student actions file.
- [x] Create `AssignmentForm`.
- [x] Add the form to the Summary Assignment panel.
- [x] Keep the current readable assignment title/detail/badge visible above the form.
- [x] Revalidate dashboard and detail routes after save.

### Task 03E-05: Verify Review Cues

- [x] Set assignment status to `needs_review`.
- [x] Confirm Lesson Brief shows a review cue for that assignment.
- [x] Set assignment status to `complete`.
- [x] Confirm roster, queue, header, Summary, and Lesson Brief update after refresh.

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
2. In Summary, create or update the Assignment.
3. Change status to `needs_review`.
4. Refresh dashboard and confirm roster/queue badges match.
5. Open Lesson Brief and confirm assignment review cue matches the saved assignment.
6. Check 320px mobile width for form overflow.

## Completion Criteria

Phase 3E is complete when assignment create/update works end-to-end, assignment badges and Lesson Brief cues agree, and the temporary demo policy is documented.
