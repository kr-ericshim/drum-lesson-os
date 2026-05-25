# Phase 3A Summary

Date: 2026-05-25
Status: Complete

## Scope

Phase 3A adds the first focused editing slice to the existing student detail page:

- Create dated lesson notes from the `Notes` tab.
- Edit or create the selected next lesson plan from the `Summary` tab.
- Keep profile, trait, progress item, assignment, delete flows, media, and real auth out of scope.

## Implemented

- Added `lessonNoteInputSchema` and `nextPlanInputSchema` with trimmed required text, UUID validation, date validation, optional form-field normalization, and priority validation.
- Added schema tests and included them in `npm test`.
- Added `next_lesson_plans.id` to Supabase selects, read-model types, mapping, and tests so the form updates a specific row.
- Added server actions for:
  - `createLessonNoteAction`
  - `saveNextLessonPlanAction`
- Server actions validate form data, verify the student belongs to the demo instructor, write only the Phase 3A tables, and revalidate `/students/{studentId}` after success.
- Added a cookie-free server-side public-key Supabase client for demo writes so the temporary `anon` RLS policy path is consistent.
- Added `LessonNoteForm` above the notes list.
- Added `NextPlanForm` inside the existing next lesson panel.
- Added temporary migration `0003_demo_lesson_note_next_plan_write_policy.sql`.
- Hardened the migration with:
  - DB text presence/length check constraints for Phase 3A fields.
  - Column-limited anon insert/update grants.
  - Demo instructor and demo-student RLS checks.
- Documented the temporary public-demo write risk in `README.md`.

## Verification Completed

- `npm test`
- `npm run build`
- `npm run lint`
- `rg "service_role|SERVICE_ROLE" src .env.example`
- `supabase db push --linked`
- `supabase db push --linked --dry-run`
- Browser DOM check for:
  - Next lesson form on `Summary`
  - Add lesson note form on `Notes`
- Browser write UAT:
  - Added a lesson note with covered material, observations, practice assigned, and next hint.
  - Confirmed the new lesson note appeared in the latest notes list.
  - Saved a next lesson plan update.
  - Confirmed the refreshed header and summary panel reflected the saved next action and detail.

## Completed Gates

- Applied `0003_demo_lesson_note_next_plan_write_policy.sql` to the linked remote Supabase project after explicit approval for temporary anonymous demo writes.
- Confirmed the remote database is up to date with `supabase db push --linked --dry-run`.
- Completed browser write UAT on `/students/22222222-2222-4222-8222-222222222222`.

## Accepted Demo Risk

The Phase 3A demo write policy is not production authentication. Anyone with the public Supabase key can call Supabase REST directly and mutate the scoped demo rows until real instructor authentication replaces these temporary policies.
