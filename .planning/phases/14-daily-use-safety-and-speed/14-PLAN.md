# Phase 14 Plan: Daily-Use Safety And Speed

## Goal

Close the highest-value daily-use gaps before the instructor relies on Drum Lesson OS as the primary teaching record.

## Scope

- Run the release UAT checklist with disposable data and fix reproducible app defects.
- Create one automatic local backup per day, retain seven daily and four older weekly snapshots, and show backup health in Settings.
- Warn about overlapping scheduled lessons during one-off and recurring creation, occurrence editing, and drag moves while allowing an explicit override.
- Add native roster search plus needs-review, high-priority, stale-note, and missing-focus filters.
- Keep the successful closeout summary available for one-click macOS clipboard copy.

## Verification

- Focused repository, view-model, formatter, and filtering tests
- `npm run verify`
- `xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' analyze`
- `./script/build_and_run.sh --verify`
- Direct macOS UAT where the local automation surface is available
- `git diff --check`
