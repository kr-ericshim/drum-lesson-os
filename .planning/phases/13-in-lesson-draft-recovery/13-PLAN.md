# Phase 13 Plan: In-Lesson Draft Recovery

## Goal

Prevent live lesson notes from being lost when the instructor leaves the lesson workspace or the app terminates before closeout.

## Behavior

- Keep one persisted draft per scheduled lesson occurrence.
- Save changed working notes after a 0.75-second debounce and show saving, saved-time, or failure feedback.
- On re-entry, require an explicit choice to continue the recovered draft or delete it before editing.
- Delete the persisted draft in the same local snapshot transaction as successful closeout.
- Include drafts in portable backup format version 3 while decoding version 1 and 2 data with an empty draft collection.

## Implementation

1. Add the draft model, repository contract, snapshot persistence, backup validation, and preview parity.
2. Add view-model debounce, recovery, deletion, and closeout cleanup behavior.
3. Add a compact recovery banner and autosave status to the active lesson workspace.
4. Cover repository, backup, view-model, and closeout behavior with regression tests.

## Verification

- `npm run verify`
- `xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' analyze`
- `git diff --check`
