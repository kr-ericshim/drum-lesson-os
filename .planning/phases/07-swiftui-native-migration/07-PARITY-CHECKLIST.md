# Phase 7 Parity Checklist

**Status:** Native implementation candidate with automated parity passed, independent approval received, and native-primary repo layout applied. Live release parity is blocked only by external UAT inputs.
**Purpose:** Track whether the SwiftUI app matches the current web MVP before cutover.

## Completion Rule

Each item uses one of these statuses: `automated_passed`, `manual_preview_passed`, `manual_live_passed`, `blocked_live_credentials`, `blocked_live_eventkit`, `blocked_iphone`, `deferred`, or `out_of_scope`.

A native workflow can be considered implementation-ready when native behavior has automated or preview evidence. Live use still requires Supabase/EventKit/iPhone evidence.

## Native-Primary Structure

| Check | Evidence type | Status | Notes |
|-------|---------------|--------|-------|
| SwiftUI app source is at repo root. | File review | automated_passed | `DrumLessonOS/`, `DrumLessonOSTests/`, `project.yml`, and `DrumLessonOS.xcodeproj` are root-level. |
| Legacy web runtime is removed from active development. | File review | automated_passed | `src/` and Next.js config/dependency files were removed. |
| Native checks are the active verification surface. | Automated | automated_passed | `npm test`, `xcodegen generate`, root `xcodebuild`, and `supabase db push --dry-run` form the current gate. |
| Supabase schema remains canonical. | Code review + SQL guard | automated_passed | Migrations and native RPC security tests remain under `supabase/` and `tests/`. |

## Native Foundation

| Check | Evidence type | Status | Notes |
|-------|---------------|--------|-------|
| Xcode project builds and tests. | Automated | automated_passed | `xcodegen generate` and `xcodebuild ... test` passed. |
| Native app launches to an auth-aware root view. | Manual preview | manual_preview_passed | Preview fallback opens the native dashboard; auth root is implemented for live config. |
| Native configuration excludes secrets from git and binary. | Code review + scan | automated_passed | Publishable-key validation rejects service-role keys; source/binary secret scans passed. |
| Native app keeps module boundaries. | Code review | automated_passed | App, Domain, Data, Features, DesignSystem, and Tests are separated under the root SwiftUI project. |

## Auth And RLS

| Web contract | Native parity requirement | Evidence type | Status |
|--------------|---------------------------|---------------|--------|
| Email/password sign-in and sign-out. | Native sign-in, session restore, sign-out. | Automated + live Mac | blocked_live_credentials |
| Password recovery flow exists. | Native opens Supabase recovery flow in system browser. | Code + live Mac | blocked_live_credentials |
| Signed-out users cannot read instructor/student data. | Native unauthenticated reads fail cleanly. | Automated | automated_passed |
| Owner-scoped RLS uses `auth.uid()` to instructor mapping. | Native reads and RPC writes derive instructor from authenticated user. | SQL/RPC tests | automated_passed |

## Dashboard And Roster

| Web contract | Native parity requirement | Evidence type | Status |
|--------------|---------------------------|---------------|--------|
| Dashboard opens calendar-first. | Native first screen shows today/current week before roster. | Manual preview | manual_preview_passed |
| Week navigation: previous, Today, next. | Native week controls produce matching visible dates. | Automated + preview | automated_passed |
| Today-first compact layout. | Compact macOS window remains readable around 430-520 px width. | Manual preview | manual_preview_passed |
| Roster shows active students and summary fields. | Native roster shows student scan context. | Automated + preview | manual_preview_passed |
| Roster filters. | Needs review, high priority, no recent note, missing focus behavior remains covered by native read-model parity. | Automated | automated_passed |
| Dashboard quick actions. | Equivalent native write paths exist through RPCs and student detail/lesson flow. | Automated + preview | automated_passed |

## Student Detail And Lesson Flow

| Web contract | Native parity requirement | Evidence type | Status |
|--------------|---------------------------|---------------|--------|
| Student detail opens by id/slug. | Native navigation opens detail from roster and calendar. | Manual preview | manual_preview_passed |
| Header shows profile cue, current focus, weak point, next action. | Native header maps the same read model. | Automated + preview | automated_passed |
| Summary, Progress, Notes tabs. | Native detail exposes equivalent sections. | Manual preview | manual_preview_passed |
| Recent notes newest first. | Native ordering matches web read-model tests. | Automated | automated_passed |
| Lesson Brief first-check contract. | Native first check, weak point, latest observation, assignment cue, next action match web fixtures. | Automated | automated_passed |
| Run Panel session-local notes. | Native in-lesson notes stay local until closeout. | Code + preview | manual_preview_passed |
| `Use in closeout`. | Native closeout draft receives lesson-run notes. | Automated | automated_passed |
| Durable closeout save. | Native calls authenticated RPC and refreshes state. | Automated + live Mac | automated_passed |

## Editing Workflows

| Web contract | Native parity requirement | Evidence type | Status |
|--------------|---------------------------|---------------|--------|
| Add student. | Native validates and creates student under current instructor. | RPC tests + preview | manual_preview_passed |
| Edit student profile. | Native updates name/profile cue/primary weak point/active state. | RPC tests + preview | manual_preview_passed |
| Add/update trait. | Native supports all `studentTraitTypes`. | Validation + preview | manual_preview_passed |
| Add/update progress item. | Native supports categories, statuses, notes, observed date, current focus. | Validation + preview | manual_preview_passed |
| Quick progress status transition. | Native enforces allowed status transitions. | Validation | automated_passed |
| Tempo checkpoint. | Native preserves Phase 4B tempo note behavior in models/validation. | Validation | automated_passed |
| Assignment create/update. | Native supports status, due date, and detail. | Validation + preview | manual_preview_passed |
| Lesson note creation. | Native creates dated notes with web fields. | Validation + preview | manual_preview_passed |
| Next lesson update. | Native updates priority, planned date, next action, and detail. | Validation + preview | manual_preview_passed |

## Scheduling And Calendar

| Web contract | Native parity requirement | Evidence type | Status |
|--------------|---------------------------|---------------|--------|
| One-off occurrence create. | Supabase occurrence is saved first; EventKit write follows. | Automated + preview | manual_preview_passed |
| Weekly template create. | Native expands weekly occurrences with same timezone behavior as web and exposes weekly creation UI. | Automated + preview | manual_preview_passed |
| Occurrence edit. | Supabase time/duration update occurs before EventKit update/recreate and edit UI is reachable. | Automated + preview | manual_preview_passed |
| Occurrence cancel. | Supabase status becomes `canceled`; EventKit event is removed or cleared. | Automated | automated_passed |
| Start lesson from occurrence. | Native opens student lesson flow with occurrence time, title, sync status, and occurrence id context. | Manual preview | manual_preview_passed |
| Sync status display. | Native shows not connected, pending, synced, failed, disabled. | Automated + preview | manual_preview_passed |
| Retry failed sync. | Native retry does not duplicate Supabase occurrence or lose EventKit marker. | Automated | automated_passed |
| Apple credential failures do not corrupt schedule data. | EventKit failure leaves Supabase canonical state intact. | Automated | automated_passed |
| iPhone calendar visibility. | Event appears/updates/removes on iPhone after iCloud sync. | Manual iPhone | blocked_iphone |

## EventKit Replacement For CalDAV

| Check | Evidence type | Status | Notes |
|-------|---------------|--------|-------|
| Native app requests macOS Calendar permission through EventKit. | Code + live Mac | blocked_live_eventkit | Adapter exists; real OS prompt still needs live UAT. |
| Instructor chooses a writable calendar. | Code + live Mac | blocked_live_eventkit | Adapter exists; real Calendar store still needs live UAT. |
| Event notes include `Drum Lesson OS occurrence: <uuid>`. | Automated builder test | automated_passed | Covered by native EventKit builder tests. |
| Native EventKit identifiers are saved to native sync fields. | SQL/RPC + coordinator tests | automated_passed | `native_update_occurrence_calendar_sync` and coordinator update paths are implemented. |
| Calendar permission denied/revoked state is recoverable. | Automated + live Mac | automated_passed | Failure paths are tested; real permission revocation remains UAT. |

## Accessibility And Layout

| Check | Evidence type | Status |
|-------|---------------|--------|
| Compact, default, and wide macOS windows remain readable. | Manual preview | manual_preview_passed |
| Korean seeded content does not clip in cards, buttons, tabs, or sheets. | Manual preview | manual_preview_passed |
| Keyboard navigation reaches dashboard, roster, detail, forms, and destructive confirmations. | Manual live | blocked_live_credentials |
| Icon-only controls have VoiceOver labels. | Accessibility tree | manual_preview_passed |
| Light Mode and Dark Mode both remain usable. | Manual live | blocked_live_credentials |
| Destructive actions use confirmations. | Code review + live | automated_passed |
| Add/Edit sheets can be dismissed without saving. | Manual preview | manual_preview_passed |

## Deferred Or Explicitly Out Of Scope

| Item | Status | Reason |
|------|--------|--------|
| Student portal/login. | out_of_scope | Excluded from current product direction. |
| Payments, attendance, reminders, external booking. | out_of_scope | Excluded from current product direction. |
| Google/Outlook Calendar. | out_of_scope | Phase 7 targets native Apple Calendar only. |
| Full bidirectional calendar sync. | deferred | `CAL-10` remains deferred unless explicitly promoted later. |
| AI summaries or audio/video analysis. | out_of_scope | Excluded from MVP scope. |

## Parity Conclusion

Native implementation parity was strong enough for independent code-review approval as a Phase 7 implementation candidate. The repo is now native-primary. Live use remains blocked by instructor credentials, real EventKit Calendar proof, iPhone/iCloud proof, and daily-use confidence.
