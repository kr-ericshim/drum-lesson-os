# Active Architecture

## System Boundary

Drum Lesson OS is a single-process macOS application. Local SQLite owns teaching data. EventKit receives app-owned calendar writes but does not replace the local schedule model.

## Composition

`AppEnvironment` constructs and owns the main dependencies:

- `LocalSQLiteRepository` for students, notes, progress, schedules, closeout, backup data, and tuition cycles
- `CalendarBackedScheduleRepository` for coordinated local schedule and calendar work
- `EventKitCalendarRepository` for the native Apple Calendar boundary
- `LocalWriteQueue` and `RetryScheduler` for durable calendar recovery
- View models for dashboard, sync status, tuition, and student workflows

Repository protocols keep domain behavior testable with `Data/Preview/PreviewRepository` and `PreviewCalendarRepository`.

## Data Flow

### Local teaching writes

1. A SwiftUI feature validates user input.
2. The relevant repository method updates the canonical local snapshot in a SQLite transaction.
3. View models reload read models from the repository.

### Scheduled calendar writes

1. The app saves the lesson occurrence locally.
2. Calendar work is recorded in the durable outbox.
3. EventKit create, update, or delete is attempted.
4. Success metadata or visible failure state is saved locally.
5. Pending work can retry after launch or from the UI.

### Backup and restore

1. Export wraps the canonical teaching snapshot in a versioned backup envelope.
2. Restore validates the entire backup before database mutation.
3. A pre-restore safety backup is created.
4. Portable backups exclude the EventKit execution queue.
5. Restored pending calendar states require explicit retry.

## Ownership Rules

- SQLite is canonical for students, schedules, teaching history, and tuition cycles.
- EventKit identifiers are synchronization metadata attached to local occurrences.
- In-lesson working notes remain session-local until closeout.
- Closeout is the durable path for lesson completion and tuition-cycle advancement.
- Progress checkpoints append history and never replace earlier observations.

## Active Surfaces

- `project.yml`
- `DrumLessonOS/App/`
- `DrumLessonOS/Domain/`
- `DrumLessonOS/Data/`
- `DrumLessonOS/Features/`
- `DrumLessonOS/DesignSystem/`
- `DrumLessonOS/Resources/`
- `DrumLessonOSTests/`

The test target mirrors the app's top-level layers so new regression coverage lives beside the architecture area it verifies. `Resources/` contains bundle assets only; Swift preview and fixture code belongs under `Data/Preview/`.

Historical phase documents may describe browser routing, Supabase RPCs, RLS, hosted sessions, or Keychain authentication. Those mechanisms are not part of the active architecture.
