# Phase 4A Workbench Filters And Progress Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Make the dashboard and Progress tab faster for daily scanning by adding focused roster filters and one-step progress status transitions.

**Architecture:** Keep filtering client-side over the existing roster read model for this slice. Add small status-transition server actions that reuse the existing progress write path and current-focus rules.

**Tech Stack:** Next.js App Router, TypeScript, Supabase/Postgres, Zod, Tailwind CSS v4, shadcn/ui primitives.

---

## Scope

Included:

- Dashboard filters:
  - `Needs review`
  - `High priority`
  - `No recent note`
  - `Missing current focus`
  - `Inactive hidden` remains the default because roster reads active students only.
- Filter count feedback.
- Empty state for a filter with no matches.
- Progress status quick transitions from the Progress list.
- Existing full progress edit form remains available.

Out of scope:

- Saved filters.
- Search across every note.
- Analytics charts.
- Scheduling or calendar automation.
- Batch actions.

## Requirements Covered

- `ROST-05`
- `PROG-04`

## Files To Create

- `src/components/dashboard/roster-filters.tsx`
  - Client component for local filter controls.

- `src/components/dashboard/filterable-student-roster.tsx`
  - Client wrapper that applies filters to roster data and renders rows.

- `src/components/students/progress-status-actions.tsx`
  - Small action controls for status movement.

## Files To Modify

- `src/lib/supabase/read-models.ts`
  - Add `lastLessonDate` and `hasRecentNote` or equivalent roster fields needed for `No recent note`.

- `src/lib/supabase/read-models.test.mts`
  - Add filter-source derivation tests.

- `src/lib/supabase/queries.ts`
  - Include enough lesson note date data in roster reads to derive `No recent note`.

- `src/app/students/[studentId]/actions.ts`
  - Add `saveProgressItemStatusAction`.

- `src/components/dashboard/student-roster-preview.tsx`
  - Render filterable roster wrapper.

- `src/components/students/student-progress-list.tsx`
  - Add status quick actions to each progress row.

- `README.md`
  - Add Phase 4A smoke check.

## Filter Rules

- `Needs review`: assignment status is `needs_review` or at least one progress item status is `needs_review`.
- `High priority`: selected next lesson plan priority is `high`.
- `No recent note`: no lesson note in the last 14 days, based on `lesson_date`.
- `Missing current focus`: `currentFocus` is `null`.
- Filters can combine with AND semantics.
- Empty filter result shows a concise empty state and a `Clear filters` action.

## Progress Status Transition Rules

Allowed status movement:

- `new` -> `in_progress`
- `in_progress` -> `needs_review`
- `in_progress` -> `steady`
- `needs_review` -> `in_progress`
- `needs_review` -> `steady`
- `steady` -> `complete`
- `complete` -> `needs_review`

The full edit form still supports any valid status when the instructor needs a precise correction.

## Tasks

### Task 04A-01: Add Roster Filter Source Fields

- [x] Extend roster query to include latest lesson note date.
- [x] Extend read model with `lastLessonDate`, `hasRecentNote`, and a progress-needs-review boolean.
- [x] Add tests for recent-note threshold and needs-review derivation.
- [x] Run `npm test`.

### Task 04A-02: Add Dashboard Filter UI

- [x] Create `RosterFilters`.
- [x] Create `FilterableStudentRoster`.
- [x] Use segmented/toggle style controls, not bulky cards.
- [x] Show filtered count.
- [x] Add clear-filters action.
- [x] Verify dashboard stays readable at 320px.

### Task 04A-03: Add Progress Status Quick Action

- [x] Add schema/action input for progress id, student id, and next status.
- [x] Add `saveProgressItemStatusAction`.
- [x] Create `ProgressStatusActions`.
- [x] Add controls to `StudentProgressList`.
- [x] Revalidate `/` and `/students/{studentId}` after save.

### Task 04A-04: Verify Workbench Flow

- [x] Set one assignment to `needs_review`.
- [x] Confirm `Needs review` filter shows that student.
- [x] Set one next lesson to high priority.
- [x] Confirm `High priority` filter shows that student.
- [x] Move a progress item from `needs_review` to `steady`.
- [x] Refresh dashboard and detail page and confirm status changed.

## Verification

Run:

```bash
npm test
npm run build
npm run lint
rg "SERVICE_ROLE|service_role" src .env.example
```

Browser smoke:

1. Open `/`.
2. Toggle each roster filter and confirm matching rows.
3. Combine two filters and confirm AND behavior.
4. Clear filters.
5. Open a student detail page and use progress status quick action.
6. Refresh and confirm status persists.
7. Check desktop and 320px mobile width for text overlap.

## Completion Criteria

Phase 4A is complete when dashboard filtering and quick status transitions reduce repeated scanning work without changing the core data model beyond the read fields needed for filters.
