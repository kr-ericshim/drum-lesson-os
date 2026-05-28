# Drum Lesson OS

## What This Is

Drum Lesson OS is a mini CRM for drum instructors who teach multiple students and need one place to remember each student's progress, habits, and lesson context. It helps an instructor see where every student is, what each person struggles with, and what should happen next in the lesson.

The MVP focuses on instructor-side student management in a macOS native app: a calendar-first schedule, clear student list, per-student progress tracking, lesson notes, student traits, weaknesses, practice patterns, and next-lesson preparation.

## Core Value

An instructor can quickly understand a student's current progress and personal characteristics before or during a lesson.

## Requirements

### Validated

(None yet - ship to validate)

### Active

- [ ] Instructor can manage multiple drum students from one dashboard.
- [ ] Instructor can record each student's current progress by practical lesson categories such as books, songs, rudiments, genres, techniques, lesson sessions, and assignments.
- [ ] Instructor can capture student-specific traits such as strengths, weak points, practice habits, learning style, and musical preferences.
- [ ] Instructor can review recent lesson notes for a student.
- [ ] Instructor can prepare the next lesson using visible progress, notes, weak points, and assignment status.
- [ ] Instructor can update progress and notes with minimal friction during or after a lesson.

### Out of Scope

- Student-facing accounts - MVP is instructor-side first, so students do not need login or self-service screens.
- Payments, invoices, attendance, reminders, and external booking - useful for a broader studio CRM, but not part of the current product direction.
- AI summaries, full music notation, and audio/video analysis - high complexity and not necessary to validate instructor workflow.
- Multi-instructor studio administration - MVP targets one instructor managing their own students.

## Context

The project started from the need for a drum teacher to manage several students' progress and personal characteristics at a glance. The strongest pain points are progress tracking and remembering student-specific details.

Useful progress dimensions include books, songs, rudiments, genres, techniques, lesson sessions, and assignments. Useful student-detail dimensions include rhythmic strengths, weak fill patterns, practice consistency, whether a student responds better to verbal explanation or demonstration, and musical taste.

The first screen should feel like a working native instructor dashboard. The most important student detail view should surface current progress, recent lesson notes, next lesson plan, weak points or cautions, and assignment follow-through.

## Constraints

- **Scope**: Keep MVP focused on instructor-side student CRM - this validates the core workflow before expanding to student accounts or payments.
- **UX**: Optimize for fast scanning before a lesson - instructors should not need to dig through many screens to remember what matters.
- **Data model**: Preserve flexible lesson notes and trait fields - early usage may reveal which categories deserve structured fields later.
- **Safety**: Avoid overbuilding music-analysis features before the basic management loop works.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Build for instructor-side use first | The core problem is the instructor remembering progress and student traits across many students. | - Pending |
| Treat progress tracking and student traits as the MVP center | These are the two strongest pain points identified during project questioning. | - Pending |
| Defer payments, scheduling automation, student accounts, and audio analysis | These add complexity before validating the core lesson-management workflow. | - Pending |
| Exclude student portal, payments, attendance, calendar automation, AI summaries, and audio/video analysis from the next roadmap | The next useful work was finishing instructor-side editing, closeout, filters, and small drum-specific checkpoints. Superseded in part by the later Phase 6 Apple Calendar decision. | 2026-05-26 |
| Add calendar-first scheduling and Apple Calendar sync as Phase 6 | The instructor already uses Apple Calendar, and the lesson operating board can become more useful when schedule changes from Drum Lesson OS write through to Apple Calendar. Drum Lesson OS remains the schedule source of truth. | 2026-05-28 |
| Promote the macOS SwiftUI app to the primary project shape | Phase 7 passed independent implementation review, and keeping the native app nested inside a removed web runtime confused follow-up agents. | 2026-05-28 |
| Remove the legacy Next.js runtime from the working tree | The current product direction is macOS native plus Supabase migrations/RPCs. Historical web evidence remains in planning docs only. | 2026-05-28 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each standalone phase transition**:
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone**:
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-28 after Phase 7 native-primary reorganization*
