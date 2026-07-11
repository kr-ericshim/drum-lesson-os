# Phase 13 Checkpoint: In-Lesson Draft Recovery

## Outcome

Phase 13 is implemented and verified. Working notes now survive lesson navigation and app relaunch until the instructor either deletes the recovered draft or completes lesson closeout.

## Implemented Behavior

- Each scheduled occurrence owns at most one draft containing progress, observation, practice, and next-check text.
- Editing schedules a 0.75-second debounced save and the workspace shows pending, saving, saved-time, and failure feedback.
- Leaving the lesson workspace flushes pending input immediately.
- Re-entry shows an explicit recovery banner and keeps the editor disabled until `이어서 작성` or `초안 삭제` is chosen.
- Successful closeout completes the occurrence and removes its draft in the same SQLite snapshot transaction.

## Persistence And Compatibility

- Drafts are stored in the canonical `LocalAppSnapshot` and persist across repository instances.
- Portable backup format version 3 includes unfinished drafts.
- Version-1 and version-2 backups decode without draft data, preserving their existing student and tuition behavior.
- Backup restore rejects duplicate, missing-occurrence, cross-student, and completed-occurrence draft links.

## Verification

- `npm run verify`: 130 passed, 0 failed, 0 skipped.
- `xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' analyze`: passed.
- `./script/build_and_run.sh --verify`: Debug build and safe preview launch passed.
- `git diff --check`: passed.

## Remaining Release UAT

Direct backup file-panel proof, broader light/keyboard/VoiceOver checks, real EventKit behavior, and iPhone iCloud propagation remain release-confidence work outside Phase 13.
