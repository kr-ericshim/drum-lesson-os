# Phase 3E Implementation Checkpoint

Date: 2026-05-26
Status: Complete

## Scope Implemented

Phase 3E adds assignment/homework review editing to the instructor-side MVP.

Implemented:

- `assignmentInputSchema` with assignment status, optional due date, and text validation.
- Assignment validation tests, including omitted due date and independent invalid-field cases.
- `0007_demo_assignment_write_policy.sql` with scoped temporary demo anon write policies for `assignments`.
- Assignment `id` selected in roster/detail queries and preserved in read models.
- `saveAssignmentAction` for assignment insert/update under the demo instructor.
- `AssignmentForm` in the Summary Assignment panel.
- Readable assignment badge/title/detail remains visible before the collapsed edit form.
- README smoke check and demo policy note.

Out of scope remains unchanged:

- Student portal.
- Practice submission.
- Assignment history timeline.
- Reminders, messages, due-date notifications, or calendar automation.
- Delete flows.

## Verification Completed

- `npm test` passed with 26 tests.
- `npm run build` passed.
- `npm run lint` passed.
- `rg "SERVICE_ROLE|service_role" src .env.example` returned no matches.
- `git diff --check` passed.
- `supabase db push --linked --dry-run` reports `0006_demo_student_trait_write_policy.sql` and `0007_demo_assignment_write_policy.sql` would be applied.
- `supabase db push --linked` applied `0007` after explicit approval.
- Render smoke checks against local `http://localhost:3000` confirmed:
  - student detail Summary renders collapsed `Edit assignment`
  - assignment form labels render
  - assignment read text uses long-text wrapping hardening
- Browser plugin live submit smoke confirmed:
  - an assignment was added for `Smoke Student 1779729007355`.
  - assignment status, due date, title, and detail persisted.
  - Lesson Brief assignment review cue updated from the saved assignment.

## Agent Verification

- Spec/correctness agent found two P2 schema/test issues.
- Design agent found four UI polish issues.
- Fixes applied and re-reviewed:
  - omitted `dueDate` now parses as `null`
  - invalid assignment field tests are independent
  - assignment form uses `Add assignment` for create and `Edit assignment` for update
  - existing assignment saves use secondary button tone
  - duplicated weak-point readout was removed from the profile card
  - user-authored read text uses `break-words`

## Demo Risk

The accepted demo risk now extends to assignment rows. This is still temporary public-key RLS for the seeded demo instructor and must be replaced before real instructor auth and real student data.
