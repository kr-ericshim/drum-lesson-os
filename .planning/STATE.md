---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: instructor-side MVP
status: native-primary-reorganized
stopped_at: Phase 7 SwiftUI Native Migration was approved; the macOS app now lives at repo root, the legacy web runtime has been removed, and native-first verification passed.
last_updated: "2026-05-28T17:17:00+09:00"
last_activity: 2026-05-28 -- Phase 7 native implementation candidate passed independent review, then the project was reorganized around the root SwiftUI app. Legacy web runtime and old web env aliases were removed. SQL guard, XcodeGen, root xcodebuild tests, Supabase dry-run, and diff check passed.
progress:
  total_phases: 7
  completed_phases: 7
  total_plans: 18
  completed_plans: 18
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-28)

**Core value:** An instructor can quickly understand a student's current progress and personal characteristics before or during a lesson.
**Current focus:** Drum Lesson OS is now a macOS SwiftUI app at the repo root. Supabase authenticated RPC writes, EventKit calendar write-through, retry visibility, and native parity tests remain the active implementation surface. The legacy Next.js runtime has been removed after Phase 7 approval.

## Current Position

Phase: 7 (SwiftUI Native Migration) — APPROVED AND REORGANIZED AS NATIVE PRIMARY
Plan: 1 of 1 implemented and verified for Phase 7 code-level gates
Status: Phase 1 through Phase 7 implementation candidate complete; root project shape is now native-first and verified. Live Supabase/EventKit/iPhone UAT remains before real daily production use.
Last activity: 2026-05-28 -- Phase 7 verified with XcodeGen, native xcodebuild tests, Supabase dry-run, source/binary secret scans, Computer Use preview smoke, independent agent approval, native-primary repository cleanup, and post-cleanup root verification.

Progress: ██████████ 100%

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
| 06 | 1 | 1 | Phase 6A complete; Phase 6B deferred |
| 07 | 1 | 1 | Implementation candidate verified; release cutover pending live UAT |

**Recent Trend:**

- Last 5 plans: 04B, 04C, 05, 06, 07
- Next 5 plans: live Phase 7 UAT, native packaging/signing, and daily-use hardening if issues appear

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
- Phase 7: The native macOS app is a SwiftUI implementation candidate at repo root; Supabase remains canonical.
- Phase 7: Native write paths use authenticated Supabase RPCs and reject service-role keys in app configuration.
- Phase 7: Native Apple Calendar writes use EventKit and additive native sync metadata.
- Phase 7: The legacy Next.js runtime was removed after independent implementation approval to keep future work native-centered.
- Demo maintenance: Keep seeded demo content Korean and expose short student slugs in routes while preserving UUID primary keys for writes and relations.

### Pending Todos

No Phase 7 code-level todos remain from this implementation pass. Live use still needs real Supabase credentials, EventKit permission/write/delete proof, iPhone iCloud propagation proof, and daily-use confidence.

### Blockers/Concerns

Native production confidence is blocked on external live UAT inputs: instructor credentials, real macOS Calendar permission/write/delete, and an iPhone on the same iCloud account. Phase 6B reverse sync remains intentionally deferred.

## Deferred Or Excluded Items

| Category | Item | Status | Decision Date |
|----------|------|--------|---------------|
| Student-facing | Student portal or student login | Not planned | 2026-05-26 |
| Studio operations | Payments, invoices, attendance, reminders, external booking, non-Apple calendar providers | Not planned | 2026-05-26 / updated 2026-05-28 |
| AI/media | AI summaries, audio/video upload, audio/video analysis | Not planned | 2026-05-26 |
| Curriculum | Full syllabus builder | Excluded from v1 | 2026-05-26 |
| Release gate | Real instructor auth, production RLS cleanup, public signup lock, signed-out route protection, inbox recovery link, and closeout transaction RPC | Complete: linked DB migrations, instructor auth binding, public signup lock, signed-out route redirects, real inbox recovery link, closeout RPC, and authenticated browser smoke verified | 2026-05-27 |

## Session Continuity

Last session: 2026-05-28T17:17:00+09:00
Stopped at: Native-primary repo reorganization completed and verified after Phase 7 approval
Resume file: .planning/phases/07-swiftui-native-migration/07-NATIVE-PRIMARY-REORG.md
