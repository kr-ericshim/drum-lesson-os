# Phase 3C Implementation Checkpoint

Date: 2026-05-25
Status: Complete

## Scope

Phase 3C makes the pre-lesson routine trustworthy and scannable before the remaining Phase 3 editing flows.

Included:

- Use `progress_items.current_focus` as the only current-focus source.
- Remove the student-level focus column from schema, seed data, generated types, queries, and UI.
- Add a dashboard Today/Upcoming lesson queue.
- Add a student Lesson Brief above the detail tabs.
- Keep dashboard, detail header, Lesson Brief, Summary, and Progress focused item in agreement.

Out of scope:

- Post-lesson closeout.
- Student profile editing.
- Trait editing.
- Assignment editing.
- Real instructor authentication.
- Scheduling automation or calendar integration.

## Implemented

- Added `0005_progress_focus_source_of_truth.sql` to normalize duplicate focused progress rows, enforce one focused progress item per student, and drop the old student-level focus column.
- Updated the baseline schema, seed data, and database types to remove the student-level focus column.
- Updated read models and queries so roster/detail current focus is derived from focused progress items.
- Added read-model tests for focused item mapping, no-focus fallback, duplicate focus resolution including same-date ties, queue sorting, and Lesson Brief field derivation.
- Added dashboard `LessonQueue` and student `LessonBrief` components.
- Updated the Summary panel so it does not elevate recent progress when no current focus is set.
- Updated progress item save ordering so the unique focus index does not reject changing focus to a different progress item.
- Updated README, roadmap, requirements, and state docs for Phase 3C.

## Verification Completed

- `npm test` passed with 17 tests.
- `npm run build` passed.
- `npm run lint` passed.
- `rg "SERVICE_ROLE|service_role" src .env.example` returned no matches.
- The old student-level focus column search over `src`, `supabase`, and `README.md` returned no matches.
- `supabase db push --linked --dry-run` first reported only `0005_progress_focus_source_of_truth.sql` would be pushed.
- `supabase db push --linked` applied `0005_progress_focus_source_of_truth.sql` to the linked remote Supabase project after explicit approval.
- A second `supabase db push --linked --dry-run` reported the remote database is up to date.
- Browser checks against `http://localhost:3000` confirmed:
  - dashboard queue renders on desktop
  - dashboard queue renders at 320px width with no horizontal overflow
  - student detail renders Lesson Brief
  - detail header, Lesson Brief, Progress tab, dashboard queue, and roster agree on the focused progress item
  - changing Daniel Kim's current focus from the Progress tab updates detail and dashboard
  - no-focused-progress fallback appears in header, Lesson Brief, Summary, dashboard queue, and roster, then focus was restored
- Multi-agent verification covered data/schema/Supabase, read-model/tests, UI/UX behavior, and docs/planning consistency. Confirmed issues were fixed before closeout.

## Demo Risk

The accepted demo risk remains unchanged: temporary public-key RLS policies allow scoped demo-row writes until real instructor authentication replaces them.
