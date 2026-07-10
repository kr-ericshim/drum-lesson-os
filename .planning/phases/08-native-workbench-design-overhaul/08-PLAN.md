# Phase 8 Native Workbench Design Overhaul Plan

**Status:** Implemented and independently design verified.
**Date:** 2026-05-28.
**Mode:** native-polish.

## Goal

Make the native macOS app feel like a polished instructor workbench instead of an implementation-candidate SwiftUI port.

The Phase 8 outcome should preserve existing MVP behavior while improving:

- dashboard first impression,
- lesson/action hierarchy,
- student detail scan speed,
- editing ergonomics,
- settings clarity,
- shared visual/component vocabulary.

## Implementation Checkpoint

See [08-CHECKPOINT.md](08-CHECKPOINT.md) for implementation evidence, command verification, Computer Use screen checks, and independent design-verification approval.

## Assumptions

- The SwiftUI app remains the primary runtime.
- No Supabase schema, RPC, EventKit, or auth behavior changes are required for this phase.
- Current tests should continue to protect behavior.
- UI verification should happen in the real macOS app with Computer Use, not code inspection alone.
- Existing demo data remains sufficient for design validation unless the instructor provides richer live data.

## Success Criteria

1. Dashboard shows the current/selected lesson as the primary decision point, with week navigation and add lesson actions in a more native location.
2. Student detail makes the first teaching check and lesson-flow sequence more prominent than maintenance editing.
3. The current six-editor teaching workbench is replaced or demoted so the page no longer reads as a wall of forms.
4. Settings clarifies Calendar permission, writable calendar, sync queue, retry, and account actions.
5. `AppTheme` and design-system components define reusable surface, status, header, and action patterns.
6. Light and dark appearance both remain readable.
7. Existing native test and SQL guard commands pass.
8. Computer Use smoke verifies the main surfaces after implementation.

## Scope

Included:

- Shared design-system tokens and components.
- Dashboard layout and selected lesson presentation.
- Week/today schedule presentation.
- Roster presentation where it supports the selected lesson flow.
- Student header and lesson flow workspace.
- Student teaching memory and maintenance editor hierarchy.
- Settings surface polish.
- Copy cleanup for implementation-facing labels that appear in normal UI.
- Accessibility labels/help for icon-only controls.

Out of scope:

- Student portal.
- Payments or attendance.
- New scheduling domain behavior.
- Reverse calendar sync.
- New Supabase migrations.
- New EventKit sync semantics.
- AI/media features.
- Packaging/signing/notarization.
- Heavy animation or branded marketing visuals.

## Work Packages

### 08A: Design System Foundation

**Goal:** Create the shared visual vocabulary before screen-level work.

Likely files:

- `DrumLessonOS/DesignSystem/Tokens/AppTheme.swift`
- `DrumLessonOS/DesignSystem/Components/StatusBadge.swift`
- New files under `DrumLessonOS/DesignSystem/Components/`

Tasks:

- Add surface roles: canvas, panel, inspector, quiet, editor.
- Add spacing and corner tokens.
- Refine status badge into state-aware `StatusPill` or expand the existing `StatusBadge`.
- Add reusable `WorkbenchHeader`, `ActionBar`, and surface wrapper if useful.
- Keep implementation small; avoid a large abstract design-system layer.

Verify:

```bash
xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
```

### 08B: Dashboard Workbench Redesign

**Goal:** Make the dashboard communicate schedule, selected lesson, and next action immediately.

Likely files:

- `DrumLessonOS/Features/Dashboard/DashboardView.swift`
- `DrumLessonOS/Features/Dashboard/WeekCalendarView.swift`
- `DrumLessonOS/Features/Dashboard/LessonEventCard.swift`
- `DrumLessonOS/Features/Dashboard/SelectedLessonPanel.swift`
- `DrumLessonOS/Features/Dashboard/TodayLessonListView.swift`
- `DrumLessonOS/Features/Students/StudentRosterView.swift`

Tasks:

- Move week navigation, Today, and Add Lesson into a native toolbar if practical.
- Make the main schedule canvas and selected lesson inspector visually distinct.
- Reduce empty-grid dominance when only a few lessons exist.
- Strengthen selected lesson action hierarchy: Start Lesson primary, Edit secondary, Cancel separated.
- Make sync state legible without overpowering the teaching action.
- Preserve compact layout behavior.

Verify:

- Dashboard opens successfully.
- Previous/next week and Today still work.
- Add Lesson sheet still opens.
- Selecting a lesson updates inspector.
- Start Lesson opens the correct student/lesson context.
- Compact window remains usable.

### 08C: Student Detail And Lesson Flow Redesign

**Goal:** Make the student detail page prioritize lesson memory and in-lesson action over maintenance forms.

Likely files:

- `DrumLessonOS/Features/Students/StudentHeaderView.swift`
- `DrumLessonOS/Features/LessonFlow/LessonFlowWorkspace.swift`
- `DrumLessonOS/Features/Students/StudentDetailView.swift`
- `DrumLessonOS/Features/Students/StudentDetailTabs.swift`

Tasks:

- Tighten student header into a compact cue card.
- Redesign lesson flow as a guided sequence: Check -> Capture -> Close.
- Make First Check visibly primary.
- Keep Run Notes easy to type into.
- Make Closeout quiet until a draft exists, then clearly saveable.
- Move broad editing below memory or behind disclosure/segmented editing.
- Keep save actions local and clear.

Verify:

- Student detail loads.
- Run note fields accept typing.
- Prepare/use closeout still fills the draft.
- Save closeout still routes through the existing write path.
- Profile/trait/progress/assignment/note/next-plan edit actions remain reachable.

### 08D: Settings And Sheet Polish

**Goal:** Make configuration and modal tasks feel native, clear, and less implementation-exposed.

Likely files:

- `DrumLessonOS/Features/Settings/SettingsView.swift`
- `DrumLessonOS/Features/Scheduling/ScheduleLessonSheet.swift`
- `DrumLessonOS/Features/Students/AddStudentSheet.swift`
- `DrumLessonOS/Features/Auth/LoginView.swift`

Tasks:

- Refine settings grouping.
- Clarify calendar permission and sync queue status.
- Separate sign out from operational sync actions.
- Remove or soften implementation-facing copy in normal user flows.
- Keep forms native and simple.

Verify:

- Settings opens.
- Request Access and Load Calendars controls remain present.
- Retry Now remains present.
- Sign Out remains present and visually separated.
- Add Lesson, Edit Occurrence, Add Student sheets remain reachable and compile.

### 08E: Visual QA And Release Evidence

**Goal:** Close Phase 8 with evidence, not subjective confidence.

Tasks:

- Run native tests and SQL guard tests.
- Build and launch the app.
- Computer Use smoke:
  - Dashboard wide window.
  - Dashboard compact/minimum window.
  - Student detail top.
  - Student detail maintenance editing reachable.
  - Settings.
  - Add Lesson sheet.
  - Edit Occurrence sheet.
  - Add Student sheet.
- Check light and dark appearance manually if available.
- Update a Phase 8 checkpoint document after implementation.

Verification bundle:

```bash
npm test
xcodegen generate
xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
git diff --check
```

Manual proof:

- Computer Use screenshots or state summaries for the surfaces above.

## Suggested Implementation Order

1. 08A design-system foundation.
2. 08B dashboard.
3. 08C student detail.
4. 08D settings/sheets.
5. 08E verification and checkpoint.

Do not start by restyling every file. Start with shared roles and one screen, then propagate only proven patterns.

## Risks

| Risk | Mitigation |
|------|------------|
| Overdesign fights native macOS | Keep native controls and system-adaptive colors as the base. |
| Scope expands into behavior changes | Treat repositories, RPCs, migrations, and EventKit semantics as out of scope. |
| Form wall gets hidden too aggressively | Keep every existing edit action reachable and verify through Computer Use. |
| Dark-mode fixes break light mode | Check both appearances before closeout. |
| Layout improves on wide screen but regresses compact window | Verify at the app's minimum width and at a wide desktop width. |

## Files To Touch Carefully

- `DrumLessonOS/DesignSystem/Tokens/AppTheme.swift`
- `DrumLessonOS/DesignSystem/Components/StatusBadge.swift`
- `DrumLessonOS/Features/Dashboard/*`
- `DrumLessonOS/Features/Students/*`
- `DrumLessonOS/Features/LessonFlow/LessonFlowWorkspace.swift`
- `DrumLessonOS/Features/Settings/SettingsView.swift`
- `DrumLessonOS/Features/Scheduling/ScheduleLessonSheet.swift`
- `DrumLessonOS/Features/Auth/LoginView.swift`

Avoid unrelated formatting and broad refactors.

## Checkpoint To Create After Implementation

Create:

- `.planning/phases/08-native-workbench-design-overhaul/08-CHECKPOINT.md`

It should include:

- before/after summary,
- changed files,
- behavior kept,
- verification commands,
- Computer Use evidence,
- known remaining polish items.
