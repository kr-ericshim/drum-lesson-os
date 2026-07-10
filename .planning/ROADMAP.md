# Roadmap: Drum Lesson OS

## Overview

Drum Lesson OS v1 stays focused on the instructor-side memory loop: know the student before the lesson, update the teaching record quickly, and leave the next lesson action visible. Phase 5 connects dashboard triage, in-lesson checks, and closeout drafting so the MVP stays centered on the 30-second pre-lesson and 2-minute post-lesson routine. Phase 6 adds a calendar-first schedule surface and Apple Calendar write-through sync because the instructor already uses Apple Calendar day to day. Phase 7 moved the same MVP workflow into a macOS SwiftUI app with EventKit replacing Apple credential storage. Phase 8 redesigned the native workbench shell so the implementation-candidate UI now has clearer schedule, lesson, student-memory, and settings hierarchy without changing the core product scope.

The current repo is native-first and local-first: `project.yml`, `DrumLessonOS/`, and `DrumLessonOSTests/` are the active implementation surfaces. SQLite is canonical, the app runs without login, and EventKit writes use a durable local retry queue. Supabase/Auth references in completed phase history describe the superseded hosted implementation.

The next phases intentionally exclude student portals, payments, attendance, reminders, AI summaries, and audio/video analysis. Live deployment still requires real EventKit create/edit/delete testing and iPhone iCloud propagation verification.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3, 4): Planned milestone work
- Lettered phases (3A, 3B, 3C): Focused slices inside a milestone
- New lettered phases continue the current MVP execution order

- [x] **Phase 1: App Foundation And Data Model** - Create the runnable app foundation, persistent database, schema, and sample teaching data. (completed 2026-05-22)
- [x] **Phase 2: Student Roster And Detail Read Views** - Let the instructor browse students and read the full teaching context for one student. (completed 2026-05-25)
- [x] **Phase 3: Teaching Workflow Editing** - Finish student/profile, trait, assignment, lesson-note, next-plan, progress, and closeout editing. (completed 2026-05-26)
- [x] **Phase 4: Instructor Workbench Polish** - Add filters, faster progress status updates, small tempo checkpoints, dashboard quick-add actions, and action-first brief/closeout tightening. (completed 2026-05-26)
- [x] **Phase 5: Lesson Flow Operating Board** - Connect dashboard triage, in-lesson checks, and closeout drafting into one lesson-flow surface. (completed 2026-05-28)
- [x] **Phase 6A: Calendar-First Scheduling And Apple Calendar Sync** - Add app-owned lesson schedules, a calendar-first dashboard, recurring occurrence expansion, and outbox-based Apple Calendar sync. Optional reverse sync remains Phase 6B.
- [x] **Phase 7: SwiftUI Native Migration** - Add a macOS SwiftUI app with Supabase authenticated RPC writes, EventKit calendar write-through, retry visibility, native parity tests, and native-primary repo layout. Live use still needs real Supabase/EventKit/iPhone UAT.
- [x] **Phase 8: Native Workbench Design Overhaul** - Improve the macOS app's visual hierarchy, native shell ergonomics, dashboard first impression, student-detail lesson flow, maintenance editor density, settings clarity, and shared component vocabulary. (completed 2026-05-28)
- [x] **Phase 9: Native UI/UX Hardening** - Fix lesson-context safety, Mac sheet ergonomics, navigation continuity, compact-window priority, calendar feedback, and systemic accessibility gaps. (completed 2026-07-11)
- [x] **Phase 10: In-Lesson Workspace Redesign** - Recompose the active lesson route around one focused, responsive session workspace with on-demand student history and lower rendering cost. (completed 2026-07-11)

## Phase Details

### Phase 1: App Foundation And Data Model

**Goal**: The project has a runnable full-stack MVP foundation with hosted Supabase/Postgres persistence and realistic drum lesson sample data.
**Mode:** mvp
**UI hint**: yes
**Depends on**: Nothing
**Requirements**: [FND-01, FND-02, FND-03]
**Success Criteria**:

  1. Instructor can run the app locally and see a working first screen.
  2. Student, progress, trait, lesson note, assignment, and next plan data persist in the database.
  3. Sample data shows multiple students with different progress states and learning traits.

Plans:

- [x] 01-01: Scaffold Next.js, TypeScript, Tailwind, shadcn/ui, and base app layout.
- [x] 01-02: Add Supabase/Postgres schema, RLS policies, migrations, and seed script.
- [x] 01-03: Add seed-backed dashboard preview and foundation verification.

### Phase 2: Student Roster And Detail Read Views

**Goal**: The instructor can browse students and open a detail page that shows the teaching context needed before a lesson.
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 1
**Requirements**: [ROST-01, STUD-01, STUD-02, NOTE-03]
**Success Criteria**:

  1. Instructor can see all active students in a dashboard list.
  2. Instructor can open a student detail view from the roster.
  3. Student detail shows current progress, recent lesson notes, traits, weak points, assignment status, and next lesson plan together.
  4. Recent lesson notes appear in reverse chronological order.

Plans:

- [x] 02-01: Build roster data loader and dashboard list UI.
- [x] 02-02: Build student detail route and context sections.
- [x] 02-03: Add recent-note ordering and read-view verification.

### Phase 3: Teaching Workflow Editing

**Goal**: The instructor can maintain the teaching record before, during, and immediately after lessons.
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 2
**Requirements**: [ROST-03, ROST-04, STUD-03, PROG-01, PROG-02, PROG-03, NOTE-01, NOTE-02, NOTE-03, NEXT-01, NEXT-02, NEXT-03, NEXT-04, CLOSE-01, CLOSE-02, CLOSE-03]
**Success Criteria**:

  1. Instructor can add and edit student profile information.
  2. Instructor can edit traits, strengths, weak points, practice habits, learning style, and musical preferences.
  3. Instructor can create and update flexible progress items with status, notes, and current focus.
  4. Instructor can add dated lesson notes with covered material, observations, practice assigned, and next-step hints.
  5. Instructor can create/update assignments and mark assignment review status.
  6. Instructor can complete a compact post-lesson closeout that updates the teaching record in one pass.

Plans:

- [x] 03A: Add lesson note creation and next lesson plan editing. (completed 2026-05-25)
- [x] 03B: Add progress item create/update flows. (completed 2026-05-25)
- [x] 03C: Unify current focus on progress items and add Lesson Brief plus Today/Upcoming queue. (completed 2026-05-25)
- [x] 03D: Add student profile and trait editing flows. (completed 2026-05-26)
- [x] 03E: Add assignment/homework review editing. (completed 2026-05-26)
- [x] 03F: Add post-lesson closeout flow. (completed 2026-05-26)

Plan files:

- [03D-PLAN.md](phases/03d-student-profile-and-trait-editing/03D-PLAN.md)
- [03D-CHECKPOINT.md](phases/03d-student-profile-and-trait-editing/03D-CHECKPOINT.md)
- [03E-PLAN.md](phases/03e-assignment-review-editing/03E-PLAN.md)
- [03E-CHECKPOINT.md](phases/03e-assignment-review-editing/03E-CHECKPOINT.md)
- [03F-PLAN.md](phases/03f-post-lesson-closeout/03F-PLAN.md)
- [03F-CHECKPOINT.md](phases/03f-post-lesson-closeout/03F-CHECKPOINT.md)

### Phase 4: Instructor Workbench Polish

**Goal**: The dashboard and student detail surfaces become faster and clearer for repeated daily teaching work.
**Mode:** mvp-polish
**UI hint**: yes
**Depends on**: Phase 3
**Requirements**: [ROST-05, PROG-04, PROG-05, QUICK-01]
**Success Criteria**:

  1. Instructor can filter the roster by the students who need attention first.
  2. Instructor can move progress items through common statuses without opening a full edit form.
  3. Instructor can record a small tempo checkpoint on progress items when BPM matters.
  4. Instructor can add the smallest useful note or next-action update from the dashboard without leaving the scan surface.
  5. Desktop and 320px mobile layouts remain dense, readable, and free of text overlap.
  6. Lesson Brief starts with the first action to check, and Closeout can change current focus without forcing a status change.

Plans:

- [x] 04A: Add dashboard filters and faster progress status transitions. (completed 2026-05-26)
- [x] 04B: Add tempo checkpoint and limited dashboard quick-add actions. (completed 2026-05-26)
- [x] 04C: Tighten Lesson Brief and Closeout meanings. (completed 2026-05-26)

Plan files:

- [04A-PLAN.md](phases/04a-workbench-filters-and-progress-polish/04A-PLAN.md)
- [04A-CHECKPOINT.md](phases/04a-workbench-filters-and-progress-polish/04A-CHECKPOINT.md)
- [04B-PLAN.md](phases/04b-tempo-and-quick-add-refinements/04B-PLAN.md)
- [04B-CHECKPOINT.md](phases/04b-tempo-and-quick-add-refinements/04B-CHECKPOINT.md)
- [04C-PLAN.md](phases/04c-brief-closeout-tightening/04C-PLAN.md)
- [04C-CHECKPOINT.md](phases/04c-brief-closeout-tightening/04C-CHECKPOINT.md)

### Phase 5: Lesson Flow Operating Board

**Goal**: The instructor can run a lesson from the dashboard queue through in-lesson checks into closeout without retyping.
**Mode:** mvp-polish
**UI hint**: yes
**Depends on**: Phase 4
**Requirements**: [FLOW-01, FLOW-02, FLOW-03, FLOW-04, FLOW-05]
**Success Criteria**:

  1. Dashboard queue is grouped into overdue, today, and upcoming work.
  2. Each queued lesson exposes the first action to check and attention flags.
  3. Student detail shows Lesson Brief, in-lesson run panel, and Closeout as one lesson-flow workspace.
  4. In-lesson working notes can become a closeout draft without saving partial data.
  5. Draft next hint fills both note hint and next action unless the instructor edits the closeout.
  6. Existing closeout remains the durable write path and dashboard/detail state agrees after refresh.

Plans:

- [x] 05: Add lesson operating board and in-lesson run panel. (completed 2026-05-28)

Plan files:

- [05-PLAN.md](phases/05-lesson-flow-operating-board/05-PLAN.md)
- [05-CHECKPOINT.md](phases/05-lesson-flow-operating-board/05-CHECKPOINT.md)

### Phase 6: Calendar-First Scheduling And Apple Calendar Sync

**Goal**: The instructor can manage lesson schedule occurrences from Drum Lesson OS and have app-owned create/update/delete operations sync to Apple Calendar.
**Mode:** integration
**UI hint**: yes
**Depends on**: Phase 5
**Requirements**: [CAL-01, CAL-02, CAL-03, CAL-04, CAL-05, CAL-06, CAL-07, CAL-08, CAL-09, CAL-10]
**Success Criteria**:

  1. Dashboard opens as a calendar-first today/week lesson schedule.
  2. Instructor can create, edit, and delete one-off lesson occurrences.
  3. Instructor can create a weekly recurring lesson template that expands into individual upcoming occurrences.
  4. Each scheduled occurrence can open the existing lesson-flow workspace.
  5. Apple Calendar connection uses iCloud CalDAV credentials stored server-side and encrypted.
  6. App-owned occurrence creates, updates, and deletes sync to Apple Calendar through an outbox.
  7. Failed Apple sync is visible, retryable, and does not corrupt app-owned schedule data.
  8. Optional reverse sync imports only app-created Apple events and keeps Drum Lesson OS as canonical on conflicts.

Plans:

- [x] 06A: Add calendar-first scheduling and Apple Calendar one-way sync.
- [ ] 06B: Optional reverse sync for app-created Apple events after one-way sync is stable.

Plan files:

- [06-PLAN.md](phases/06-calendar-apple-sync/06-PLAN.md)

### Phase 7: SwiftUI Native Migration

**Goal**: The instructor can run Drum Lesson OS as a macOS SwiftUI app while Supabase remains canonical and EventKit handles native Apple Calendar writes.
**Mode:** native-migration
**UI hint**: yes
**Depends on**: Phase 6A
**Requirements**: Existing instructor-side MVP requirements plus Phase 7 parity/release gates
**Success Criteria**:

  1. Native macOS app builds, launches, and passes its Swift test suite.
  2. Native screens cover dashboard, roster, student detail, editing workflows, lesson flow, scheduling, settings, and sync status.
  3. Native writes use authenticated Supabase RPCs and never embed the service-role key.
  4. Native Apple Calendar access uses EventKit and stores only recoverable calendar identifiers.
  5. EventKit failures are visible and retryable without corrupting Supabase schedule data.
  6. The legacy Next.js runtime has been removed after Phase 7 approval so future work starts from the native app.

Plans:

- [x] 07: Add SwiftUI native implementation candidate and release-gate evidence. (implemented 2026-05-28; independent review approved)
- [x] 07R: Reorganize repo as native-primary and remove legacy web runtime. (completed 2026-05-28)

Plan files:

- [07-PLAN.md](phases/07-swiftui-native-migration/07-PLAN.md)
- [07-CHECKPOINT.md](phases/07-swiftui-native-migration/07-CHECKPOINT.md)
- [07-RELEASE-GATE.md](phases/07-swiftui-native-migration/07-RELEASE-GATE.md)
- [07-NATIVE-PRIMARY-REORG.md](phases/07-swiftui-native-migration/07-NATIVE-PRIMARY-REORG.md)

### Phase 8: Native Workbench Design Overhaul

**Goal**: The native macOS app feels like a polished daily teaching workbench, with clear next-action hierarchy and a consistent SwiftUI design system.
**Mode:** native-polish
**UI hint**: yes
**Depends on**: Phase 7
**Requirements**: Existing instructor-side MVP requirements plus Phase 8 visual hierarchy and usability gates
**Success Criteria**:

  1. Dashboard shows the current or selected lesson as the primary decision point, with native-feeling schedule controls and a clearer selected lesson action area.
  2. Student detail shows the student cue, first check, run notes, closeout, teaching memory, and maintenance editors in a priority order that supports pre-lesson and in-lesson use.
  3. Broad maintenance editing no longer appears as a six-section form wall above the read-only teaching context.
  4. Settings clearly separates Calendar permission, writable calendar, sync queue, retry, and account actions.
  5. Shared SwiftUI design components define surface roles, status states, section headers, and action grouping without overbuilding a large design-system layer.
  6. Light and dark appearance remain readable, and compact/wide windows avoid text overlap.
  7. The native entry flow restores a saved Keychain session before rendering the app shell, and only shows account connection when no usable session remains.
  8. Existing native tests, SQL guard tests, and Computer Use smoke checks pass after the visual changes.

Plans:

- [x] 08: Redesign native workbench surfaces and shared visual system. (implemented 2026-05-28; independent design verification OK)

Plan files:

- [08-PLAN.md](phases/08-native-workbench-design-overhaul/08-PLAN.md)
- [08-RESEARCH.md](phases/08-native-workbench-design-overhaul/08-RESEARCH.md)
- [08-UI-SPEC.md](phases/08-native-workbench-design-overhaul/08-UI-SPEC.md)
- [08-CHECKPOINT.md](phases/08-native-workbench-design-overhaul/08-CHECKPOINT.md)

### Phase 9: Native UI/UX Hardening

**Goal**: The local macOS app supports fast, safe daily teaching work with compact native forms, consistent navigation context, explicit calendar state, and accessible lesson cues.
**Mode:** native-ux-hardening
**UI hint**: yes
**Depends on**: Phase 8
**Requirements**: Existing instructor-side MVP requirements plus the Phase 9 audit findings
**Success Criteria**:

  1. Student browsing cannot accidentally create a lesson closeout without an explicit lesson occurrence.
  2. Add Lesson, Edit Lesson Time, and Add Student sheets are content-sized, keyboard-friendly, consistently labeled, and readable in Korean.
  3. Student and lesson detail routes preserve visible top-level navigation context and a clear return path.
  4. Compact dashboards prioritize today's lessons and the selected lesson before whole-week supporting context.
  5. Calendar permission, writable-calendar selection, errors, loading, and queue-empty states are visible and recoverable.
  6. Core first-check, attention, selection, error, and success meaning remains available to VoiceOver and does not rely on color alone.
  7. Wide/compact and light/dark checks pass with no clipping or text overlap.
  8. The native build, full test suite, and diff check pass after the changes.

Plans:

- [x] 09: Execute the native UI/UX audit backlog and document the verification checkpoint. (implemented and verified 2026-07-11; live EventKit and direct compact/light UAT remain release checks)

Plan files:

- [09-AUDIT.md](phases/09-native-ui-ux-hardening/09-AUDIT.md)
- [09-PLAN.md](phases/09-native-ui-ux-hardening/09-PLAN.md)
- [09-CHECKPOINT.md](phases/09-native-ui-ux-hardening/09-CHECKPOINT.md)

### Phase 10: In-Lesson Workspace Redesign

**Goal**: The active lesson route becomes a fast, legible teaching console that keeps the first check, live capture, and closeout action in view without mounting the full student-management surface.
**Mode:** native-focused-redesign
**UI hint**: yes
**Depends on**: Phase 9
**Requirements**: Existing lesson-flow and closeout requirements plus active-session rendering, hierarchy, and accessibility improvements
**Success Criteria**:

  1. Active lessons render a dedicated session header and workspace instead of the full student-detail management stack.
  2. First check, live notes, readiness, review, and save form one clear progressive flow with no empty closeout card.
  3. Student history remains available on demand in a focused side panel, while maintenance editors remain available from normal student detail.
  4. Wide and compact layouts use a single adaptive content subtree, keep important teaching text untruncated, and preserve keyboard and VoiceOver meaning.
  5. Run-note drafts and the existing occurrence-backed atomic closeout semantics remain unchanged.
  6. The native build, full test suite, diff check, and direct running-app verification pass after the changes.

Plans:

- [x] 10: Redesign, optimize, and verify the active lesson workspace. (completed 2026-07-11)

Plan files:

- [10-PLAN.md](phases/10-in-lesson-workspace-redesign/10-PLAN.md)
- [10-CHECKPOINT.md](phases/10-in-lesson-workspace-redesign/10-CHECKPOINT.md)

## Explicitly Not Planned

These items should not be revived as near-term phases without a new product decision:

- Student portal or student login.
- Payments, invoices, or billing.
- Attendance tracking.
- Calendar reminders, external booking, or non-Apple calendar providers.
- AI summary generation.
- Audio/video upload or analysis.
- Full curriculum/syllabus builder.

## Progress

**Execution Order:**
Phases execute in this order: 1 -> 2 -> 3A -> 3B -> 3C -> 3D -> 3E -> 3F -> 4A -> 4B -> 4C -> 5 -> 6 -> 7 -> 8 -> 9 -> 10

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. App Foundation And Data Model | 3/3 | Complete | 2026-05-22 |
| 2. Student Roster And Detail Read Views | 3/3 | Complete | 2026-05-25 |
| 3. Teaching Workflow Editing | 6/6 | Complete | 2026-05-26 |
| 4. Instructor Workbench Polish | 3/3 | Complete | 2026-05-26 |
| 5. Lesson Flow Operating Board | 1/1 | Complete | 2026-05-28 |
| 6. Calendar-First Scheduling And Apple Calendar Sync | 1/1 | Phase 6A verification | 2026-05-28 |
| 7. SwiftUI Native Migration | 1/1 | Native-primary repo layout; live UAT pending | 2026-05-28 |
| 8. Native Workbench Design Overhaul | 1/1 | Complete | 2026-05-28 |
| 9. Native UI/UX Hardening | 1/1 | Implementation complete; live visual/EventKit UAT remains | 2026-07-11 |
| 10. In-Lesson Workspace Redesign | 1/1 | Complete | 2026-07-11 |
