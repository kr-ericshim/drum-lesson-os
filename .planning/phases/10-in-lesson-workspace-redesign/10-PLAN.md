# Phase 10 In-Lesson Workspace Redesign Plan

**Status:** Complete
**Mode:** focused native redesign
**Depends on:** Phase 9

## Goal

Turn the active lesson route into a calm, responsive teaching console that prioritizes the first check, live capture, and closeout while preserving every existing write and data invariant.

## Observed Problems

- The active lesson route mounts the student header, lesson workspace, history tabs, and all six maintenance editors in one eager scroll hierarchy.
- Student identity and first-check context repeat across multiple equally weighted surfaces.
- The adaptive layout duplicates the interactive run and closeout subtree for measurement.
- Auto-growing note fields can change the height of a long scroll hierarchy while typing.
- A permanently visible empty closeout surface adds scroll length before it offers an action.

## Implementation

1. Branch active lessons from normal student detail so only session-relevant UI is mounted.
2. Add a fixed compact session header and a single adaptive lesson canvas.
3. Keep the first check visually dominant, use stable-height labeled note fields, and reveal closeout review only when prepared.
4. Expose student history on demand through a focused side panel; keep maintenance editors only in normal student detail.
5. Preserve current ViewModel state, occurrence identity/date, validation, atomic repository closeout, and success/error behavior.

## Touched Files

- `DrumLessonOS/Features/Students/StudentDetailView.swift`
- `DrumLessonOS/Features/Students/StudentDetailTabs.swift`
- `DrumLessonOS/Features/LessonFlow/LessonFlowWorkspace.swift`
- `DrumLessonOS/DesignSystem/Tokens/AppTheme.swift` only if a focused session surface token is required
- Relevant tests only when a behavior seam changes

## Verification

```text
xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' build
xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' -derivedDataPath /tmp/DrumLessonOS-lesson-redesign CODE_SIGN_STYLE=Manual 'CODE_SIGN_IDENTITY=-' DEVELOPMENT_TEAM= test
git diff --check
```

Visual checks: wide and compact windows, light and dark appearance, first/middle/bottom scroll positions, note entry, review, saving, error, success, student-record panel open/closed, keyboard focus, and VoiceOver labels.

## Result

Implemented and verified on 2026-07-11. See `10-CHECKPOINT.md` for evidence and remaining release UAT.
