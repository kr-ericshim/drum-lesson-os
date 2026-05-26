---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: instructor-side MVP
status: complete
stopped_at: Phase 4B complete after 0009 apply and tempo note Browser smoke
last_updated: "2026-05-26T00:00:00+09:00"
last_activity: 2026-05-26 -- Linked Supabase 0009 applied and Browser plugin verified tempo note persistence in Progress row and Lesson Brief
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 14
  completed_plans: 14
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-22)

**Core value:** An instructor can quickly understand a student's current progress and personal characteristics before or during a lesson.
**Current focus:** Instructor-side MVP phases complete; next meaningful work is release-gate hardening such as real instructor auth and production RLS cleanup.

## Current Position

Phase: 4 (Instructor Workbench Polish) — COMPLETE
Plan: 2 of 2 complete in Phase 4
Status: Phase 1 through Phase 4 complete with tests, Browser plugin verification, and agent verification.
Last activity: 2026-05-26 -- Browser plugin verified tempo note persistence after `0009`, including Progress row and Lesson Brief current-focus display.

Progress: ██████████ 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 14
- Average duration: N/A
- Total execution time: N/A

**By Phase:**

| Phase | Plans | Complete | Status |
|-------|-------|----------|--------|
| 01 | 3 | 3 | Complete |
| 02 | 3 | 3 | Complete |
| 03 | 6 | 6 | Complete |
| 04 | 2 | 2 | Complete |

**Recent Trend:**

- Last 5 plans: 03D, 03E, 03F, 04A, 04B
- Next 5 plans: release-gate hardening if real deployment is requested

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
- 2026-05-26 replanning: Do not plan student portal, payments, attendance, calendar automation, AI summaries, or audio/video analysis as near-term phases.
- 2026-05-26 replanning: Finish the remaining MVP through 03D profile/trait editing, 03E assignment review editing, 03F closeout, 04A workbench filters/progress status polish, and 04B tempo/quick-add refinements.
- 2026-05-26 replanning: Treat real instructor auth and production RLS cleanup as a release gate before real deployment, not as one of the requested product feature phases.

### Pending Todos

- `gh auth status` reports the `kr-ericshim` token is invalid. GitHub public repo creation/push is pending `gh auth login -h github.com`.

### Blockers/Concerns

None for the requested phase execution work.

## Deferred Or Excluded Items

| Category | Item | Status | Decision Date |
|----------|------|--------|---------------|
| Student-facing | Student portal or student login | Not planned | 2026-05-26 |
| Studio operations | Payments, invoices, attendance, calendar automation | Not planned | 2026-05-26 |
| AI/media | AI summaries, audio/video upload, audio/video analysis | Not planned | 2026-05-26 |
| Curriculum | Full syllabus builder | Excluded from v1 | 2026-05-26 |
| Release gate | Real instructor auth and production RLS cleanup | Required before real deployment | 2026-05-26 |

## Session Continuity

Last session: 2026-05-26T00:00:00+09:00
Stopped at: Phase 4B complete
Resume file: .planning/phases/04b-tempo-and-quick-add-refinements/04B-CHECKPOINT.md
