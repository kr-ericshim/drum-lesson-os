# Drum Lesson OS

## Product

Drum Lesson OS is a local macOS SwiftUI CRM for a drum instructor managing multiple students. It keeps the schedule, student context, lesson notes, progress history, assignments, next-lesson preparation, prepaid four-lesson cycles, and Apple Calendar write-through in one place.

**Core value:** An instructor can quickly understand a student's current progress and personal characteristics before or during a lesson.

## Current Product State

The instructor-side implementation is complete through Phase 13. The active app:

- runs without login and stores canonical data in local SQLite;
- writes app-owned lesson occurrences to Apple Calendar through EventKit;
- preserves retryable calendar work in a durable local outbox;
- supports local backup and restore with pre-restore safety copies;
- preserves append-only progress checkpoints;
- tracks manual prepaid four-lesson tuition cycles without processing payments.
- recovers occurrence-scoped in-lesson drafts after navigation or app restart.

Release-confidence UAT remains for native backup panels, light mode, keyboard and VoiceOver behavior, real EventKit create/edit/delete, and iPhone iCloud propagation. See [STATE.md](STATE.md).

## Product Boundaries

### Included

- Instructor-only student roster and detail
- Flexible progress, traits, lesson notes, assignments, and next plans
- Calendar-first scheduling and lesson closeout
- Apple Calendar write-through with retry visibility
- Local backup and restore
- Manual four-lesson tuition-cycle tracking and dated payment confirmation

### Deferred Or Excluded

- Student or parent accounts
- Multi-instructor administration
- Bank integration, invoices, payment processing, and tuition amounts
- Attendance, reminders, external booking, and non-Apple calendar providers
- Optional Apple Calendar reverse sync
- AI summaries, notation, and audio/video upload or analysis
- Full curriculum or syllabus builder

## Constraints

- **Scope:** Protect the instructor memory and lesson-management loop before expanding into studio operations.
- **UX:** Optimize for quick scanning before a lesson and low-friction updates during or after it.
- **Data:** Keep lesson notes, progress categories, and traits flexible until real use supports stricter structure.
- **Durability:** Local teaching records must survive app restarts and recover safely from EventKit failures.

## Current Decisions

| Decision | Rationale | Date |
|----------|-----------|------|
| Keep the app instructor-only and local-first | One instructor on one Mac is the validated implementation boundary for v1. | 2026-07-10 |
| Use SQLite as canonical persistence | Transactional local writes keep the core workflow reliable without hosted infrastructure. | 2026-07-10 |
| Use EventKit only as the calendar boundary | Drum Lesson OS owns schedules while Apple Calendar remains the connected calendar target. | 2026-07-10 |
| Persist EventKit work in a durable outbox | Permission and calendar failures must not lose lesson occurrences or create untracked duplicate work. | 2026-07-10 |
| Keep backups portable and exclude the execution queue | Restoring teaching data must not replay stale calendar operations automatically. | 2026-07-11 |
| Track four-lesson cycles without payment processing | The instructor needs operational visibility without billing or bank integrations. | 2026-07-11 |
| Persist in-lesson notes by occurrence | Live teaching notes must survive navigation and app termination until closeout succeeds. | 2026-07-11 |

Historical decisions and superseded architectures remain in [ROADMAP.md](ROADMAP.md) and the completed [phase records](phases/README.md).

---

*Last updated: 2026-07-11 for Phase 13 in-lesson draft recovery.*
