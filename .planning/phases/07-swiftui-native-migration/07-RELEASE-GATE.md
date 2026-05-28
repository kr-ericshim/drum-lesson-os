# Phase 7 Release Gate

**Status:** Implementation candidate verified, approved, and reorganized as native-primary; live production confidence remains on hold.
**Purpose:** Decide whether the macOS SwiftUI app is ready for real daily instructor use.

## Release Decision Rule

Do not rely on the native app for real teaching records until every required automated and live manual gate below is passed with current evidence. The implementation is code-complete and the legacy web runtime has been removed from active development after independent approval.

Current release decision: `native_primary_hold_for_live_uat`

## Required Automated Gates

| Gate | Command/check | Pass condition | Status | Evidence |
|------|---------------|----------------|--------|----------|
| Native RPC security guard | `npm test` | SQL guard tests pass. | passed | `tests/native-rpc-security.test.mts` checks native RPC ownership and grants. |
| Supabase migration dry-run | `supabase db push --dry-run` | No unexpected migration drift. | passed | Dry-run would push only `0018_native_write_rpcs.sql` and `0019_native_eventkit_sync.sql`. |
| Native project generation | `xcodegen generate` | Xcode project is generated from `project.yml`. | passed | Command exited 0 on 2026-05-28 17:13 KST. |
| Native tests | `xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test` | Build and all native tests pass. | passed | Root-project command passed 34 Swift tests on 2026-05-28 17:13 KST. |
| Native read-model parity | Native parity test target | Roster/detail/calendar/brief/closeout fixtures match web expectations. | passed | `ReadModelParityTests`, `WeeklyOccurrenceExpanderTests`, and domain decoding tests passed through native test run. |
| Native RPC security | SQL/test scan | Native RPCs derive instructor from `auth.uid()` and grant execute only to `authenticated`. | passed | `tests/native-rpc-security.test.mts` passed inside `npm test`. |
| Secret scan | Source and Debug app binary scan | No Supabase service-role key or Apple credential is embedded in native app. | passed | Debug binary scan had no matching secret markers. |
| Native-primary layout | File/route check | SwiftUI app is at repo root and web runtime files are absent. | passed | `DrumLessonOS/`, `DrumLessonOSTests/`, `project.yml`, `tests/`, and `supabase/` are active surfaces; `git diff --check` passed. |

## Required Manual Gates

| Gate | Pass condition | Status | Evidence |
|------|----------------|--------|----------|
| Native sign-in/session/sign-out | Existing instructor can sign in, relaunch restores session, sign-out hides protected screens. | blocked_live_credentials | Live instructor credentials were not available in this run. Preview auth and sign-out UI were smoke checked. |
| Native dashboard parity | Calendar-first dashboard, roster, selected lesson panel, and quick actions are usable. | manual_preview_passed | Computer Use verified dashboard and compact layout. Wide/default native layout was covered in earlier app run and native tests. |
| Native student workflow parity | Student add, profile, traits, progress, assignment, note, next plan, run panel, and closeout work. | manual_preview_passed | Computer Use verified add-student sheet and student detail edit workbench actions; automated validation/RPC tests cover write payloads. |
| Native scheduling parity | One-off create, weekly create, edit, cancel, and start lesson from occurrence work. | manual_preview_passed | Preview one-off create showed `Calendar synced`; Computer Use verified weekly-create mode, edit sheet, and occurrence-context lesson flow are reachable; native tests cover expansion and sync coordinator behavior. |
| EventKit permission | Calendar access uses macOS permission prompt and no Apple credential prompt. | blocked_live_eventkit | EventKit adapter implemented and tested; real OS permission prompt was not exercised. |
| EventKit failure handling | Permission denied/revoked or write failure does not corrupt Supabase schedule data. | automated_passed | Coordinator tests and retry queue behavior cover failed EventKit writes. |
| Mac Apple Calendar proof | Native-created event appears, updates, and is removed/canceled on Mac Calendar. | blocked_live_eventkit | Requires a real selected writable Calendar. |
| iPhone iCloud proof | Native-created event appears, updates, and is removed/canceled on iPhone after iCloud sync. | blocked_iphone | Requires an iPhone on the same iCloud Calendar account. |
| Offline/retry proof | Last successful dashboard/detail reads remain useful; failed EventKit writes are visible and retryable; closeout is durable only after RPC success. | automated_passed_preview_partial | Cached read tests and local queue/retry tests passed; live network toggle was not exercised. |
| Accessibility/layout proof | Compact/default/wide windows, keyboard navigation, VoiceOver labels, Light/Dark Mode, and Korean text are checked. | manual_preview_partial | Compact UI and VoiceOver labels for icon-only controls were inspected through the accessibility tree. Full keyboard/Light Mode pass remains live UAT. |

## Data And Security Gates

- Native app loads only Supabase URL and publishable/anon keys.
- Native config rejects service-role-like keys, including `service_role` JWT payloads and `sb_secret_` prefixes.
- Native write paths use authenticated SQL RPCs that derive the instructor from `auth.uid()`.
- RPC execute grants are scoped to `authenticated`.
- Signed-out native state has no instructor session and falls back to the auth root.
- Native EventKit does not read or store Apple ID, app-specific password, or CalDAV credentials.
- Phase 6 CalDAV columns and `calendar_sync_outbox` may remain in the database schema as historical/additive data, but the active app path is EventKit.
- Phase 7 native sync metadata is additive.
- EventKit identifiers are recoverable integration metadata; Supabase occurrence rows remain canonical.
- Event notes include `Drum Lesson OS occurrence: <uuid>` for app-owned recovery.

## Native-Primary Gate

The native app should be treated as production-ready only when all of these are true:

1. All automated native, SQL guard, and Supabase checks pass in the same release run.
2. Live manual Mac/EventKit/iPhone UAT is recorded in `07-UAT.md`.
3. No P0/P1 data-loss, auth, RLS, or calendar-sync issue remains open.
4. The native app has been used for real daily teaching workflow without a blocking issue.
5. README, `.planning/ROADMAP.md`, `.planning/STATE.md`, and `.planning/REQUIREMENTS.md` accurately describe the current native state.

Until then, treat live use as pending and record UAT gaps directly.

## Known Release Blockers

| Blocker | Reason |
|---------|--------|
| Live native sign-in was not exercised. | This run did not include instructor credentials for the native app. |
| Real EventKit permission and writable calendar selection were not exercised. | Preview and unit tests cannot replace the macOS privacy prompt and Calendar database. |
| iPhone iCloud propagation was not exercised. | Requires a paired iPhone on the same iCloud Calendar account. |
| Daily native use confidence has not started. | Required before relying on the app for real teaching records. |

## Current Verdict

```text
Decision: native_primary_hold_for_live_uat
Date: 2026-05-28
Release candidate commit: uncommitted workspace candidate
Automated commands:
  - xcodegen generate
  - xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
  - npm test
  - supabase db push --dry-run
Manual UAT record:
  - Computer Use compact/dashboard/settings/student workflow smoke completed on preview data.
  - Computer Use verified add-student, weekly schedule mode, occurrence edit sheet, and Start Lesson occurrence context are reachable.
Remaining risks:
  - Live Supabase sign-in, real EventKit permission/write/delete, iPhone iCloud propagation, and daily-use confidence.
Project shape:
  - Native app is primary at repo root; legacy web runtime removed.
Approver:
  - Independent agent review approved Phase 7 implementation candidate.
```
