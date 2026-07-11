# Roadmap: Drum Lesson OS

## Status

Phases 1 through 14 are complete. Device-only release UAT is explicitly deferred until Computer Use is working again, as recorded in [STATE.md](STATE.md).

The active product is native-first and local-first. SQLite is canonical, EventKit is the Apple Calendar boundary, and hosted authentication is not part of the running app.

## Phase Summary

| Phase | Outcome | Status | Record |
|------:|---------|--------|--------|
| 1 | Initial app foundation and data model | Complete; original web implementation is historical | [Phase 1](phases/01-app-foundation-and-data-model/) |
| 2 | Student roster and detail read views | Complete; original web implementation is historical | [Phase 2](phases/02-student-roster-and-detail-read-views/) |
| 3 | Teaching workflow editing | Complete; original web implementation is historical | [Phase 3 records](phases/README.md#phase-3) |
| 4 | Instructor workbench polish | Complete; original web implementation is historical | [Phase 4 records](phases/README.md#phase-4) |
| 5 | Lesson-flow operating board | Complete; behavior carried into native app | [Phase 5](phases/05-lesson-flow-operating-board/) |
| 6A | Calendar-first scheduling and Apple Calendar sync | Complete | [Phase 6](phases/06-calendar-apple-sync/) |
| 6B | Optional reverse sync for app-created Apple events | Deferred | [Requirements](REQUIREMENTS.md#calendar-scheduling-and-apple-sync) |
| 7 | SwiftUI native migration and native-primary repo layout | Complete; hosted Supabase stage is historical | [Phase 7](phases/07-swiftui-native-migration/) |
| 8 | Native workbench design overhaul | Complete | [Phase 8](phases/08-native-workbench-design-overhaul/) |
| 9 | Native UI/UX hardening | Complete; direct accessibility UAT remains | [Phase 9](phases/09-native-ui-ux-hardening/) |
| 10 | In-lesson workspace redesign | Complete; direct accessibility UAT remains | [Phase 10](phases/10-in-lesson-workspace-redesign/) |
| 11 | Local backup and progress history | Complete; native file-panel UAT remains | [Phase 11](phases/11-local-backup-and-progress-history/) |
| 12 | Prepaid four-lesson tuition management | Complete | [Phase 12](phases/12-prepaid-tuition-management/) |
| 13 | In-lesson draft autosave and recovery | Complete | [Phase 13](phases/13-in-lesson-draft-recovery/) |
| 14 | Daily-use safety and speed | Complete; direct UAT deferred | [Phase 14](phases/14-daily-use-safety-and-speed/) |

## Architecture Transitions

### Initial web implementation

Phases 1 through 6 were first implemented in a Next.js and Supabase-oriented project. Those documents preserve product and workflow decisions, but their framework, authentication, routing, and persistence instructions are no longer active.

### Native migration

Phase 7 moved the product into macOS SwiftUI and EventKit. Some Phase 7 records describe an intermediate native client backed by Supabase; that stage was later superseded.

### Local-first cutover

On 2026-07-10, local SQLite became canonical, hosted authentication was removed from the active app, and EventKit retry work moved to a durable local outbox. Phases 9 through 12 and the current research documents describe this active architecture.

## Deferred Direct Validation

The operator deferred the following checks on 2026-07-11 until Computer Use is working again. Before relying on the app as the only teaching record:

1. Complete native backup save/open panel testing with disposable data.
2. Complete light mode, keyboard, and VoiceOver checks.
3. Verify real EventKit create, edit, cancel, delete, and retry behavior.
4. Confirm iPhone iCloud propagation.
5. Re-run `npm run verify` and `git diff --check` after any resulting fixes.

## Future Scope

Phase 14 covers release UAT, rolling local backup, overlap warnings, native roster search and filters, and post-closeout summary copy. Current exclusions include student accounts, payment processing, hosted sync, non-Apple calendars, and audio/video analysis.
