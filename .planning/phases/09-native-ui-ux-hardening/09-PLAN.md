# Phase 9 Native UI/UX Hardening Plan

**Status:** Implementation verified
**Mode:** native UX hardening
**Depends on:** Phase 8

## Goal

Turn the current macOS implementation into a reliable daily teaching workbench by fixing context safety, form ergonomics, navigation continuity, compact-window priority, calendar feedback, and recurring accessibility gaps without changing the local-first product scope.

## Scope

### 09A — Context and navigation safety

- Only expose lesson capture and closeout for a selected lesson occurrence.
- Guard the closeout write path when no occurrence is present.
- Use one first-check source across dashboard, student header, and lesson flow.
- Keep the appropriate sidebar section selected on student and lesson detail routes.
- Remove the duplicate initial dashboard load.

### 09B — Modal form system

- Recompose Add Lesson, Edit Lesson Time, and Add Student into compact, content-sized Mac sheets.
- Use persistent labels, Korean date presentation, readable duration controls, and nearby primary/secondary actions.
- Hide raw time-zone editing from the default path while preserving its stored value.
- Add default/cancel keyboard actions, initial focus, inline progress, and accessible status feedback.
- Clarify one-off versus repeating schedule copy and show a plain-language repeat summary.

### 09C — Dashboard and student memory hierarchy

- Put today’s lessons first in compact windows.
- Improve compact metadata and empty-state recovery actions.
- Keep full first-check and attention meaning available to VoiceOver.
- Remove fixed-height memory-tab behavior and improve long-list readability.
- Keep lower-frequency record maintenance visually secondary with persistent field labels.

### 09D — Calendar settings and state feedback

- Load the permission, writable calendars, and selected calendar as one visible state.
- Mark the selected calendar visually and semantically.
- Surface request, load, and selection errors instead of discarding them.
- Add useful loading, empty, and queue-empty states; disable actions that cannot currently run.

### 09E — Verification and final polish

- Verify build and all native tests.
- Verify `git diff --check`.
- Inspect compact and wide layouts, one-off and repeating sheets, light and dark appearance, error/empty/loading states, and keyboard traversal.
- Re-score the five audit dimensions and document remaining lower-priority risks.

## Constraints

- Preserve existing repositories, local SQLite data semantics, EventKit write-through behavior, and MVP scope.
- Keep edits surgical inside active SwiftUI surfaces and shared visual components.
- Do not introduce student accounts, payments, attendance, reminders, AI, or media analysis.
- Preserve all unrelated changes already present in the dirty working tree.

## Verification

```text
xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' build
xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
git diff --check
```

Completed on 2026-07-11. See `09-CHECKPOINT.md` for the re-audit, command results, visual evidence, and remaining live-UAT items.
