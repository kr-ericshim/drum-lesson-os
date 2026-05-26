# Requirements: Drum Lesson OS

**Defined:** 2026-05-22
**Last updated:** 2026-05-26
**Core Value:** An instructor can quickly understand a student's current progress and personal characteristics before or during a lesson.

## v1 Requirements

### Foundation

- [x] **FND-01**: Instructor can run the app locally with a persistent database.
- [x] **FND-02**: App includes a durable data model for students, progress items, lesson notes, traits, assignments, and next lesson plans.
- [x] **FND-03**: App includes realistic sample data that demonstrates multiple students with different progress states and learning traits.

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

## Not Planned

The following are not part of the current product direction:

| Feature | Product decision |
|---------|------------------|
| Student portal or student login | Excluded from the near-term roadmap. |
| Payments, invoices, or billing | Excluded from the near-term roadmap. |
| Attendance tracking | Excluded from the near-term roadmap. |
| Calendar integration or recurring schedule automation | Excluded from the near-term roadmap. |
| AI lesson summaries | Excluded from the near-term roadmap. |
| Audio/video upload or analysis | Excluded from the near-term roadmap. |
| Full curriculum/syllabus builder | Excluded from v1; keep student progress flexible. |

## Release Gate

Real instructor authentication and production RLS cleanup remain required before sharing real student data outside the demo environment. This is a release gate, not a new user-facing product phase.

## Traceability

Traceability maps every v1 requirement to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FND-01 | Phase 1 | Complete |
| FND-02 | Phase 1 | Complete |
| FND-03 | Phase 1 | Complete |
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

**Coverage:**
- v1 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0
