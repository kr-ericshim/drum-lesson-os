# Current Product And Technical Summary

Drum Lesson OS is an instructor-side macOS workbench for remembering student context and running the lesson loop from preparation through closeout.

## Product Center

- Calendar-first view of teaching work
- Student roster and lesson-relevant profile
- Flexible progress, traits, assignments, and notes
- First action and next-lesson preparation
- In-lesson working notes and durable closeout
- Append-only progress observations
- Manual prepaid four-lesson cycle visibility

## Technical Center

- SwiftUI and Swift 6.2
- XcodeGen project generation
- Local SQLite as canonical persistence
- EventKit write-through for Apple Calendar
- Durable local outbox for calendar recovery
- Versioned local backup and restore
- Swift Testing for domain, persistence, sync, and view-model behavior

## Scope Boundary

The app does not currently include student accounts, hosted sync, bank or payment processing, attendance, external booking, non-Apple calendars, AI summaries, or audio/video analysis.

## Remaining Confidence Work

Implementation is complete through Phase 12. Native backup panels, broader accessibility checks, real EventKit behavior, iPhone iCloud propagation, and daily-use confidence still require direct UAT.

See [../STATE.md](../STATE.md) for the current status and [ARCHITECTURE.md](ARCHITECTURE.md) for component ownership.
