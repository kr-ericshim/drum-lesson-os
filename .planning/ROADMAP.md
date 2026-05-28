# Roadmap: Drum Lesson OS

## Overview

Drum Lesson OS v1 stays focused on the instructor-side memory loop: know the student before the lesson, update the teaching record quickly, and leave the next lesson action visible. Phase 5 connects dashboard triage, in-lesson checks, and closeout drafting so the MVP stays centered on the 30-second pre-lesson and 2-minute post-lesson routine. Phase 6 adds a calendar-first schedule surface and Apple Calendar write-through sync because the instructor already uses Apple Calendar day to day. Phase 7 moved the same MVP workflow into a macOS SwiftUI app with EventKit replacing Apple credential storage.

The current repo is native-first: `project.yml`, `DrumLessonOS/`, `DrumLessonOSTests/`, `supabase/`, and `tests/` are the active implementation surfaces. The legacy Next.js runtime has been removed after Phase 7 approval.

The next phases intentionally exclude student portals, payments, attendance, reminders, AI summaries, and audio/video analysis. Real instructor authentication is implemented as a release gate; live deployment still requires applying the auth migration and binding the single Supabase Auth user to the existing instructor row.

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
Phases execute in this order: 1 -> 2 -> 3A -> 3B -> 3C -> 3D -> 3E -> 3F -> 4A -> 4B -> 4C -> 5 -> 6 -> 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. App Foundation And Data Model | 3/3 | Complete | 2026-05-22 |
| 2. Student Roster And Detail Read Views | 3/3 | Complete | 2026-05-25 |
| 3. Teaching Workflow Editing | 6/6 | Complete | 2026-05-26 |
| 4. Instructor Workbench Polish | 3/3 | Complete | 2026-05-26 |
| 5. Lesson Flow Operating Board | 1/1 | Complete | 2026-05-28 |
| 6. Calendar-First Scheduling And Apple Calendar Sync | 1/1 | Phase 6A verification | 2026-05-28 |
| 7. SwiftUI Native Migration | 1/1 | Native-primary repo layout; live UAT pending | 2026-05-28 |
