# Phase 12 Plan: Prepaid Tuition Management

## Goal

Add a dedicated macOS tuition workspace that lets the instructor scan each active student's four-lesson cycle, record prepaid tuition confirmation manually, and keep lesson progress aligned with successful lesson closeouts.

## Product Rules

- Tuition is normally prepaid for a four-lesson cycle.
- Only an occurrence completed through the existing atomic lesson closeout advances the cycle.
- Manual lesson notes, canceled occurrences, and merely elapsed schedules do not advance tuition progress.
- Payment confirmation is manual and stores the confirmation date; no bank connection, amount, invoice, or payment processing is included.
- Existing students show `설정 필요` until the instructor sets their current cycle once. New students start at `0/4` with payment unconfirmed.
- Completing `4/4` keeps that cycle visible until the instructor starts the next four lessons. If another lesson is closed out first, the app creates the next cycle automatically at `1/4` and flags payment as unconfirmed.
- Earlier unpaid cycles remain visible as outstanding after a new cycle begins.

## Implementation

1. Add persisted tuition-cycle models, validation, repository APIs, legacy snapshot decoding, and version-2 backup validation.
2. Advance the configured cycle in the same transaction as successful lesson closeout and align preview behavior with the local repository.
3. Add an environment-owned tuition view model and a `수강비` sidebar destination with wide and compact native SwiftUI layouts.
4. Add setup, payment-confirmation, correction, and next-cycle flows without adding billing or bank abstractions.
5. Cover persistence, duplicate-closeout safety, rollover, legacy decoding, backup compatibility, and route selection with native tests.

## Expected Files

- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `DrumLessonOS/App/AppRoute.swift`
- `DrumLessonOS/App/RootView.swift`
- `DrumLessonOS/App/AppEnvironment.swift`
- `DrumLessonOS/Domain/Models/TuitionModels.swift`
- `DrumLessonOS/Domain/Repositories/TuitionRepository.swift`
- `DrumLessonOS/Domain/Validation/TuitionValidation.swift`
- `DrumLessonOS/Data/Local/LocalSQLiteRepository.swift`
- `DrumLessonOS/Resources/PreviewData/PreviewRepository.swift`
- `DrumLessonOS/Features/Tuition/TuitionViewModel.swift`
- `DrumLessonOS/Features/Tuition/TuitionView.swift`
- `DrumLessonOSTests/LocalSQLiteRepositoryTests.swift`
- `DrumLessonOSTests/NativeSmokeTests.swift`

## Verification

1. `npm run verify`
2. `xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' analyze`
3. `CONFIGURATION=Release ./script/build_and_run.sh --verify`
4. `git diff --check`
