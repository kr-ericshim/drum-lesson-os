# Phase 3D Student Profile And Trait Editing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Let the instructor add students, update student profile cues, and maintain lesson-relevant traits from the existing instructor workflow.

**Architecture:** Keep writes in server actions under `src/app/students/[studentId]/actions.ts` where the current Phase 3 editing actions already live. Add narrow demo RLS for `students` and `student_traits`, then wire compact forms into the dashboard and Summary tab.

**Tech Stack:** Next.js App Router, TypeScript, Supabase/Postgres, Zod, Tailwind CSS v4, shadcn/ui primitives.

---

## Scope

Included:

- Add a new active student with `name`, `profile_cue`, and `primary_weak_point`.
- Edit an existing student's basic profile fields.
- Add and update student traits for the existing trait types:
  - `strength`
  - `weak_point`
  - `practice_habit`
  - `learning_style`
  - `musical_preference`
  - `caution`
- Keep the Summary, Lesson Brief, dashboard roster, and queue in sync after save.

Out of scope:

- Student login or portal.
- Parent/contact/payment fields.
- Delete flows.
- Bulk import.
- Assignment editing.
- Closeout flow.

## Requirements Covered

- `ROST-03`
- `ROST-04`
- `STUD-03`

## Files To Create

- `supabase/migrations/0006_demo_student_trait_write_policy.sql`
  - Temporary anon insert/update policies for seeded-demo `students`.
  - Temporary anon insert/update policies for seeded-demo `student_traits`.
  - DB-level text checks for profile and trait fields.

- `src/app/students/new/page.tsx`
  - Minimal new-student page.

- `src/app/students/new/actions.ts`
  - `createStudentAction`.

- `src/components/students/student-profile-form.tsx`
  - Shared profile form for create/edit.

- `src/components/students/student-traits-editor.tsx`
  - Compact trait add/edit section for Summary.

## Files To Modify

- `src/lib/students/editing-schemas.ts`
  - Add `studentProfileInputSchema`.
  - Add `studentTraitInputSchema`.
  - Export `studentTraitTypes`.

- `src/lib/students/editing-schemas.test.mts`
  - Add validation tests for profile and trait inputs.

- `src/app/students/[studentId]/actions.ts`
  - Add `saveStudentProfileAction`.
  - Add `saveStudentTraitAction`.

- `src/components/dashboard/student-roster-preview.tsx`
  - Add a compact `Add student` action near the roster heading.

- `src/components/students/student-summary-panel.tsx`
  - Add profile edit and trait edit UI without hiding the existing read summary.

- `README.md`
  - Add Phase 3D smoke check and demo policy note.

## Data Contract

Student profile:

- `name`: required, 1-120 characters after trim.
- `profileCue`: required, 1-240 characters after trim.
- `primaryWeakPoint`: required, 1-240 characters after trim.
- `active`: boolean, default `true` for new students.

Student trait:

- `traitId`: optional UUID for update.
- `studentId`: required UUID.
- `type`: one of the existing `student_traits.trait_type` values.
- `label`: required, 1-120 characters after trim.
- `detail`: required, 1-1000 characters after trim.

## Tasks

### Task 03D-01: Add Validation Contracts

- [x] Add profile and trait schemas to `src/lib/students/editing-schemas.ts`.
- [x] Add tests that accept valid profile/trait payloads.
- [x] Add tests that reject blank profile fields, invalid trait type, blank label, blank detail, and invalid UUID.
- [x] Run `npm test` and confirm the new tests pass.

### Task 03D-02: Add Demo Write Policy

- [x] Create `0006_demo_student_trait_write_policy.sql`.
- [x] Allow anon insert/update only when `instructor_id = '11111111-1111-4111-8111-111111111111'`.
- [x] Limit policies to `students` and `student_traits`.
- [x] Add text length/blank check constraints that match the app schema.
- [x] Run `supabase db push --linked --dry-run`.
- [x] Apply only after explicit approval because this adds public-demo write paths.

### Task 03D-03: Add Student Create Flow

- [x] Create `/students/new`.
- [x] Add `createStudentAction` with schema validation and demo instructor ownership.
- [x] After create, redirect to `/students/{newStudentId}`.
- [x] Add `Add student` from the dashboard roster header.
- [x] Verify the new student appears in the roster after refresh.

### Task 03D-04: Add Student Profile Edit Flow

- [x] Add `saveStudentProfileAction`.
- [x] Reuse `StudentProfileForm` on the student Summary tab.
- [x] Revalidate `/` and `/students/{studentId}` after save.
- [x] Verify dashboard row, detail header, Lesson Brief, and Summary reflect edited profile fields.

### Task 03D-05: Add Trait Add/Edit Flow

- [x] Add `saveStudentTraitAction`.
- [x] Add `StudentTraitsEditor` in the Summary tab.
- [x] Support editing existing trait label/detail/type.
- [x] Support adding a new trait for the current student.
- [x] Revalidate `/students/{studentId}` after save.
- [x] Verify weak-point traits update the Weak points panel and Lesson Brief context.

## Verification

Run:

```bash
npm test
npm run build
npm run lint
rg "SERVICE_ROLE|service_role" src .env.example
```

Browser smoke:

1. Open `/` and click `Add student`.
2. Create a student and confirm redirect to the new detail page.
3. Edit profile cue and primary weak point from Summary.
4. Add one `learning_style` trait.
5. Refresh `/` and `/students/{id}` and confirm saved values persist.
6. Check 320px mobile width for form overflow.

## Completion Criteria

Phase 3D is complete when student creation, profile editing, and trait add/edit work end-to-end under the temporary demo policy, with tests/build/lint passing and docs updated.
