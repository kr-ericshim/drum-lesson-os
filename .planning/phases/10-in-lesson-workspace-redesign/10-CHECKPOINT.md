# Phase 10 In-Lesson Workspace Redesign Checkpoint

**Status:** Complete
**Completed:** 2026-07-11

## Outcome

The active lesson route is now a dedicated teaching console. It keeps the student cue, first check, live capture, review, and save flow together without mounting the normal student-management editor stack.

## Implemented

- Added a fixed session header with lesson identity, timing, and on-demand student records.
- Made the first check the strongest visual surface and removed repeated student/lesson context.
- Replaced the duplicated adaptive layout with one bounded grid that resolves to two columns wide and one column compact.
- Replaced auto-growing run-note inputs with stable-height, three-line fields to reduce scroll-layout churn while typing.
- Removed the permanently empty closeout panel; review and save appear progressively when the required capture is ready.
- Moved summary, progress, and recent notes into an on-demand side panel. Full maintenance editors remain on the normal student-detail route.
- Kept the side panel out of the main layout so opening it does not reflow the lesson canvas.
- Disabled, removed hit testing from, and hid the background workspace from accessibility while the side panel is open. The close button receives focus, Escape closes the panel, and focus returns to the student-record button.
- Preserved the existing ViewModel and repository closeout path, including occurrence identity/date, duplicate-save prevention, atomic writes, error handling, success cleanup, and next-hint semantics.

## Runtime Finding

SwiftUI's native `.inspector` triggered a repeatable AppKit `NSTrackingSeparatorToolbarItem` registration crash on macOS 15.7.7 when this route changed. The final implementation uses a focused trailing overlay panel, which preserved the desired on-demand workflow without the toolbar-separator crash or main-layout reflow.

## Verification

- Release build completed successfully through `CONFIGURATION=Release ./script/build_and_run.sh --verify`.
- The built Release bundle was launched directly and its running executable path was confirmed.
- `xcodebuild` test result: 92 passed, 0 failed, 0 skipped on macOS 15.7.7 arm64.
- `git diff --check` passed.
- Direct wide-window dark-appearance capture showed no clipping, overlap, or unnecessary full-page scroll on the active lesson route.
- Final code audit found no remaining P0/P1 performance or state-safety issue in the redesigned lesson surfaces.

## Integration Note

Project generation picked up the concurrently added `CalendarView.swift`. Its invalid mixed-width `.frame` call was corrected with the equivalent valid min/max-width overload so the full current workspace could compile. No calendar behavior was changed for Phase 10.

## Remaining Release UAT

- Direct compact-window and light-appearance captures.
- VoiceOver traversal and full keyboard-only interaction on the running app.
- Real EventKit permission, create, edit, delete, and iPhone iCloud propagation checks.

These checks remain release confidence work and do not change the completed Phase 10 implementation scope.
