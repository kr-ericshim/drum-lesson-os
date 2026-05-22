---
phase: 01-app-foundation-and-data-model
plan: 01-02
subsystem: database
tags: [supabase, postgres, rls, seed-data]
requires:
  - phase: 01-01
    provides: app scaffold and Supabase client utilities
provides:
  - Instructor-owned Supabase/Postgres schema
  - RLS policies for all Phase 1 domain tables
  - Realistic drum lesson seed data
  - Dashboard preview query helper
affects: [phase-1, phase-2, phase-3, database, dashboard]
tech-stack:
  added: [supabase-cli-setup-docs]
  patterns: [sql-migrations-own-rls, instructor-scoped-query-helper]
key-files:
  created:
    - supabase/config.toml
    - supabase/migrations/0001_foundation.sql
    - supabase/seed.sql
    - src/types/database.ts
    - src/lib/demo-instructor.ts
    - src/lib/supabase/queries.ts
  modified:
    - README.md
    - src/lib/supabase/client.ts
    - src/lib/supabase/server.ts
key-decisions:
  - "Duplicate instructor_id on child records for straightforward RLS and dashboard reads."
  - "Keep seed data tied to a documented demo instructor id instead of storing real student data."
patterns-established:
  - "Every student-domain table has authenticated RLS policies using auth.uid()."
  - "Dashboard preview data is mapped through a roster-ready query helper."
requirements-completed: [FND-02, FND-03]
duration: 30 min
completed: 2026-05-22
---

# Phase 1 Plan 01-02: Hosted Schema, RLS, And Seed Data Summary

**Supabase/Postgres lesson domain schema with instructor ownership, RLS policies, seed data, and roster query helper**

## Performance

- **Duration:** 30 min
- **Started:** 2026-05-22T03:08:00Z
- **Completed:** 2026-05-22T03:38:00Z
- **Tasks:** 5
- **Files modified:** 9

## Accomplishments

- Added tables for instructors, students, progress items, student traits, lesson notes, assignments, and next lesson plans.
- Enabled RLS on every Phase 1 domain table with `to authenticated` policies using `auth.uid()`.
- Added 6 realistic drum student cases covering beginner, hobby adult, audition prep, weak fills, inconsistent practice, and demonstration-friendly learning.
- Added typed database surfaces and `getStudentDashboardPreview`.

## Task Commits

1. **Tasks 01-02-T1 through 01-02-T5: Schema, RLS, seed data, query helper, and setup docs** - `7ca5cbc`

## Files Created/Modified

- `supabase/migrations/0001_foundation.sql` - Tables, indexes, and RLS policies.
- `supabase/seed.sql` - Demo instructor and 6 realistic student records with related lesson data.
- `src/types/database.ts` - Minimal Supabase database types.
- `src/lib/demo-instructor.ts` - Demo instructor id constant.
- `src/lib/supabase/queries.ts` - Roster-ready dashboard preview query.
- `README.md` - Supabase migration and seed instructions.

## Decisions Made

- Used SQL migrations as the owner of RLS instead of hiding policies behind an ORM layer.
- Kept child tables with direct `instructor_id` fields and composite student relationships for simple policy checks.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- Supabase CLI is not installed on this machine, so `supabase db push` and `supabase db reset` could not be run.
- SQL content was verified with source assertions, and README documents the exact commands to run once the CLI/project credentials are available.

## User Setup Required

Supabase project setup is required before hosted data can load:

- Add `NEXT_PUBLIC_SUPABASE_URL`
- Add `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- Run `supabase db push`
- Run `supabase db execute --file supabase/seed.sql` or `supabase db reset` for local Supabase

## Next Phase Readiness

Ready for `01-03`: database files, seed data, RLS, and query helper are in place.

---
*Phase: 01-app-foundation-and-data-model*
*Completed: 2026-05-22*
