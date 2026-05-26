# Phase 4B Tempo And Quick Add Refinements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the smallest drum-specific checkpoint and dashboard quick-add actions that help between lessons without turning the app into analytics, scheduling, or a student portal product.

**Architecture:** Add one optional progress tempo note field, then add limited dashboard quick actions that reuse existing lesson-note and next-plan server actions. Keep the dashboard actions intentionally narrow.

**Tech Stack:** Next.js App Router, TypeScript, Supabase/Postgres, Zod, Tailwind CSS v4, shadcn/ui primitives.

---

## Scope

Included:

- Optional `tempo_note` on progress items.
- Tempo note appears in progress rows and Lesson Brief current-focus detail when present.
- Dashboard quick actions for:
  - add a short lesson note
  - update next lesson action
  - mark assignment as `needs_review`
- Quick actions use existing tables and do not introduce a new dashboard-specific data model.

Out of scope:

- BPM graphs.
- Practice analytics.
- Audio/video upload.
- Automatic BPM detection.
- Student reminders.
- Calendar events.
- Bulk dashboard editing.

## Requirements Covered

- `PROG-05`
- `QUICK-01`

## Files To Create

- `supabase/migrations/0008_progress_tempo_note.sql`
  - Adds nullable `tempo_note` to `progress_items`.
  - Adds conservative text length check.

- `src/components/dashboard/student-quick-actions.tsx`
  - Compact quick action controls inside or near each roster row.

- `src/components/students/tempo-note-field.tsx`
  - Small reusable field for progress item forms.

## Files To Modify

- `src/types/database.ts`
  - Add `tempo_note` to progress item Row/Insert/Update types.

- `supabase/seed.sql`
  - Add a few realistic tempo notes to seeded progress items.

- `src/lib/students/editing-schemas.ts`
  - Add optional `tempoNote` to progress item schema.
  - Add quick-action schemas.

- `src/lib/students/editing-schemas.test.mts`
  - Add tempo note and dashboard quick-action validation tests.

- `src/lib/supabase/read-models.ts`
  - Add `tempoNote` to progress source/read models and current-focus summary.

- `src/lib/supabase/read-models.test.mts`
  - Add tempo note mapping tests.

- `src/lib/supabase/queries.ts`
  - Select `tempo_note` from progress items.

- `src/app/students/[studentId]/actions.ts`
  - Include tempo note in `saveProgressItemAction`.
  - Add narrow quick-action handlers if existing actions cannot be reused cleanly.

- `src/components/students/progress-item-form.tsx`
  - Add optional tempo note field.

- `src/components/students/student-progress-list.tsx`
  - Show tempo note when present.

- `src/components/dashboard/student-summary-row.tsx`
  - Add quick action entry points without crowding roster scan text.

- `README.md`
  - Add Phase 4B smoke check and migration note.

## Data Contract

Progress tempo note:

- `tempoNote`: optional text, maximum 240 characters.
- Examples:
  - `Clean at 84, tense at 96.`
  - `Keep 92 bpm until ghost notes stay below backbeat.`
  - `Comfortable at 70 with click, rushes at 76.`

Quick note:

- Creates a lesson note with a short required observation.
- Uses today's date by default.
- Requires covered/practice/next hint values, prefilled with concise defaults that the instructor can edit.

Quick next action:

- Updates the selected next lesson plan's `next_action`.
- Preserves existing planned date, priority, and detail.
- If no plan exists, creates a minimal normal-priority plan with `nextAction` as the initial detail.

Mark needs review:

- Updates the latest assignment status to `needs_review`.
- If no assignment exists, quick action is hidden or disabled with clear copy.

## Tasks

### Task 04B-01: Add Tempo Note Data Field

- [x] Create `0008_progress_tempo_note.sql`.
- [x] Add nullable `tempo_note text`.
- [x] Add check constraint for max 240 characters when present.
- [x] Update `src/types/database.ts`.
- [x] Run `supabase db push --linked --dry-run`.
- [x] Apply only after explicit approval because this changes schema.
- [x] Apply `0009_demo_progress_tempo_note_write_grant.sql` after explicit approval because it widens the temporary demo anon write grant.

### Task 04B-02: Wire Tempo Note Through Read/Write Models

- [x] Add `tempoNote` to progress schemas.
- [x] Select `tempo_note` in progress queries.
- [x] Add `tempoNote` to `StudentProgressItem` and `ProgressFocusSummary`.
- [x] Render tempo note in Progress rows and current-focus display.
- [x] Add tests for mapping and validation.
- [x] Browser-submit a tempo note after `0009` is applied.

### Task 04B-03: Add Dashboard Quick Actions

- [x] Create `StudentQuickActions`.
- [x] Add quick note action.
- [x] Add quick next-action update.
- [x] Add mark-assignment-needs-review action.
- [x] Keep actions visually secondary to the roster scan fields.
- [x] Revalidate dashboard and student detail routes after save.

### Task 04B-04: Verify The Actions Stay Small

- [x] Confirm quick note creates a real lesson note visible in Notes.
- [x] Confirm quick next action updates queue and detail header.
- [x] Confirm mark needs review updates roster, queue, Summary, and Lesson Brief.
- [x] Confirm no new student portal, scheduling, AI, media, or analytics routes were added.
- [x] Confirm tempo note renders in Progress row and Lesson Brief after `0009` is applied.

## Verification

Run:

```bash
npm test
npm run build
npm run lint
rg "SERVICE_ROLE|service_role" src .env.example
rg "portal|payment|invoice|attendance|calendar|AI summary|audio|video" src
```

Browser smoke:

1. Add a tempo note to a progress item.
2. Refresh detail and confirm Progress plus current-focus surfaces show it.
3. From the dashboard, add a short note.
4. Confirm the student Notes tab shows the note.
5. From the dashboard, update a next action.
6. Confirm queue and detail header update.
7. Mark assignment as needs review and confirm badges/cues update.
8. Check desktop and 320px mobile width for text overlap.

## Completion Criteria

Phase 4B is complete when tempo checkpoints and dashboard quick actions help short between-lesson updates while staying inside the instructor-side CRM scope.
