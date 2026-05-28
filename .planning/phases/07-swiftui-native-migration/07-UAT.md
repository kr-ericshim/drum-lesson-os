# Phase 7 UAT

**Status:** Automated preflight passed; preview Mac smoke passed; native-primary repo reorg applied; live Supabase/EventKit/iPhone UAT remains open.
**Purpose:** Record human verification for the macOS SwiftUI native migration.
**Current truth:** The native implementation candidate has been launched and checked on this Mac with preview data. Real instructor credentials, real EventKit permission, and iPhone/iCloud propagation still need a live UAT run before real daily use.

## UAT Rules

- Do not mark native release-ready from automated tests alone.
- Separate automated evidence from manual evidence.
- The legacy web runtime has been removed after Phase 7 approval; record native UAT gaps directly.
- Record exact date, machine, macOS version, Xcode version, app build identifier, Supabase target, and iPhone/iCloud account used for each live run.
- Record failures honestly as `blocked` or `failed`; do not convert them to pass because preview data worked.

## Current Run Context

| Field | Value |
|-------|-------|
| UAT run id | `phase7-preview-2026-05-28` |
| Date/time | 2026-05-28 16:51 KST |
| Tester | Codex with Computer Use |
| Native app build/commit | Uncommitted workspace candidate on `codex/phase7-swiftui-native-migration` |
| Supabase project/environment | Preview fallback for native UI; remote Supabase dry-run only |
| Project shape | Native app at repo root; legacy web runtime removed after approval |
| Apple Calendar account type | Preview calendar repository for UI smoke |
| iPhone model/iOS version | Not available in this run |

## Automated Preflight

| Command | Expected result | Status | Evidence |
|---------|-----------------|--------|----------|
| `xcodegen generate` | Native Xcode project is generated from `project.yml`. | passed | Command exited 0. |
| `xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test` | Native build and tests pass. | passed | Root-project command is the current native gate. |
| `npm test` | Native RPC SQL guard passes. | passed | `tests/native-rpc-security.test.mts` checks the Phase 7 RPC boundary. |
| `supabase db push --dry-run` | No unexpected pending migrations, or only planned Phase 7 migrations. | passed | Would push `0018_native_write_rpcs.sql` and `0019_native_eventkit_sync.sql` only. |
| Native binary secret scan | No service-role key or Apple credential appears in the built app. | passed | Debug app binary `strings` scan had no matching secret markers. |

## Native-Primary Reorg Smoke

| Step | Expected result | Status | Notes |
|------|-----------------|--------|-------|
| Root project inventory | `DrumLessonOS/`, `DrumLessonOSTests/`, `project.yml`, `supabase/`, and `tests/` are the active surfaces. | passed | Legacy `src/` and Next.js config were removed from the working tree. |
| Verification commands | Native and SQL guard commands are the active gate. | passed | `npm test`, `xcodegen generate`, root `xcodebuild`, `supabase db push --dry-run`, and `git diff --check` passed after reorg; native config cleanup was rechecked at 2026-05-28 17:17 KST. |

## Native Mac Preview Smoke

| Step | Expected result | Status | Notes |
|------|-----------------|--------|-------|
| Launch native app | App opens as a macOS SwiftUI window. | passed | Opened Debug app from DerivedData. |
| View compact dashboard | Today-first schedule and roster are readable; add lesson button does not clip. | passed | Computer Use inspected 520 px compact window. |
| Add preview lesson | Schedule sheet saves a preview occurrence and returns to dashboard. | passed | New occurrence showed `Calendar synced`. |
| Open weekly schedule mode | Schedule sheet exposes one-off and weekly modes with weekday, interval, optional end date, duration, and timezone. | passed | Computer Use verified the weekly controls. |
| Open occurrence edit | Selected lesson panel exposes edit occurrence. | passed | Computer Use verified the edit sheet with start, duration, timezone, and save controls. |
| Open add-student flow | Roster exposes add student. | passed | Computer Use verified the add-student sheet with name, profile cue, weak point, active, and create controls. |
| Start lesson from occurrence | Student flow keeps selected occurrence context. | passed | Computer Use verified occurrence time, title, sync status, and occurrence id in the lesson flow. |
| Check Settings | Calendar permission state and Sync Queue are visible. | passed | Settings showed `authorized` and `All local writes are clear.` |
| Student workflow surface | Student detail exposes edit/save paths for profile, traits, progress, assignments, notes, and next plan. | passed | Computer Use accessibility tree confirmed the edit workbench controls. |
| Icon-only labels | Compact toolbar buttons have meaningful accessibility labels. | passed | Add lesson button remained icon-only visually and exposed `Add lesson` label. |

## Live Native Mac UAT

These items remain for a live run with real credentials:

| Step | Expected result | Status | Notes |
|------|-----------------|--------|-------|
| Launch native app signed out. | Protected dashboard/student data is hidden; login is visible. | blocked_live_credentials | Needs live config and credential entry. |
| Sign in as existing instructor. | Dashboard loads instructor-owned data. | blocked_live_credentials | Not run in preview smoke. |
| Quit and reopen. | Session restores without retyping credentials. | blocked_live_credentials | Not run in preview smoke. |
| Sign out. | Protected screens are hidden again. | blocked_live_credentials | UI exists; live session behavior still needs UAT. |
| Resize to default and wide widths. | Dashboard remains readable and aligned. | partial_preview | Earlier native preview checks covered default/wide; record a formal live pass during UAT. |
| Switch Light/Dark Mode. | Text, borders, badges, and form controls remain legible. | not_run | Needs formal live pass. |
| Use keyboard navigation. | Focus order is usable and visible. | not_run | Needs formal live pass. |
| Add/edit student, trait, progress, assignment, note, next plan. | Writes persist through Supabase and refresh. | blocked_live_credentials | Implemented, preview-reachable, and covered by RPC/validation tests; live persistence still needs UAT. |
| Start lesson and save closeout. | Lesson note/next plan/assignment/progress updates persist and views agree. | blocked_live_credentials | Implemented through native RPC boundary; live persistence still needs UAT. |

## Native EventKit UAT

This section must run on a Mac with real Calendar access available.

| Step | Expected result | Status | Notes |
|------|-----------------|--------|-------|
| Request Calendar access. | macOS EventKit permission prompt appears. | blocked_live_eventkit | Adapter implemented; real prompt not exercised. |
| Deny/revoke permission. | App remains usable for Supabase schedule data and explains recovery. | blocked_live_eventkit | Failure handling is covered by automated coordinator tests. |
| Grant permission and list writable calendars. | User can choose an iCloud calendar. | blocked_live_eventkit | Requires real Calendar store. |
| Confirm no Apple ID/app-specific password prompt. | Native app uses EventKit only. | automated_passed | Native UI/settings copy and code path do not request Apple credentials. |
| Create/edit/cancel a lesson. | Supabase changes first; Apple Calendar event appears, updates, and removes/cancels. | blocked_live_eventkit | Requires live Supabase and selected calendar. |
| Inspect event notes. | Notes include `Drum Lesson OS occurrence: <uuid>`. | automated_passed | Covered by EventKit event builder tests. |
| Retry failed native calendar sync. | EventKit catches up without duplicate Supabase occurrences. | automated_passed_preview_partial | Queue/retry tests pass; live failure retry still needs UAT. |

## iPhone/iCloud UAT

This section must run on an iPhone signed into the same iCloud Calendar account.

| Step | Expected result | Status | Notes |
|------|-----------------|--------|-------|
| After Mac one-off create, open Calendar on iPhone. | Event appears after iCloud sync. | blocked_iphone | Requires paired iPhone. |
| After Mac edit, refresh/check iPhone Calendar. | Event time updates after iCloud sync. | blocked_iphone | Requires paired iPhone. |
| After Mac cancel, refresh/check iPhone Calendar. | Event disappears or shows implemented canceled state. | blocked_iphone | Requires paired iPhone. |
| Confirm event notes/title on iPhone. | Event remains identifiable as Drum Lesson OS-owned. | blocked_iphone | Requires paired iPhone. |

## UAT Result

| Gate | Status | Notes |
|------|--------|-------|
| Automated preflight | passed | Web, Supabase dry-run, native build/tests, and binary secret scan passed. |
| Native-primary reorg smoke | passed | Root native and SQL guard checks passed after reorg. |
| Native Mac workflows | passed_preview_partial | Preview UI workflows passed; live Supabase persistence remains. |
| EventKit Mac flow | automated_passed_live_blocked | Adapter tests passed; real Calendar permission/write proof remains. |
| iPhone/iCloud flow | blocked_iphone | Not available in this run. |
| Offline/retry behavior | automated_passed_preview_partial | Cached read and queue/retry tests passed; live network-toggle smoke remains. |

**Current conclusion:** Phase 7 is a verified native implementation candidate and the repo is now native-primary. Live production use still waits on Supabase, EventKit, iPhone/iCloud, and daily-use confidence gates.
