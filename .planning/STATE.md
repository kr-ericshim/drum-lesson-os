---
milestone: v1.0
milestone_name: instructor-side MVP
status: phase-14-in-progress-release-uat-pending
last_updated: "2026-07-11"
progress:
  implementation_phases: 14
  completed_phases: 13
  implementation_plans: 25
  completed_plans: 24
  implementation_percent: 100
---

# Project State

## Current Position

The instructor-side implementation is complete through Phase 13. Phase 14 is adding daily-use safety and speed features while closing the release UAT checklist.

- **Active architecture:** macOS SwiftUI, local SQLite, EventKit, durable local calendar outbox
- **Current work:** [Phase 14 plan](phases/14-daily-use-safety-and-speed/14-PLAN.md)
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
- Daily rolling backups with seven-daily and four-weekly retention plus Settings health status
- Overlap warnings with explicit override across schedule creation, editing, and drag moves
- Native roster search and attention filters
- Post-closeout lesson-summary clipboard copy
- Native source and test trees organized by app layer, with code removed from bundle resources

## Latest Recorded Verification

After Phase 14 implementation on 2026-07-11:

- `npm run verify`: 141 passed, 0 failed, 0 skipped
- `xcodebuild ... analyze`: passed
- `./script/build_and_run.sh --verify`: passed
- Disposable-path app launch and automatic-backup creation/relaunch check: passed
- `git diff --check`: passed

The [Phase 14 UAT record](phases/14-daily-use-safety-and-speed/14-UAT.md) separates this automated evidence from the remaining device-only release checks.

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

Complete the remaining device-only checks in the [Phase 14 UAT record](phases/14-daily-use-safety-and-speed/14-UAT.md).
