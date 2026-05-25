# Requirements: Drum Lesson OS

**Defined:** 2026-05-22
**Core Value:** An instructor can quickly understand a student's current progress and personal characteristics before or during a lesson.

## v1 Requirements

### Foundation

- [x] **FND-01**: Instructor can run the app locally with a persistent database.
- [x] **FND-02**: App includes a durable data model for students, progress items, lesson notes, traits, assignments, and next lesson plans.
- [x] **FND-03**: App includes realistic sample data that demonstrates multiple students with different progress states and learning traits.

### Student Roster

- [x] **ROST-01**: Instructor can view all active students in a dashboard list.
- [ ] **ROST-02**: Instructor can see each student's current focus, primary weak point, assignment status, and next lesson action from the roster.
- [ ] **ROST-03**: Instructor can add a new student with basic lesson-relevant profile information.
- [ ] **ROST-04**: Instructor can edit a student's basic profile information.

### Student Detail

- [x] **STUD-01**: Instructor can open a student detail view from the roster.
- [x] **STUD-02**: Student detail view shows current progress, recent lesson notes, traits, weak points, assignment status, and next lesson plan together.
- [ ] **STUD-03**: Instructor can update student traits such as strengths, weak points, practice habits, learning style, and musical preferences.

### Progress

- [x] **PROG-01**: Instructor can create progress items using flexible categories such as books, songs, rudiments, genres, techniques, lesson sessions, and assignments.
- [x] **PROG-02**: Instructor can update progress item status and notes.
- [ ] **PROG-03**: Instructor can identify the student's current focus without reading the full lesson history.

### Lesson Notes

- [ ] **NOTE-01**: Instructor can add a dated lesson note for a student.
- [ ] **NOTE-02**: Instructor can record what was covered, what was observed, practice assigned, and next-step hints in a lesson note.
- [x] **NOTE-03**: Instructor can review recent notes in reverse chronological order.

### Assignments And Next Lesson

- [ ] **NEXT-01**: Instructor can record a student's current assignment or practice task.
- [ ] **NEXT-02**: Instructor can mark assignment status such as not started, practicing, needs review, or complete.
- [ ] **NEXT-03**: Instructor can write and update a next lesson plan for each student.
- [ ] **NEXT-04**: Dashboard and student detail views surface the next lesson action clearly.

## v2 Requirements

### Studio Operations

- **OPS-01**: Instructor can manage recurring lesson schedules.
- **OPS-02**: Instructor can track attendance.
- **OPS-03**: Instructor can manage payments or invoices.
- **OPS-04**: Instructor can send reminders or messages to students or parents.

### Student Portal

- **PORT-01**: Student can log in to view assignments and lesson notes.
- **PORT-02**: Student can mark practice activity or assignment progress.

### Advanced Music Features

- **MUS-01**: App can manage a structured drum syllabus.
- **MUS-02**: App can attach audio/video references to lesson notes.
- **MUS-03**: App can analyze student audio or video practice.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Student-facing accounts | MVP validates instructor workflow first. |
| Payments and invoices | Useful studio CRM feature, but unrelated to the initial progress/trait memory loop. |
| Scheduling automation | Common in the market, but can wait until the core lesson-management flow works. |
| Multi-instructor studio administration | MVP targets one instructor managing their own students. |
| Audio/video analysis | High complexity and not needed to validate the CRM workflow. |
| Hardcoded complete drum syllabus | Early data should stay flexible until real usage reveals the right structure. |

## Traceability

Traceability maps every v1 requirement to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FND-01 | Phase 1 | Complete |
| FND-02 | Phase 1 | Complete |
| FND-03 | Phase 1 | Complete |
| ROST-01 | Phase 2 | Complete |
| ROST-02 | Phase 4 | Pending |
| ROST-03 | Phase 3 | Pending |
| ROST-04 | Phase 3 | Pending |
| STUD-01 | Phase 2 | Complete |
| STUD-02 | Phase 2 | Complete |
| STUD-03 | Phase 3 | Pending |
| PROG-01 | Phase 3 | Complete |
| PROG-02 | Phase 3 | Complete |
| PROG-03 | Phase 4 | Pending |
| NOTE-01 | Phase 3 | Pending |
| NOTE-02 | Phase 3 | Pending |
| NOTE-03 | Phase 2 | Complete |
| NEXT-01 | Phase 3 | Pending |
| NEXT-02 | Phase 3 | Pending |
| NEXT-03 | Phase 3 | Pending |
| NEXT-04 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0

---
*Requirements defined: 2026-05-22*
*Last updated: 2026-05-25 after Phase 3B progress item editing completion*
