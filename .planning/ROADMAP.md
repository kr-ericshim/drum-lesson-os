# Roadmap: Drum Lesson OS

## Overview

Drum Lesson OS v1 builds a focused instructor-side MVP in four vertical phases: first the app/data foundation, then readable student views, then editing workflows, then the pre-lesson briefing polish that makes the product useful in real teaching. The roadmap intentionally avoids broader studio CRM features until the progress and student-memory loop is proven.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: App Foundation And Data Model** - Create the runnable app foundation, persistent database, schema, and sample teaching data. (completed 2026-05-22)
- [x] **Phase 2: Student Roster And Detail Read Views** - Let the instructor browse students and read the full teaching context for one student. (completed 2026-05-25)
- [ ] **Phase 3: Teaching Workflow Editing** - Add create/edit flows for students, traits, progress, lesson notes, assignments, and next lesson plans. (03A and 03B completed 2026-05-25)
- [ ] **Phase 4: Pre-Lesson Briefing Polish** - Turn the dashboard into a fast scan surface for current focus, weak points, assignment status, and next actions.

## Phase Details

### Phase 1: App Foundation And Data Model

**Goal**: The project has a runnable full-stack MVP foundation with hosted Supabase/Postgres persistence and realistic drum lesson sample data.
**Mode:** mvp
**UI hint**: yes
**Depends on**: Nothing (first phase)
**Requirements**: [FND-01, FND-02, FND-03]
**Success Criteria** (what must be TRUE):

  1. Instructor can run the app locally and see a working first screen.
  2. Student, progress, trait, lesson note, assignment, and next plan data persist in the database.
  3. Sample data shows multiple students with different progress states and learning traits.

**Plans**: 3 plans

Plans:
**Wave 1**

- [x] 01-01: Scaffold Next.js, TypeScript, Tailwind, shadcn/ui, and base app layout.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02: Add Supabase/Postgres schema, RLS policies, migrations, and seed script.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-03: Add seed-backed dashboard preview and foundation verification.

### Phase 2: Student Roster And Detail Read Views

**Goal**: The instructor can browse students and open a detail page that shows the teaching context needed before a lesson.
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 1
**Requirements**: [ROST-01, STUD-01, STUD-02, NOTE-03]
**Success Criteria** (what must be TRUE):

  1. Instructor can see all active students in a dashboard list.
  2. Instructor can open a student detail view from the roster.
  3. Student detail shows current progress, recent lesson notes, traits, weak points, assignment status, and next lesson plan together.
  4. Recent lesson notes appear in reverse chronological order.

**Plans**: 3 plans

Plans:
**Wave 1**

- [x] 02-01: Build roster data loader and dashboard list UI.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 02-02: Build student detail route and context sections.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 02-03: Add recent-note ordering and read-view verification.

### Phase 3: Teaching Workflow Editing

**Goal**: The instructor can maintain the teaching record during or after lessons without leaving the student workflow.
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 2
**Requirements**: [ROST-03, ROST-04, STUD-03, PROG-01, PROG-02, NOTE-01, NOTE-02, NEXT-01, NEXT-02, NEXT-03]
**Success Criteria** (what must be TRUE):

  1. Instructor can add and edit student profile information.
  2. Instructor can edit traits, strengths, weak points, practice habits, learning style, and musical preferences.
  3. Instructor can create and update flexible progress items with status and notes.
  4. Instructor can add dated lesson notes with covered material, observations, practice assigned, and next-step hints.
  5. Instructor can record assignment status and update the next lesson plan.

**Plans**: 4 plans

Plans:

- [x] 03A: Add lesson note creation and next lesson plan editing as the first focused editing slice. (completed 2026-05-25)
- [ ] 03-01: Add student profile and trait editing flows.
- [x] 03B: Add progress item create/update flows. (completed 2026-05-25)
- [ ] 03-03: Add lesson note, assignment, and next lesson plan editing flows.

### Phase 4: Pre-Lesson Briefing Polish

**Goal**: The roster becomes a fast pre-lesson briefing surface that highlights what the instructor should remember and do next.
**Mode:** mvp
**UI hint**: yes
**Depends on**: Phase 3
**Requirements**: [ROST-02, PROG-03, NEXT-04]
**Success Criteria** (what must be TRUE):

  1. Instructor can see each student's current focus from the roster without opening full history.
  2. Roster surfaces primary weak point, assignment status, and next lesson action for each student.
  3. Student detail and dashboard agree on the next lesson action.
  4. The main dashboard is scannable on desktop and mobile without text overlap.

**Plans**: 2 plans

Plans:

- [ ] 04-01: Add briefing indicators and current-focus summaries to dashboard and detail views.
- [ ] 04-02: Polish responsive layout, empty states, and verification coverage.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. App Foundation And Data Model | 3/3 | Complete   | 2026-05-22 |
| 2. Student Roster And Detail Read Views | 3/3 | Complete   | 2026-05-25 |
| 3. Teaching Workflow Editing | 2/4 | In progress | - |
| 4. Pre-Lesson Briefing Polish | 0/2 | Not started | - |
