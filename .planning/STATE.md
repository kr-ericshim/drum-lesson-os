---
milestone: v1.0
milestone_name: instructor-side MVP
status: implementation-complete-release-uat-pending
last_updated: "2026-07-11"
progress:
  implementation_phases: 13
  completed_phases: 13
  implementation_plans: 24
  completed_plans: 24
  implementation_percent: 100
---

# Project State

## Current Position

The instructor-side implementation is complete through Phase 13. Release confidence remains pending until direct native and real-calendar UAT is complete.

- **Active architecture:** macOS SwiftUI, local SQLite, EventKit, durable local calendar outbox
- **Current checkpoint:** [Phase 13 checkpoint](phases/13-in-lesson-draft-recovery/13-CHECKPOINT.md)
- **Product definition:** [PROJECT.md](PROJECT.md)
- **Requirement status:** [REQUIREMENTS.md](REQUIREMENTS.md)
- **Phase history:** [ROADMAP.md](ROADMAP.md)

## Completed Implementation

- Student roster, detail, traits, progress, notes, assignments, and next plans
- Calendar-first scheduling, recurring occurrences, and lesson closeout
- EventKit create, update, delete, retry visibility, and durable recovery logic
- Responsive native lesson workspace and accessibility-oriented UI hardening
- Versioned local backup and restore with pre-restore safety backup
- Append-only progress checkpoints
- Manual prepaid four-lesson tuition-cycle tracking
- Occurrence-scoped in-lesson draft autosave, recovery, and backup support
- Native source and test trees organized by app layer, with code removed from bundle resources

## Latest Recorded Verification

After Phase 13 on 2026-07-11:

- `npm run verify`: 130 passed, 0 failed, 0 skipped
- `xcodebuild ... analyze`: passed
- Release build and launch verification: passed
- `git diff --check`: passed

The [Phase 13 checkpoint](phases/13-in-lesson-draft-recovery/13-CHECKPOINT.md) records the draft-recovery implementation and verification evidence. Run the repository verification commands again after new implementation changes.

## Release-Confidence Work Remaining

- Exercise backup export and restore through native save/open panels using disposable data.
- Check light mode, keyboard traversal, and VoiceOver on the main workflows.
- Verify real EventKit permission, create, edit, cancel, delete, and retry behavior.
- Confirm propagation to an iPhone using the same iCloud account.
- Establish confidence with real daily teaching data before treating the app as the only record.

## Deferred

- `CAL-10` optional reverse sync from Apple Calendar remains intentionally deferred.
- Student accounts, hosted sync, payment processing, and non-Apple calendars remain outside v1.

## Resume Point

Return to the release-confidence checklist above, beginning with disposable-data backup panel UAT.
