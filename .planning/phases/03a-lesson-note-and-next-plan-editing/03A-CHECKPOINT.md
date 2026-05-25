# Phase 3A Implementation Checkpoint

Date: 2026-05-25

## Current Status

Phase 3A is complete.

The completion gates were closed:

- Applied `supabase/migrations/0003_demo_lesson_note_next_plan_write_policy.sql` to the linked remote Supabase project after explicit approval for the anonymous demo write policy.
- Ran actual write smoke/UAT through the browser:
  - Add one lesson note from the `Notes` tab.
  - Save one next lesson plan edit from the `Summary` tab.
  - Confirm the refreshed student detail view reads the saved values back.

## Implemented Locally

- Added Zod input validation for lesson note creation and next lesson plan saving.
- Added tests for valid/invalid lesson note and next plan payloads.
- Added `id` to next lesson plan read models and Supabase select queries.
- Added server actions for lesson note insert and next plan insert/update.
- Server actions now use a cookie-free public-key Supabase client so the temporary demo `anon` RLS policies apply consistently.
- Added `LessonNoteForm` to the `Notes` tab.
- Added `NextPlanForm` to the `Next lesson` summary panel.
- Added temporary demo RLS migration `0003_demo_lesson_note_next_plan_write_policy.sql`.
- Added DB-level check constraints for Phase 3A text fields so direct Supabase calls cannot bypass app-side blank/length validation.
- Limited demo anon insert/update grants to the columns used by the Phase 3A forms.
- Documented that the demo write policies must be removed or replaced when real instructor authentication is added.

## Verification Completed

- `npm test` passed.
- `npm run build` passed.
- `npm run lint` passed.
- `rg "service_role|SERVICE_ROLE" src .env.example` returned no matches.
- `supabase db push --linked` applied `0003_demo_lesson_note_next_plan_write_policy.sql`.
- `supabase db push --linked --dry-run` confirmed the remote database is up to date.
- Browser DOM check confirmed:
  - `Summary` renders the next lesson plan form.
  - `Notes` renders the add lesson note form.
- Browser write UAT confirmed:
  - A new lesson note appeared in the latest notes list.
  - A saved next lesson plan update appeared in the header and `Next lesson` panel after refresh.

## Demo Risk

The accepted demo risk is that `0003` is public-key RLS, not server-action-only access. Anyone with the public Supabase key could directly mutate the scoped demo rows through Supabase REST until real instructor authentication replaces these policies.
