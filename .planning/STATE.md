---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: instructor-side MVP
status: release-gate-complete
stopped_at: Instructor-side MVP release gate complete; linked Supabase auth/RLS, public signup lock, closeout RPC, signed-out route protection, inbox recovery link, and authenticated closeout smoke verified
last_updated: "2026-05-27T02:57:34+09:00"
last_activity: 2026-05-27 -- Password recovery UI, real inbox recovery link, login rate limiting, security headers, public signup lock, signed-out route protection, transactional closeout RPC, and authenticated dashboard/detail closeout smoke were verified; linked Supabase dry-run reports migrations up to date, the instructor row has a bound Auth user, and demo anon policies/grants are removed.
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 15
  completed_plans: 15
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-22)

**Core value:** An instructor can quickly understand a student's current progress and personal characteristics before or during a lesson.
**Current focus:** Instructor-side MVP phases and release gate are complete. Real instructor auth, production RLS cleanup, public signup lock, signed-out route protection, the closeout transaction RPC, real inbox recovery link, and the authenticated browser smoke path are implemented and verified against the linked Supabase project/local app.

## Current Position

Phase: 4 (Instructor Workbench Polish) — COMPLETE
Plan: 3 of 3 complete in Phase 4
Status: Phase 1 through Phase 4 complete with tests and Browser plugin verification.
Last activity: 2026-05-27 -- Auth/password recovery release-gate slice verified locally; real inbox recovery link checked; linked Supabase real-auth/RLS, public signup lock, and closeout RPC state checked/applied; signed-out protected routes redirect to login; logged-in dashboard/detail closeout smoke persists after refresh.

Progress: ██████████ 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 15
- Average duration: N/A
- Total execution time: N/A

**By Phase:**

| Phase | Plans | Complete | Status |
|-------|-------|----------|--------|
| 01 | 3 | 3 | Complete |
| 02 | 3 | 3 | Complete |
| 03 | 6 | 6 | Complete |
| 04 | 3 | 3 | Complete |

**Recent Trend:**

- Last 5 plans: 03E, 03F, 04A, 04B, 04C
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
- Phase 4C: Keep the next slice to UX tightening only; make Lesson Brief action-first, make Closeout less strict, allow focus-only closeout updates, and choose the current next plan by latest update instead of priority.
- Demo maintenance: Keep seeded demo content Korean and expose short student slugs in routes while preserving UUID primary keys for writes and relations.

### Pending Todos

None.

### Blockers/Concerns

None for the requested phase execution work.

## Deferred Or Excluded Items

| Category | Item | Status | Decision Date |
|----------|------|--------|---------------|
| Student-facing | Student portal or student login | Not planned | 2026-05-26 |
| Studio operations | Payments, invoices, attendance, calendar automation | Not planned | 2026-05-26 |
| AI/media | AI summaries, audio/video upload, audio/video analysis | Not planned | 2026-05-26 |
| Curriculum | Full syllabus builder | Excluded from v1 | 2026-05-26 |
| Release gate | Real instructor auth, production RLS cleanup, public signup lock, signed-out route protection, inbox recovery link, and closeout transaction RPC | Complete: linked DB migrations, instructor auth binding, public signup lock, signed-out route redirects, real inbox recovery link, closeout RPC, and authenticated browser smoke verified | 2026-05-27 |

## Session Continuity

Last session: 2026-05-27T02:18:00+09:00
Stopped at: Password recovery/auth security slice locally verified; linked Supabase auth/RLS, public signup lock, signed-out route protection, closeout RPC, real inbox recovery link, and authenticated browser closeout smoke applied/verified
Resume file: .planning/phases/04c-brief-closeout-tightening/04C-CHECKPOINT.md
