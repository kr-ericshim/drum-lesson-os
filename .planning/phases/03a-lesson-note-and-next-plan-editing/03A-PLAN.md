---
phase: 3A
slug: lesson-note-and-next-plan-editing
title: Lesson Note And Next Plan Editing
type: standalone-plan
status: ready-to-execute
created: 2026-05-25
depends_on:
  - Phase 2: Student Roster And Detail Read Views
requirements_addressed: [NOTE-01, NOTE-02, NEXT-03]
requirements_deferred: [ROST-03, ROST-04, STUD-03, PROG-01, PROG-02, NEXT-01, NEXT-02]
---

# Phase 3A: Lesson Note And Next Plan Editing Plan

## Goal

Let the instructor update the teaching record from the existing student detail page by adding a dated lesson note and editing the next lesson plan.

## Assumptions

- Phase 3A is a narrow slice of Phase 3, not the whole Phase 3.
- Student profile editing, trait editing, progress item editing, and assignment status editing stay out of this slice.
- The app is still in MVP demo mode with no real instructor login.
- Writes should be limited to the seeded demo instructor id: `11111111-1111-4111-8111-111111111111`.
- Do not use service-role keys in the app. Use Supabase public key plus narrow RLS policies.
- The temporary demo write policies must be documented as removable when real auth is added.

## Current State

- Dashboard roster and student detail read views are complete.
- Supabase is linked and remote migrations are applied.
- `0002_demo_read_policy.sql` allows anonymous read access only to seeded demo instructor rows.
- Student detail already renders `Summary`, `Progress`, and `Notes` tabs.
- `getStudentDetail` reads `lesson_notes` and `next_lesson_plans`, but next plan rows currently do not expose an `id` in the UI read model.

## Approach

Use Next.js server actions for writes and keep forms inside the student detail workflow.

This keeps mutation logic server-side, lets the UI stay simple, and avoids opening broad client-side write access. Since RLS still applies to public-key requests, Phase 3A needs a second temporary migration that allows anonymous writes only for the seeded demo instructor and only for the two tables in scope: `lesson_notes` and `next_lesson_plans`.

## Out Of Scope

- Real instructor authentication.
- Student creation or profile editing.
- Trait editing.
- Progress item creation or updates.
- Assignment creation or assignment status updates.
- Delete flows for notes or next plans.
- Rich text, media attachments, drum notation, or file uploads.

## Data Contract

### Lesson Note Create

Table: `public.lesson_notes`

Fields:
- `student_id`: current route student id
- `instructor_id`: fixed demo instructor id
- `lesson_date`: required date
- `covered_material`: required text
- `observations`: required text
- `practice_assigned`: required text
- `next_step_hint`: required text

Behavior:
- Insert one new row.
- After save, revalidate `/students/{studentId}`.
- The new note should appear in the `Notes` tab if it is among the latest three by `lesson_date`.

### Next Lesson Plan Edit

Table: `public.next_lesson_plans`

Fields:
- `id`: selected next plan row id, if one exists
- `student_id`: current route student id
- `instructor_id`: fixed demo instructor id
- `planned_for`: optional date
- `priority`: `low`, `normal`, or `high`
- `next_action`: required text
- `detail`: required text

Behavior:
- If a selected plan exists, update that row.
- If no selected plan exists, insert a new row for the student.
- After save, revalidate `/students/{studentId}`.
- The summary header and `Next lesson` panel should reflect the saved action.

## Files To Create Or Modify

### Create

- `supabase/migrations/0003_demo_lesson_note_next_plan_write_policy.sql`
  - Adds temporary anon insert policy for `lesson_notes`.
  - Adds temporary anon insert/update policy for `next_lesson_plans`.
  - Constrains writes to the seeded demo instructor id.

- `src/lib/students/editing-schemas.ts`
  - Defines Zod schemas for lesson note and next plan form data.
  - Exports typed validation helpers used by server actions and tests.

- `src/lib/students/editing-schemas.test.mts`
  - Tests accepted and rejected payloads for both forms.

- `src/app/students/[studentId]/actions.ts`
  - Defines `createLessonNoteAction`.
  - Defines `saveNextLessonPlanAction`.
  - Validates form data, writes through Supabase, and calls `revalidatePath`.

- `src/components/students/form-submit-button.tsx`
  - Small client component using `useFormStatus`.
  - Shows pending copy without moving mutation logic client-side.

- `src/components/students/lesson-note-form.tsx`
  - Renders the add-note form.
  - Posts to `createLessonNoteAction`.

- `src/components/students/next-plan-form.tsx`
  - Renders the next-plan edit form.
  - Posts to `saveNextLessonPlanAction`.

### Modify

- `src/lib/supabase/read-models.ts`
  - Add `id` to `NextPlanContextRow`.
  - Add `id` to `StudentNextPlan`.

- `src/lib/supabase/queries.ts`
  - Select `id` from `next_lesson_plans`.

- `src/components/students/student-notes-list.tsx`
  - Add `LessonNoteForm` above the existing note list.
  - Keep the compact notes list unchanged.

- `src/components/students/student-summary-panel.tsx`
  - Add `NextPlanForm` inside the existing `Next lesson` panel.
  - Keep read-only summary text visible even when the form is present.

- `package.json`
  - Add `src/lib/students/editing-schemas.test.mts` to the test command.

- `README.md`
  - Document that Phase 3A temporarily allows demo writes for lesson notes and next lesson plans.

## Tasks

### Task 03A-01: Add Validated Mutation Inputs

**Purpose:** Make the write contract explicit before wiring forms or database writes.

Steps:
1. Create `src/lib/students/editing-schemas.ts`.
2. Add `lessonNoteInputSchema` with required fields:
   - `studentId`
   - `lessonDate`
   - `coveredMaterial`
   - `observations`
   - `practiceAssigned`
   - `nextStepHint`
3. Add `nextPlanInputSchema` with required fields:
   - `studentId`
   - `priority`
   - `nextAction`
   - `detail`
   - optional `planId`
   - optional `plannedFor`
4. Reject empty strings after trimming.
5. Keep text limits conservative, for example 1 to 2000 characters for long fields and 1 to 240 for action/title style fields.
6. Create `src/lib/students/editing-schemas.test.mts` with tests for valid payloads, blank required fields, invalid priority, and invalid date.

Verification:
- `npm test`
- `npm run build`

### Task 03A-02: Add Narrow Demo Write RLS Policies

**Purpose:** Allow the current demo app to write only the scoped tables and only for the seeded instructor.

Steps:
1. Create `supabase/migrations/0003_demo_lesson_note_next_plan_write_policy.sql`.
2. Add anon insert policy on `lesson_notes` with `with check (instructor_id = demo id)`.
3. Add anon insert policy on `next_lesson_plans` with `with check (instructor_id = demo id)`.
4. Add anon update policy on `next_lesson_plans` with both `using` and `with check` constrained to the demo id.
5. Do not add update/delete policy for `lesson_notes`.
6. Do not add write policies for students, traits, progress items, or assignments.

Verification:
- `supabase db push --linked --dry-run`
- `supabase db push --linked`
- Public-key smoke script can insert a test lesson note for a seeded student and update a next plan, then the UI can read it back.

Rollback note:
- Remove this migration's policies when real auth is introduced.

### Task 03A-03: Add Server Actions

**Purpose:** Keep mutation behavior server-side and reusable by forms.

Steps:
1. Create `src/app/students/[studentId]/actions.ts`.
2. Add a local constant for the demo instructor id.
3. Add `createLessonNoteAction(formData: FormData)`.
4. Parse form data with `lessonNoteInputSchema`.
5. Insert into `lesson_notes` with the demo instructor id and validated fields.
6. Add `saveNextLessonPlanAction(formData: FormData)`.
7. Parse form data with `nextPlanInputSchema`.
8. If `planId` exists, update the matching `next_lesson_plans` row.
9. If `planId` is missing, insert a new `next_lesson_plans` row.
10. Return a small action state or throw a readable error that the route can surface later.
11. Call `revalidatePath(`/students/${studentId}`)` after successful writes.

Verification:
- `npm run build`
- `rg "service_role|SERVICE_ROLE" src .env.example`
- `rg "insert\\(|update\\(" src/app/students src/lib/students`

### Task 03A-04: Add Lesson Note Form

**Purpose:** Let the instructor add the most common post-lesson record from the existing `Notes` tab.

Steps:
1. Create `src/components/students/form-submit-button.tsx`.
2. Create `src/components/students/lesson-note-form.tsx`.
3. Render fields:
   - Lesson date
   - Covered
   - Observations
   - Practice
   - Next hint
4. Include hidden `studentId`.
5. Default lesson date to today's date in `YYYY-MM-DD`.
6. Keep copy practical and compact.
7. Add the form above the notes list in `StudentNotesList`.
8. Keep `No lesson notes yet` empty state for students without notes.

Verification:
- `npm run build`
- Browser: open `/students/{id}`, go to `Notes`, submit a note, confirm it appears newest-first.

### Task 03A-05: Add Next Lesson Plan Form

**Purpose:** Let the instructor update the next action without leaving the summary screen.

Steps:
1. Update `next_lesson_plans` read selection to include `id`.
2. Update read model types and tests so `student.nextPlan?.id` exists.
3. Create `src/components/students/next-plan-form.tsx`.
4. Render fields:
   - Planned for
   - Priority
   - Next action
   - Detail
5. Include hidden `studentId`.
6. Include hidden `planId` when a selected next plan exists.
7. Add the form inside the `Next lesson` panel in `StudentSummaryPanel`.
8. Keep current read-only `nextAction` and detail visible.

Verification:
- `npm test`
- `npm run build`
- Browser: edit next action, save, confirm header and summary panel update.

### Task 03A-06: Final Verification And Documentation

**Purpose:** Prove Phase 3A works without over-claiming broader Phase 3 completion.

Steps:
1. Run `npm test`.
2. Run `npm run build`.
3. Run `npm run lint`.
4. Run `rg "service_role|SERVICE_ROLE" src .env.example`.
5. Run `supabase db push --linked --dry-run` and confirm remote DB is up to date.
6. Browser UAT:
   - Open dashboard.
   - Open one student.
   - Add a lesson note.
   - Confirm it appears in `Notes`.
   - Edit next lesson plan.
   - Confirm header and summary panel reflect the saved action.
7. Update `README.md` with:
   - Phase 3A smoke check.
   - Reminder that demo write policies are temporary.
8. Add `.planning/phases/03a-lesson-note-and-next-plan-editing/03A-SUMMARY.md` after implementation.

## Success Criteria

- Instructor can add a dated lesson note for a student.
- Lesson note records covered material, observations, practice assigned, and next-step hint.
- Instructor can update or create the next lesson plan for a student.
- Student detail refreshes after save and shows the new note/next plan.
- Writes are limited to `lesson_notes` and `next_lesson_plans`.
- Writes are limited to the seeded demo instructor id.
- No service-role key is introduced.
- Student/profile/trait/progress/assignment editing remains out of scope.

## Risks

| Risk | Mitigation |
|------|------------|
| Temporary demo write policy allows public writes to demo rows | Limit policy to two tables and seeded instructor id; document removal before auth. |
| Next plan update touches the wrong row if multiple plans exist | Add plan id to read model and update by `id` plus demo instructor id. |
| Form errors are too rough | Keep error handling simple for Phase 3A, but return readable messages and preserve build safety. |
| Scope expands into all Phase 3 editing | Treat profile, trait, progress, and assignment editing as separate later phases. |

## Completion Boundary

Phase 3A is complete when lesson note creation and next lesson plan editing work end-to-end on the current student detail page. It does not complete Phase 3 overall.
