---
phase: 02-student-roster-and-detail-read-views
plan: 02-01
subsystem: roster-read-flow
tags: [nextjs, supabase, roster, read-only]
requires:
  - phase: 01-03
    provides: seed-backed dashboard preview
provides:
  - Active-student roster query
  - Clickable dashboard roster rows
  - Setup-aware roster empty and error states
affects: [phase-2, dashboard, supabase]
tech-stack:
  added: []
  patterns: [server-read-query, accessible-detail-link, read-model-mapper]
key-files:
  created:
    - src/lib/supabase/read-models.ts
    - src/lib/supabase/read-models.test.mts
  modified:
    - src/lib/supabase/queries.ts
    - src/app/page.tsx
    - src/components/dashboard/student-roster-preview.tsx
    - src/components/dashboard/student-summary-row.tsx
requirements-completed: [ROST-01]
completed: 2026-05-25
---

# Phase 2 Plan 02-01: Roster Data Loader And Clickable Student List Summary

## Accomplishments

- Added `StudentRosterItem` and `getStudentRoster`.
- Kept the active-student filter and name ordering in the Supabase roster query.
- Converted dashboard rows into read-flow entries with an `Open student` link to `/students/{id}`.
- Preserved setup, empty, and query failure states without adding edit workflows.

## Verification

- `npm test` passed.
- `npm run build` passed.
- `npm run lint` passed.

## Deviations

- Added a small tested read-model mapper so roster and detail normalization stay deterministic outside the Supabase call.

---
*Completed: 2026-05-25*
