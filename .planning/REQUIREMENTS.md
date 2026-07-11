# Requirements: Drum Lesson OS

**Defined:** 2026-05-22
**Last updated:** 2026-07-11
**Core Value:** An instructor can quickly understand a student's current progress and personal characteristics before or during a lesson.
**Implementation status:** 53 complete, 1 deferred, 1 pending direct release UAT

## v1 Requirements

### Foundation

- [x] **FND-01**: Instructor can run the app locally with a persistent database.
- [x] **FND-02**: App includes a durable data model for students, progress items, lesson notes, traits, assignments, and next lesson plans.
- [x] **FND-03**: App includes realistic sample data that demonstrates multiple students with different progress states and learning traits.
- [x] **FND-04**: Instructor can export and restore a validated versioned local backup with a pre-restore safety copy.

### Student Roster

- [x] **ROST-01**: Instructor can view all active students in a dashboard list.
- [x] **ROST-02**: Instructor can see each student's current focus, primary weak point, assignment status, and next lesson action from the roster.
- [x] **ROST-03**: Instructor can add a new student with basic lesson-relevant profile information.
- [x] **ROST-04**: Instructor can edit a student's basic profile information.
- [x] **ROST-05**: Instructor can filter the roster by needs review, high-priority next lesson, no recent note, and missing current focus.

### Student Detail

- [x] **STUD-01**: Instructor can open a student detail view from the roster.
- [x] **STUD-02**: Student detail view shows current progress, recent lesson notes, traits, weak points, assignment status, and next lesson plan together.
- [x] **STUD-03**: Instructor can update student traits such as strengths, weak points, practice habits, learning style, and musical preferences.

### Progress

- [x] **PROG-01**: Instructor can create progress items using flexible categories such as books, songs, rudiments, genres, techniques, lesson sessions, and assignments.
- [x] **PROG-02**: Instructor can update progress item status and notes.
- [x] **PROG-03**: Instructor can identify the student's current focus without reading the full lesson history.
- [x] **PROG-04**: Instructor can move a progress item through common statuses from the progress list with minimal interaction.
- [x] **PROG-05**: Instructor can record a small tempo checkpoint for progress items where BPM matters.
- [x] **PROG-06**: Instructor can append dated BPM, status, and observation checkpoints without overwriting earlier progress history.

### Lesson Notes

- [x] **NOTE-01**: Instructor can add a dated lesson note for a student.
- [x] **NOTE-02**: Instructor can record what was covered, what was observed, practice assigned, and next-step hints in a lesson note.
- [x] **NOTE-03**: Instructor can review recent notes in reverse chronological order.

### Assignments And Next Lesson

- [x] **NEXT-01**: Instructor can record a student's current assignment or practice task.
- [x] **NEXT-02**: Instructor can mark assignment status such as not started, in progress, needs review, complete, or paused.
- [x] **NEXT-03**: Instructor can write and update a next lesson plan for each student.
- [x] **NEXT-04**: Dashboard and student detail views surface the next lesson action clearly.

### Post-Lesson Closeout

- [x] **CLOSE-01**: Instructor can use one compact closeout form to create a lesson note and update the next lesson plan.
- [x] **CLOSE-02**: Instructor can create or update the assignment review cue from the closeout flow.
- [x] **CLOSE-03**: Instructor can optionally update progress status or current focus from the closeout flow.

### Dashboard Quick Actions

- [x] **QUICK-01**: Instructor can add the smallest useful note or next-action update from the dashboard without opening the full student detail workflow.

### Lesson Flow

- [x] **FLOW-01**: Instructor can see the first action to check for each queued lesson from the dashboard.
- [x] **FLOW-02**: Instructor can tell which queued lessons are overdue, today, or upcoming without reading every date.
- [x] **FLOW-03**: Instructor can record short in-lesson working notes before committing the final closeout.
- [x] **FLOW-04**: Instructor can turn in-lesson working notes into a closeout draft without retyping.
- [x] **FLOW-05**: Existing closeout remains the durable save path and keeps dashboard/detail state aligned after refresh.
- [x] **DRAFT-01**: In-lesson working notes are saved automatically for the current lesson occurrence after a short typing delay.
- [x] **DRAFT-02**: Reopening a lesson with an unfinished draft offers explicit continue and delete actions before editing resumes.
- [x] **DRAFT-03**: The lesson workspace shows saving, saved-time, and save-failure feedback without interrupting the lesson.
- [x] **DRAFT-04**: Successful lesson closeout removes its persisted draft in the same local transaction.
- [x] **DRAFT-05**: Portable backups include unfinished drafts and older supported backups restore with an empty draft collection.

### Calendar Scheduling And Apple Sync

- [x] **CAL-01**: Instructor can view today and the current week as a calendar-first lesson schedule.
- [x] **CAL-02**: Instructor can create a one-off scheduled lesson for an existing student.
- [x] **CAL-03**: Instructor can create a recurring lesson template that expands into individual upcoming lesson occurrences.
- [x] **CAL-04**: Instructor can edit or delete a Drum Lesson OS lesson occurrence.
- [x] **CAL-05**: Instructor can start the existing lesson-flow workspace from a scheduled calendar occurrence.
- [x] **CAL-06**: Drum Lesson OS syncs app-owned occurrence creates, updates, and deletes to Apple Calendar.
- [x] **CAL-07**: Instructor can see whether an occurrence is Apple-synced, pending, failed, or disconnected.
- [x] **CAL-08**: Instructor can manually retry Apple Calendar sync.
- [x] **CAL-09**: Apple Calendar credential failures do not corrupt app-owned schedule data.
- [ ] **CAL-10**: Optional reverse sync imports Apple-side changes only for events originally created by Drum Lesson OS.

### Native macOS Migration

- [x] **NATIVE-01**: Instructor can build and launch a macOS SwiftUI implementation of the current Drum Lesson OS workflow.
- [x] **NATIVE-02**: Native screens cover the calendar-first dashboard, roster, student detail, editing workflows, lesson flow, scheduling, settings, and sync status.
- [x] **NATIVE-03**: Native writes use transactional local SQLite persistence without requiring hosted authentication.
- [x] **NATIVE-04**: Native Apple Calendar integration uses EventKit instead of prompting for Apple ID or app-specific password credentials.
- [x] **NATIVE-05**: EventKit failures are visible and retryable through a durable local outbox without corrupting local lesson occurrence data.
- [ ] **NATIVE-06**: Native production use is verified with real EventKit create/edit/cancel, iPhone iCloud propagation, and daily-use confidence.
- [x] **NATIVE-07**: Repo structure is native-primary, with SwiftUI app source at root and the legacy web runtime removed from active development.

### Prepaid Tuition Management

- [x] **TUIT-01**: Instructor can scan each active student's current four-lesson cycle from a dedicated tuition workspace.
- [x] **TUIT-02**: A successful scheduled-lesson closeout advances the configured tuition cycle exactly once.
- [x] **TUIT-03**: Instructor can manually set the current cycle, confirm or correct prepaid tuition with a date, and start the next four-lesson cycle.
- [x] **TUIT-04**: Tuition cycles and payment history persist locally, survive backup and restore, and keep earlier unconfirmed cycles visible.

## Not Planned

The following are not part of the current product direction:

| Feature | Product decision |
|---------|------------------|
| Student portal or student login | Excluded from the near-term roadmap. |
| Bank integration, invoices, payment processing, or tuition amounts | Excluded; Phase 12 only tracks four-lesson cycles and manual prepaid confirmation. |
| Attendance tracking | Excluded from the near-term roadmap. |
| Calendar reminders, external booking, or non-Apple calendar providers | Excluded from Phase 6. |
| AI lesson summaries | Excluded from the near-term roadmap. |
| Audio/video upload or analysis | Excluded from the near-term roadmap. |
| Full curriculum/syllabus builder | Excluded from v1; keep student progress flexible. |

## Release Gate

The active app keeps teaching records on this Mac and does not expose a hosted account boundary. Live EventKit/iPhone UAT, local backup confidence, and daily-use confidence remain required before relying on it for real teaching records.

## Traceability

Traceability maps every v1 requirement to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FND-01 | Phase 1 | Complete |
| FND-02 | Phase 1 | Complete |
| FND-03 | Phase 1 | Complete |
| FND-04 | Phase 11 | Complete |
| ROST-01 | Phase 2 | Complete |
| ROST-02 | Phase 3C | Complete |
| ROST-03 | Phase 3D | Complete |
| ROST-04 | Phase 3D | Complete |
| ROST-05 | Phase 4A | Complete |
| STUD-01 | Phase 2 | Complete |
| STUD-02 | Phase 2 | Complete |
| STUD-03 | Phase 3D | Complete |
| PROG-01 | Phase 3B | Complete |
| PROG-02 | Phase 3B | Complete |
| PROG-03 | Phase 3C | Complete |
| PROG-04 | Phase 4A | Complete |
| PROG-05 | Phase 4B | Complete |
| PROG-06 | Phase 11 | Complete |
| NOTE-01 | Phase 3A | Complete |
| NOTE-02 | Phase 3A | Complete |
| NOTE-03 | Phase 2 | Complete |
| NEXT-01 | Phase 3E | Complete |
| NEXT-02 | Phase 3E | Complete |
| NEXT-03 | Phase 3A | Complete |
| NEXT-04 | Phase 3C | Complete |
| CLOSE-01 | Phase 3F | Complete |
| CLOSE-02 | Phase 3F | Complete |
| CLOSE-03 | Phase 3F | Complete |
| QUICK-01 | Phase 4B | Complete |
| FLOW-01 | Phase 5 | Complete |
| FLOW-02 | Phase 5 | Complete |
| FLOW-03 | Phase 5 | Complete |
| FLOW-04 | Phase 5 | Complete |
| FLOW-05 | Phase 5 | Complete |
| CAL-01 | Phase 6 | Complete |
| CAL-02 | Phase 6 | Complete |
| CAL-03 | Phase 6 | Complete |
| CAL-04 | Phase 6 | Complete |
| CAL-05 | Phase 6 | Complete |
| CAL-06 | Phase 6 | Complete |
| CAL-07 | Phase 6 | Complete |
| CAL-08 | Phase 6 | Complete |
| CAL-09 | Phase 6 | Complete |
| CAL-10 | Phase 6B | Deferred |
| NATIVE-01 | Phase 7 | Complete |
| NATIVE-02 | Phase 7 | Complete |
| NATIVE-03 | Phase 7 | Complete |
| NATIVE-04 | Phase 7 | Complete |
| NATIVE-05 | Phase 7 | Complete |
| NATIVE-06 | Phase 7 release gate | Pending live UAT |
| NATIVE-07 | Phase 7 native-primary reorg | Complete |
| TUIT-01 | Phase 12 | Complete |
| TUIT-02 | Phase 12 | Complete |
| TUIT-03 | Phase 12 | Complete |
| TUIT-04 | Phase 12 | Complete |
| DRAFT-01 | Phase 13 | Complete |
| DRAFT-02 | Phase 13 | Complete |
| DRAFT-03 | Phase 13 | Complete |
| DRAFT-04 | Phase 13 | Complete |
| DRAFT-05 | Phase 13 | Complete |

**Coverage:**
- tracked requirements: 60 total
- Mapped to phases: 60
- Unmapped: 0
- Complete: 58
- Deferred: 1 (`CAL-10`)
- Pending direct release UAT: 1 (`NATIVE-06`)
