# Phase 8 Native Workbench Design Overhaul Checkpoint

**Status:** Implemented and independently design verified.
**Date:** 2026-05-28.
**Mode:** native-polish.

## Goal

Make the macOS SwiftUI app feel like a polished instructor workbench while preserving the existing MVP data, auth, scheduling, EventKit, and Supabase behavior.

## Implementation Summary

- Added shared workbench surface roles in `AppTheme`: `canvas`, `panel`, `inspector`, `quiet`, and `editor`.
- Added reusable spacing, surface colors, border colors, `WorkbenchSurface`, and `WorkbenchHeader`.
- Refined status badges so state remains visible without overpowering primary actions.
- Reworked the dashboard so the selected/current lesson is the first decision area, with week navigation and Add Lesson in the native toolbar.
- Demoted the week grid and roster into supporting dashboard surfaces; compact windows use a today list before the selected lesson and roster.
- Strengthened the selected lesson action hierarchy: Start Lesson primary, Edit secondary, Cancel occurrence as an icon action with accessibility labels.
- Reworked student detail around a teaching sequence: student cue, First Check, Capture, Close, teaching memory, then maintenance editors.
- Moved broad maintenance editors behind disclosure rows so the page no longer opens as a six-section form wall.
- Removed implementation-facing occurrence UUID copy from the lesson context.
- Clarified Settings into Apple Calendar, Sync Queue, and Account groups.
- Polished Add Lesson, Edit Lesson Time, Add Student, and Login copy without changing write behavior.

## Verification Commands

All command checks passed on 2026-05-28:

```bash
npm test
xcodegen generate
xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
git diff --check
```

Observed results:

- `npm test`: 6 native RPC/security guard tests passed.
- `xcodegen generate`: project regenerated successfully.
- `xcodebuild ... test`: macOS test suite completed successfully.
- `git diff --check`: no whitespace errors.

## Computer Use Evidence

Native UI smoke was performed against the built macOS app at:

`/Users/ericshim/Library/Developer/Xcode/DerivedData/DrumLessonOS-fbjmgggjmgjnohdtfppbcadhteon/Build/Products/Debug/DrumLessonOS.app`

Verified surfaces:

- Dark wide dashboard: selected lesson appears as the top primary surface with Start Lesson, Edit, and Cancel occurrence actions; week grid and roster sit below as supporting surfaces.
- Dark compact dashboard: Today list appears first, followed by the selected lesson panel and roster; the seven-column grid is not forced into the compact width.
- Dark student detail: student cue appears first, First Check is the strongest lesson-flow surface, Capture and Close follow, teaching memory stays below, and maintenance editors are collapsed.
- Lesson capture flow: Covered, Observation, Practice, and Next hint fields accepted input; Prepare Closeout generated a closeout draft and exposed Save Closeout.
- Maintenance editing reachability: Profile, Trait, Progress, Assignment, Lesson Note, and Next Plan remain reachable through disclosure rows.
- Settings: Apple Calendar authorization, Request Access, Load Calendars, Sync Queue, Retry Now, Account, and Sign Out are visible and grouped.
- Sheets: Add Lesson, Edit Lesson Time, and Add Student sheets opened and retained their core controls.
- Light appearance: wide dashboard and student detail remained legible after temporarily enabling `NSRequiresAquaSystemAppearance`.
- Appearance override was removed after light-mode verification and the app was relaunched back to the default appearance.

## Independent Design Verification

The final verification agent returned `OK` after reviewing the latest implementation, checkpoint evidence, and the previously blocked surfaces.

Accepted points:

- Wide dashboard is no longer dominated by an empty seven-day grid.
- Dark dashboard, student detail, and settings evidence is present and readable.
- `08-CHECKPOINT.md` is credible enough for Phase 8 closeout.
- First Check is visually stronger than Capture and Close.
- Settings and sheets remain acceptable.
- Verification evidence is sufficient for the phase checkpoint.

## Follow-Up Polish

After a later UI review, a small follow-up polish pass tightened the app's daily-use feel without changing data, sync, auth, or repository behavior:

- Login now uses a wider native entry surface with product context and a clearer form area.
- Dashboard wide layout keeps the week schedule on the left and the selected lesson plus roster on the right, so the selected lesson no longer stretches across the whole screen.
- Empty "today" content no longer dominates wide dashboards, and compact dashboards stack today, selected lesson, and roster without forcing the week grid.
- Student detail now gives the student cue and today's check a cleaner top band, then presents First Check as the main teaching surface with Capture and Close beside or below it.
- Settings now uses a wider two-column configuration layout on desktop and a stacked layout on compact windows.
- A second review pass translated leaked auth error copy, removed repetitive empty-day labels from the week calendar, made student detail use the student name as the window title, and reduced one-off/edit/student sheet heights.
- An auth-entry follow-up removed the visible daily login gate: the root view restores the Keychain-backed Supabase session on launch, including Debug builds, shows a quiet connection-check state while restoring, and only presents a "계정 연결" form when no usable session remains.
- Settings now treats the account action as a Mac-local connection state and exposes "연결 해제" instead of a recurring login/logout mental model.

Follow-up verification:

```bash
npm test
xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' build
xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
git diff --check
```

Computer Use smoke rechecked auto-open into the dashboard with preview Keychain restore, the account connection fallback after connection release, dashboard wide, dashboard compact, student detail compact, and settings wide.

## Files Changed

- `DrumLessonOS/DesignSystem/Tokens/AppTheme.swift`
- `DrumLessonOS/DesignSystem/Components/StatusBadge.swift`
- `DrumLessonOS/Features/Auth/LoginView.swift`
- `DrumLessonOS/Features/Auth/AuthViewModel.swift`
- `DrumLessonOS/App/RootView.swift`
- `DrumLessonOS/Features/Dashboard/DashboardView.swift`
- `DrumLessonOS/Features/Dashboard/LessonEventCard.swift`
- `DrumLessonOS/Features/Dashboard/SelectedLessonPanel.swift`
- `DrumLessonOS/Features/Dashboard/TodayLessonListView.swift`
- `DrumLessonOS/Features/Dashboard/WeekCalendarView.swift`
- `DrumLessonOS/Features/LessonFlow/LessonFlowWorkspace.swift`
- `DrumLessonOS/Features/Scheduling/ScheduleLessonSheet.swift`
- `DrumLessonOS/Features/Settings/SettingsView.swift`
- `DrumLessonOS/Features/Students/AddStudentSheet.swift`
- `DrumLessonOS/Features/Students/StudentDetailTabs.swift`
- `DrumLessonOS/Features/Students/StudentDetailView.swift`
- `DrumLessonOS/Features/Students/StudentHeaderView.swift`
- `DrumLessonOS/Features/Students/StudentRosterView.swift`
- `DrumLessonOSTests/NativeSmokeTests.swift`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`

## Remaining Risks

- This phase does not prove live Supabase credentials, real EventKit write/delete behavior, or iPhone iCloud propagation.
- Phase 6B reverse sync remains deferred.
- Empty-day treatment in the week grid can be made even quieter in a future polish pass, but this is not blocking Phase 8.
