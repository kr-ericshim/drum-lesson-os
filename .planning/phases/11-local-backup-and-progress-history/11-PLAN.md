# Phase 11: Local Backup And Progress History

**Goal:** Protect the local teaching record and preserve append-only progress observations without expanding beyond the instructor-side CRM.

## Scope

1. Export the canonical local snapshot as a versioned Drum Lesson OS backup file.
2. Validate a selected backup before restore and create an automatic pre-restore safety backup.
3. Exclude the EventKit write queue from portable backups. Restored pending calendar work must require explicit manual retry instead of running automatically.
4. Add append-only progress checkpoints linked to an existing progress item.
5. Capture checkpoint date, optional BPM, current progress status, and a short observation.
6. Add quick checkpoint capture to the active lesson workspace and show checkpoint history in the student progress tab.

## Success Criteria

1. Backup and restore preserve students, lesson notes, plans, schedules, and progress checkpoints.
2. Invalid or unsupported backup files do not modify the current database.
3. Restore creates a readable pre-restore backup before replacing the snapshot.
4. Restored pending EventKit work is not automatically replayed.
5. Adding a checkpoint never overwrites an earlier checkpoint or the linked progress item.
6. Legacy snapshots without checkpoint data still decode.
7. `npm run verify` and `git diff --check` pass.

## Files Expected To Change

- `DrumLessonOS/Domain/Models/DomainModels.swift`
- `DrumLessonOS/Domain/ReadModels/ReadModels.swift`
- `DrumLessonOS/Domain/ReadModels/ReadModelMappers.swift`
- `DrumLessonOS/Domain/Repositories/Repositories.swift`
- `DrumLessonOS/Domain/Validation/StudentEditingValidation.swift`
- `DrumLessonOS/Data/Local/LocalSQLiteRepository.swift`
- `DrumLessonOS/Resources/PreviewData/PreviewRepository.swift`
- `DrumLessonOS/App/AppEnvironment.swift`
- `DrumLessonOS/App/RootView.swift`
- `DrumLessonOS/Features/Settings/SettingsView.swift`
- `DrumLessonOS/Features/LessonFlow/LessonFlowWorkspace.swift`
- `DrumLessonOS/Features/Students/StudentDetailTabs.swift`
- `DrumLessonOS/Features/Students/StudentDetailViewModel.swift`
- `DrumLessonOSTests/`
