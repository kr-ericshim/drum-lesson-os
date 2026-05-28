---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: instructor-side MVP
status: phase-6-planned
stopped_at: Phase 6 Calendar-First Scheduling And Apple Calendar Sync is planned; implementation has not started.
last_updated: "2026-05-28T13:44:37+09:00"
last_activity: 2026-05-28 -- Phase 6 was planned as app-owned lesson scheduling with a calendar-first dashboard, app-expanded recurring occurrences, and outbox-based Apple Calendar sync through iCloud CalDAV.
progress:
  total_phases: 6
  completed_phases: 5
  total_plans: 17
  completed_plans: 16
  percent: 94
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-28)

**Core value:** An instructor can quickly understand a student's current progress and personal characteristics before or during a lesson.
**Current focus:** Phase 6 is planned but not implemented. The next planned work is calendar-first scheduling with Drum Lesson OS as the source of truth and Apple Calendar as the sync target.

## Current Position

Phase: 6 (Calendar-First Scheduling And Apple Calendar Sync) — PLANNED
Plan: 0 of 1 implemented in Phase 6
Status: Phase 1 through Phase 5 complete; Phase 6 plan is documented and awaiting review before implementation.
Last activity: 2026-05-28 -- Phase 6 plan created for calendar-first scheduling and Apple Calendar outbox sync.

Progress: █████████░ 94%

## Performance Metrics

**Velocity:**

- Total plans completed: 16
- Average duration: N/A
- Total execution time: N/A

**By Phase:**

| Phase | Plans | Complete | Status |
|-------|-------|----------|--------|
| 01 | 3 | 3 | Complete |
| 02 | 3 | 3 | Complete |
| 03 | 6 | 6 | Complete |
| 04 | 3 | 3 | Complete |
| 05 | 1 | 1 | Complete |
| 06 | 1 | 0 | Planned |

**Recent Trend:**

- Last 5 plans: 03F, 04A, 04B, 04C, 05
- Next 5 plans: 06

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Initialization: Build instructor-side MVP first.
- Initialization: Center v1 on progress tracking and student traits.
- Initialization: Defer student portal, scheduling automation, payments, and audio/video analysis.
- Phase 2: Keep roster rows compact and read-only, with one clear `Open student` route to `/students/{id}`.
- Phase 2: Use a tabbed student detail read view with `Summary`, `Progress`, and `Notes`.
- Phase 2: Show the latest 3 lesson notes newest-first by `lesson_date`.
- Phase 3A: Start Phase 3 with lesson note creation and next lesson plan editing before broader profile, trait, progress, or assignment editing.
- Phase 3A: Use narrow temporary demo write policies for `lesson_notes` and `next_lesson_plans`; do not introduce service-role keys.
- Phase 3A: Accept temporary public-key demo write risk for scoped demo rows until real instructor authentication replaces the demo policies.
- Phase 3B: Use narrow temporary demo write policies for `progress_items`; do not introduce service-role keys.
- Phase 3C: Treat `progress_items.current_focus` as the only current-focus source of truth and remove the old student-level focus column.
- Phase 3C: With the unique focus index, progress item saves clear competing focused rows before promoting the requested target.
- Phase 3C: Add a dashboard Today/Upcoming queue and a student Lesson Brief before continuing the remaining Phase 3 editing flows.
- 2026-05-26 replanning: Do not plan student portal, payments, attendance, calendar automation, AI summaries, or audio/video analysis as near-term phases. Superseded in part on 2026-05-28 for app-owned calendar scheduling and Apple Calendar sync only.
- 2026-05-26 replanning: Finish the remaining MVP through 03D profile/trait editing, 03E assignment review editing, 03F closeout, 04A workbench filters/progress status polish, and 04B tempo/quick-add refinements.
- 2026-05-26 replanning: Treat real instructor auth and production RLS cleanup as a release gate before real deployment, not as one of the requested product feature phases.
- Phase 4C: Keep the next slice to UX tightening only; make Lesson Brief action-first, make Closeout less strict, allow focus-only closeout updates, and choose the current next plan by latest update instead of priority.
- Phase 5: Keep in-lesson run notes session-local and avoid new tables; the existing closeout save remains the durable write path.
- Phase 5: Initialize closeout `nextStepHint` and `nextAction` from the same run-panel next hint so dashboard and Lesson Brief do not split after save.
- Phase 6: Drum Lesson OS owns lesson schedules; Apple Calendar is the sync target.
- Phase 6: Recurring lessons expand into app-owned individual occurrences before Apple sync.
- Phase 6: Use an outbox for Apple Calendar create/update/delete so app schedule saves are durable even when CalDAV sync fails.
- Phase 6: Optional reverse sync should only inspect app-created Apple events and should keep Drum Lesson OS canonical on conflicts.
- Demo maintenance: Keep seeded demo content Korean and expose short student slugs in routes while preserving UUID primary keys for writes and relations.

### Pending Todos

Phase 6 implementation not started.

### Blockers/Concerns

None.

## Deferred Or Excluded Items

| Category | Item | Status | Decision Date |
|----------|------|--------|---------------|
| Student-facing | Student portal or student login | Not planned | 2026-05-26 |
| Studio operations | Payments, invoices, attendance, reminders, external booking, non-Apple calendar providers | Not planned | 2026-05-26 / updated 2026-05-28 |
| AI/media | AI summaries, audio/video upload, audio/video analysis | Not planned | 2026-05-26 |
| Curriculum | Full syllabus builder | Excluded from v1 | 2026-05-26 |
| Release gate | Real instructor auth, production RLS cleanup, public signup lock, signed-out route protection, inbox recovery link, and closeout transaction RPC | Complete: linked DB migrations, instructor auth binding, public signup lock, signed-out route redirects, real inbox recovery link, closeout RPC, and authenticated browser smoke verified | 2026-05-27 |

## Session Continuity

Last session: 2026-05-28T13:44:37+09:00
Stopped at: Phase 6 plan documented; implementation not started
Resume file: .planning/phases/06-calendar-apple-sync/06-PLAN.md
