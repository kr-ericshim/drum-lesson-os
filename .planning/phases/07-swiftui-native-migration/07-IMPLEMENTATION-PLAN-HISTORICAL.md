# Phase 7 SwiftUI Native Migration Plan

> **Post-approval update (2026-05-28):** This plan was executed and then superseded by the native-primary reorganization in `07-NATIVE-PRIMARY-REORG.md`. Current paths are `DrumLessonOS/`, `DrumLessonOSTests/`, `project.yml`, `DrumLessonOS.xcodeproj`, `supabase/`, and `tests/`. Historical references to `native/DrumLessonOS`, `src/`, Next.js, or web fallback describe the migration period only.

> **For agentic workers:** Phase 7 implementation work is complete. For follow-up changes, use the native-primary layout above and the verification commands in `07-NATIVE-PRIMARY-REORG.md`.

**Goal:** Rebuild Drum Lesson OS as a complete macOS SwiftUI app that preserves the current instructor-side MVP behavior and replaces CalDAV password-based Apple Calendar sync with native EventKit calendar access.

**Architecture:** The native app owns the user experience, state, and EventKit integration. Supabase remains the remote source of truth for instructor/student/lesson data, while EventKit writes app-owned lesson occurrences into the user's selected iCloud calendar without storing Apple credentials. Native writes use authenticated Supabase RPCs and RLS-safe table reads; the service-role key stays server-only and is never embedded in the app.

**Tech Stack:** Swift 6.2.3, Xcode 26.2, SwiftUI, Observation, EventKit, Swift Testing, Supabase Swift client, Keychain Services, Supabase/Postgres, existing SQL migrations through `0017_calendar_outbox_invariants.sql`, macOS native Calendar privacy entitlements.

---

## Product Decision

Move Drum Lesson OS from a web-first MVP to a macOS-first native app. The native app should feel like a focused teacher workbench: calendar first, fast to scan, comfortable during lessons, and tightly integrated with Apple Calendar.

The migration does not expand product scope. It moves the existing scope into SwiftUI:

- instructor authentication
- calendar-first dashboard
- student roster
- student detail
- progress items
- traits
- assignments
- lesson notes
- next lesson plans
- lesson brief
- in-lesson run panel
- closeout
- schedule occurrence create/edit/cancel
- weekly schedule expansion
- native Apple Calendar write-through

The migration intentionally avoids:

- student portal
- payments
- attendance as a separate domain
- reminders
- external booking
- Google Calendar or Outlook Calendar
- AI summaries
- audio/video analysis
- full curriculum builder

## Completion Definition

Phase 7 is complete only when all of these are true:

1. The macOS app builds and launches from Xcode and `xcodebuild`.
2. A signed-in instructor can use every current MVP workflow without opening the web app.
3. Supabase RLS still protects real data; no service-role key is embedded in the app.
4. Calendar permission is requested through EventKit, not Apple ID credentials or app-specific passwords.
5. Creating, editing, and canceling app-owned lesson occurrences updates Supabase first and then Apple Calendar.
6. EventKit failures are visible and retryable without corrupting Supabase schedule data.
7. The app remains usable offline for the current loaded session and queues writes for retry.
8. Native UI is verified at compact, default, and wide macOS window sizes.
9. After independent approval, the legacy web runtime can be removed and the native app becomes the primary project shape.
10. `.planning/STATE.md`, `.planning/ROADMAP.md`, README, and release notes accurately describe the new native app state.

## Current Source Of Truth

Use these files as the reference behavior:

- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/phases/06-calendar-apple-sync/06-PLAN.md`
- `supabase/migrations/0001_foundation.sql`
- `supabase/migrations/0013_real_instructor_auth.sql`
- `supabase/migrations/0014_closeout_lesson_rpc.sql`
- `supabase/migrations/0015_calendar_scheduling.sql`
- `supabase/migrations/0016_calendar_sync_security.sql`
- `supabase/migrations/0017_calendar_outbox_invariants.sql`
- `src/lib/supabase/read-models.ts`
- `src/lib/supabase/queries.ts`
- `src/lib/calendar/recurrence.ts`
- `src/lib/calendar/calendar-read-models.ts`
- `src/lib/students/lesson-closeout-draft.ts`
- `src/components/dashboard/lesson-calendar-workbench.tsx`
- `src/components/students/lesson-flow-workspace.tsx`

## Native App Workspace Layout

Create the native project under `native/DrumLessonOS/` so it can live beside the current web app during migration.

```text
native/DrumLessonOS/
  DrumLessonOS.xcodeproj
  DrumLessonOS/
    App/
      DrumLessonOSApp.swift
      AppEnvironment.swift
      AppRoute.swift
      RootView.swift
    Domain/
      Models/
      ReadModels/
      Repositories/
      Validation/
    Data/
      Supabase/
      Calendar/
      Persistence/
      Sync/
    Features/
      Auth/
      Dashboard/
      Students/
      LessonFlow/
      Scheduling/
      Settings/
    DesignSystem/
      Components/
      Tokens/
      Formatters/
    Resources/
      Assets.xcassets
      PreviewData/
  DrumLessonOSTests/
  DrumLessonOSUITests/
```

Boundary rules:

- `Domain` contains pure Swift value types, repository protocols, read-model mapping, validation, recurrence, and closeout draft logic.
- `Data` implements Supabase, EventKit, Keychain, local persistence, and retry queues.
- `Features` imports `Domain`, `Data` only through protocol dependencies, and `DesignSystem`.
- `DesignSystem` has reusable SwiftUI primitives, labels, badges, cards, empty states, and formatters.
- `App` owns dependency wiring, route state, windows, scenes, and environment injection.

## Data And Write Boundary

Keep the current Supabase schema for domain records. Add native migrations for RPC write boundaries and EventKit sync metadata.

The native app must not embed `SUPABASE_SERVICE_ROLE_KEY`. Any write that currently depends on Next.js server actions or admin Supabase access must move behind authenticated SQL RPCs. RPC functions should use `security definer`, set `search_path = public`, derive the instructor from `auth.uid()`, validate ownership inside the function, and grant execute only to `authenticated`.

Proposed native write migration:

`supabase/migrations/0018_native_write_rpcs.sql`

Required RPCs:

- `public.native_create_student`
- `public.native_update_student_profile`
- `public.native_upsert_student_trait`
- `public.native_upsert_progress_item`
- `public.native_update_progress_status`
- `public.native_upsert_assignment`
- `public.native_create_lesson_note`
- `public.native_upsert_next_lesson_plan`
- `public.native_create_one_off_occurrence`
- `public.native_create_weekly_schedule_template`
- `public.native_insert_expanded_occurrences`
- `public.native_edit_occurrence_time`
- `public.native_cancel_occurrence`
- `public.native_update_occurrence_calendar_sync`

Each RPC must return the changed row id or a compact changed-row summary so the native app can refresh only affected state.

Proposed EventKit sync migration:

`supabase/migrations/0019_native_eventkit_sync.sql`

```sql
alter table public.lesson_occurrences
  add column if not exists native_calendar_event_identifier text,
  add column if not exists native_calendar_identifier text,
  add column if not exists native_calendar_external_identifier text,
  add column if not exists native_calendar_sync_status text not null default 'not_connected'
    check (native_calendar_sync_status in ('not_connected', 'pending', 'synced', 'failed', 'disabled')),
  add column if not exists native_calendar_sync_error text,
  add column if not exists native_calendar_synced_at timestamptz;

create index if not exists lesson_occurrences_native_calendar_sync_idx
  on public.lesson_occurrences (instructor_id, native_calendar_sync_status, starts_at);

grant select (
  native_calendar_event_identifier,
  native_calendar_identifier,
  native_calendar_external_identifier,
  native_calendar_sync_status,
  native_calendar_sync_error,
  native_calendar_synced_at
) on public.lesson_occurrences to authenticated;
```

Do not remove the Phase 6 CalDAV columns in the first native migration. Keeping both sets of columns preserves rollback safety.

## EventKit Ownership Rules

EventKit replaces CalDAV credentials for the native app.

- The app asks macOS for Calendar access with EventKit.
- The user chooses one writable calendar from EventKit calendars.
- The selected calendar identifier is stored in Keychain or local app storage.
- Lesson occurrences remain canonical in Supabase.
- Native EventKit writes are derived from Supabase occurrence data.
- Event notes include a stable marker: `Drum Lesson OS occurrence: <uuid>`.
- If an EventKit event is missing, recreate it from Supabase and update the occurrence sync fields.
- If an EventKit write fails, leave the Supabase occurrence saved and mark native calendar sync failed.
- Do not import user-created Apple Calendar events into Supabase in Phase 7 unless they contain the Drum Lesson OS marker.
- Do not store Apple ID, app-specific password, or iCloud credential in the native app.

## Phase 7 Task Overview

| Task | Name | Outcome |
|------|------|---------|
| 07-01 | Freeze Web Contracts | Current behavior has parity snapshots and test markers. |
| 07-02 | Create Native Project | Xcode project builds and has module boundaries. |
| 07-03 | Port Domain Models | Supabase rows and read models exist in pure Swift. |
| 07-04 | Supabase Auth And Data Client | Native sign-in and owner-scoped reads work. |
| 07-05 | Calendar Read Models | Dashboard week/today model matches web behavior. |
| 07-06 | Native RPC Write Boundary | Authenticated RPCs replace web admin writes for native. |
| 07-07 | EventKit Adapter | Permission, calendar selection, create/update/delete work. |
| 07-08 | Native Dashboard | Calendar-first dashboard and roster render in SwiftUI. |
| 07-09 | Student Detail | Summary, Progress, Notes, Brief, Run, Closeout render. |
| 07-10 | Student Editing | Profile, traits, progress, assignments, notes, next plan write. |
| 07-11 | Scheduling Writes | Occurrence create/edit/cancel and weekly expansion write to Supabase and EventKit. |
| 07-12 | Offline Queue | Failed writes stay visible and retryable. |
| 07-13 | Visual And Accessibility Pass | Window sizes, keyboard, VoiceOver labels, and dark mode pass. |
| 07-14 | Release Gate | Native app is verified, docs updated, web fallback preserved. |

---

## Task 07-01: Freeze Web Contracts

**Goal:** Capture the current web MVP behavior before rebuilding it.

**Files:**

- Create: `.planning/phases/07-swiftui-native-migration/07-LEGACY-WEB-REFERENCE.md`
- Create: `.planning/phases/07-swiftui-native-migration/07-PARITY-CHECKLIST.md`

Steps:

- [ ] Record the current route and workflow inventory:
  - `/login`
  - `/forgot-password`
  - `/reset-password`
  - `/`
  - `/students/new`
  - `/students/[studentId]`
  - `/api/calendar/sync`
- [ ] Record every user-visible workflow from `.planning/REQUIREMENTS.md`.
- [ ] Record the current Supabase tables and RPCs used by the web app.
- [ ] Record the current calendar behavior:
  - one-off lesson create
  - weekly lesson create
  - occurrence edit
  - occurrence cancel
  - sync status display
  - retry failed sync
  - start lesson from occurrence
- [ ] Run the current web verification commands.

Verification:

```bash
npm test
npm run build
npm run lint
supabase db push --dry-run
```

Expected:

- `npm test` passes all tests.
- `next build` completes.
- `eslint .` exits with code 0.
- Supabase dry-run reports no unexpected pending migrations, or lists only the planned native migrations after Tasks 07-06 and 07-11.

Commit:

```bash
git add .planning/phases/07-swiftui-native-migration/07-LEGACY-WEB-REFERENCE.md .planning/phases/07-swiftui-native-migration/07-PARITY-CHECKLIST.md
git commit -m "docs: freeze native migration web contracts"
```

## Task 07-02: Create Native Project

**Goal:** Add a macOS SwiftUI app that builds before feature work starts.

**Files:**

- Create: `native/DrumLessonOS/DrumLessonOS.xcodeproj`
- Create: `native/DrumLessonOS/DrumLessonOS/App/DrumLessonOSApp.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/App/RootView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/App/AppEnvironment.swift`
- Create: `native/DrumLessonOS/DrumLessonOSTests/NativeSmokeTests.swift`
- Modify: `.gitignore`
- Modify: `README.md`

Steps:

- [ ] Create a macOS SwiftUI app named `DrumLessonOS`.
- [ ] Set deployment target to the oldest macOS version available on the development machine that supports the selected EventKit access API.
- [ ] Add Swift Package dependency for the official Supabase Swift client.
- [ ] Add Calendar usage description to the app target Info settings:

```text
Privacy - Calendars Usage Description = Drum Lesson OS writes scheduled lesson times to the Apple Calendar you choose.
```

- [ ] Add the Calendar entitlement if Xcode requires it for the chosen target settings.
- [ ] Add a root window that renders a native placeholder:

```swift
import SwiftUI

struct RootView: View {
    var body: some View {
        ContentUnavailableView(
            "Drum Lesson OS",
            systemImage: "music.note.list",
            description: Text("Native migration shell is ready.")
        )
        .frame(minWidth: 960, minHeight: 680)
    }
}
```

- [ ] Add a smoke test:

```swift
import Testing
@testable import DrumLessonOS

@Test func nativeSmokeTest() {
    #expect(AppRoute.dashboard.description == "dashboard")
}
```

Verification:

```bash
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
```

Expected:

- Build succeeds.
- `nativeSmokeTest` passes.

Commit:

```bash
git add native/DrumLessonOS .gitignore README.md
git commit -m "feat: add native swiftui app shell"
```

## Task 07-03: Port Domain Models

**Goal:** Define pure Swift models that mirror Supabase rows and current read models.

**Files:**

- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Models/Instructor.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Models/Student.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Models/ProgressItem.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Models/StudentTrait.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Models/LessonNote.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Models/Assignment.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Models/NextLessonPlan.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Models/LessonSchedule.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/ReadModels/StudentRosterItem.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/ReadModels/StudentDetail.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/ReadModels/CalendarWorkbench.swift`
- Create: `native/DrumLessonOS/DrumLessonOSTests/DomainModelDecodingTests.swift`

Steps:

- [ ] Add enums for every existing constrained text value:
  - progress category
  - progress status
  - trait type
  - assignment status
  - next lesson priority
  - occurrence status
  - native calendar sync status
- [ ] Add row structs that decode snake_case Supabase JSON.
- [ ] Add read-model structs that use Swift-friendly property names.
- [ ] Add fixtures using realistic Korean seed content.
- [ ] Add decoding tests for one full student detail payload and one calendar occurrence payload.

Verification:

```bash
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test -only-testing:DrumLessonOSTests/DomainModelDecodingTests
```

Expected:

- Decoding test passes.
- Invalid enum values fail decoding with a visible test failure.

Commit:

```bash
git add native/DrumLessonOS/DrumLessonOS/Domain native/DrumLessonOS/DrumLessonOSTests/DomainModelDecodingTests.swift
git commit -m "feat: port native domain models"
```

## Task 07-04: Supabase Auth And Data Client

**Goal:** Let the native app sign in and read instructor-owned data without service-role credentials.

**Files:**

- Create: `native/DrumLessonOS/DrumLessonOS/Data/Supabase/SupabaseEnvironment.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Data/Supabase/SupabaseClientFactory.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Data/Supabase/AuthSessionStore.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Data/Supabase/SupabaseStudentRepository.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Repositories/AuthRepository.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Repositories/StudentRepository.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Auth/LoginView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Auth/AuthViewModel.swift`
- Create: `native/DrumLessonOS/DrumLessonOSTests/AuthRepositoryTests.swift`

Steps:

- [ ] Load `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` equivalents from a native configuration file excluded from git.
- [ ] Store the Supabase session in Keychain.
- [ ] Implement sign-in with email and password.
- [ ] Implement sign-out.
- [ ] Implement password recovery by opening Supabase recovery link flow in the system browser.
- [ ] Implement `loadCurrentInstructor`.
- [ ] Implement roster and detail reads using the authenticated user session.
- [ ] Add a login screen with:
  - email field
  - password field
  - sign-in button
  - forgot password button
  - setup/error state

Verification:

```bash
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test -only-testing:DrumLessonOSTests/AuthRepositoryTests
```

Manual check:

1. Launch the native app.
2. Sign in as the existing instructor.
3. Quit and reopen.
4. Confirm the session restores.
5. Sign out.
6. Confirm protected screens are hidden.

Commit:

```bash
git add native/DrumLessonOS/DrumLessonOS/Data/Supabase native/DrumLessonOS/DrumLessonOS/Domain/Repositories native/DrumLessonOS/DrumLessonOS/Features/Auth native/DrumLessonOS/DrumLessonOSTests/AuthRepositoryTests.swift
git commit -m "feat: add native supabase auth"
```

## Task 07-05: Port Read-Model Logic

**Goal:** Match the web app's derived dashboard, roster, detail, lesson brief, and closeout draft behavior.

**Files:**

- Create: `native/DrumLessonOS/DrumLessonOS/Domain/ReadModels/StudentRosterMapper.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/ReadModels/StudentDetailMapper.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/ReadModels/CalendarWorkbenchMapper.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/ReadModels/LessonBriefBuilder.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/ReadModels/LessonCloseoutDraftBuilder.swift`
- Create: `native/DrumLessonOSTests/ReadModelParityTests.swift`

Steps:

- [ ] Port current-focus selection from `src/lib/supabase/read-models.ts`.
- [ ] Port newest-note ordering.
- [ ] Port assignment status selection.
- [ ] Port next lesson plan selection.
- [ ] Port roster filter source fields.
- [ ] Port lesson brief first-check selection.
- [ ] Port closeout draft next-hint behavior.
- [ ] Port calendar week/today grouping from `src/lib/calendar/calendar-read-models.ts`.
- [ ] Add parity tests with fixture data matching current web tests.

Verification:

```bash
npm test -- src/lib/supabase/read-models.test.mts src/lib/calendar/calendar-read-models.test.mts src/lib/students/lesson-closeout-draft.test.mts
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test -only-testing:DrumLessonOSTests/ReadModelParityTests
```

Expected:

- Web read-model tests still pass.
- Native parity tests produce the same roster/detail/calendar labels and first-check fields.

Commit:

```bash
git add native/DrumLessonOS/DrumLessonOS/Domain/ReadModels native/DrumLessonOS/DrumLessonOSTests/ReadModelParityTests.swift
git commit -m "feat: port native read models"
```

## Task 07-06: Native RPC Write Boundary

**Goal:** Add authenticated Supabase RPCs so the native app can write data without embedding a service-role key.

**Files:**

- Create: `supabase/migrations/0018_native_write_rpcs.sql`
- Create: `tests/native-rpc-security.test.mts`
- Modify: `package.json`
- Create: `native/DrumLessonOS/DrumLessonOS/Data/Supabase/SupabaseRPCClient.swift`
- Create: `native/DrumLessonOSTests/SupabaseRPCClientTests.swift`

Steps:

- [ ] Create `public.native_current_instructor_id()` that returns the instructor id linked to `auth.uid()`.
- [ ] Create student-domain RPCs:
  - `native_create_student`
  - `native_update_student_profile`
  - `native_upsert_student_trait`
  - `native_upsert_progress_item`
  - `native_update_progress_status`
  - `native_upsert_assignment`
  - `native_create_lesson_note`
  - `native_upsert_next_lesson_plan`
- [ ] Create schedule RPCs:
  - `native_create_one_off_occurrence`
  - `native_create_weekly_schedule_template`
  - `native_insert_expanded_occurrences`
  - `native_edit_occurrence_time`
  - `native_cancel_occurrence`
  - `native_update_occurrence_calendar_sync`
- [ ] Reuse existing `closeout_lesson` RPC for closeout.
- [ ] Make every RPC derive instructor ownership from `auth.uid()`.
- [ ] Grant execute on these RPCs to `authenticated`.
- [ ] Revoke execute from `anon`.
- [ ] Add tests that confirm the migration contains no service-role-only native path.
- [ ] Add tests that confirm every native RPC references `native_current_instructor_id()`.
- [ ] Add `SupabaseRPCClient` wrapper in Swift so features never call raw RPC names directly.

Verification:

```bash
npm test -- tests/native-rpc-security.test.mts
supabase db push --dry-run
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test -only-testing:DrumLessonOSTests/SupabaseRPCClientTests
```

Expected:

- Migration security test passes.
- Supabase dry-run accepts the RPC migration.
- Swift RPC wrapper tests pass with mocked responses.

Commit:

```bash
git add supabase/migrations/0018_native_write_rpcs.sql tests/native-rpc-security.test.mts package.json native/DrumLessonOS/DrumLessonOS/Data/Supabase/SupabaseRPCClient.swift native/DrumLessonOS/DrumLessonOSTests/SupabaseRPCClientTests.swift
git commit -m "feat: add native supabase write rpcs"
```

## Task 07-07: EventKit Adapter

**Goal:** Add native Apple Calendar access without Apple credentials.

**Files:**

- Create: `native/DrumLessonOS/DrumLessonOS/Data/Calendar/EventKitCalendarRepository.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Data/Calendar/EventKitPermissionState.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Data/Calendar/EventKitLessonEventBuilder.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Repositories/CalendarRepository.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Settings/CalendarSettingsView.swift`
- Create: `native/DrumLessonOSTests/EventKitLessonEventBuilderTests.swift`

Steps:

- [ ] Define `CalendarRepository` with:
  - permission status
  - request permission
  - list writable calendars
  - select target calendar
  - create lesson event
  - update lesson event
  - delete lesson event
  - retry failed sync
- [ ] Implement EventKit permission state mapping.
- [ ] Build event title as `Drum lesson - {studentName}`.
- [ ] Build event notes with:
  - current focus
  - first check
  - student id
  - occurrence id marker
- [ ] Store selected calendar identifier locally.
- [ ] Store EventKit event identifiers in Supabase occurrence sync fields after successful writes.
- [ ] Add safe errors for permission denied, no writable calendar, and missing event.

Verification:

```bash
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test -only-testing:DrumLessonOSTests/EventKitLessonEventBuilderTests
```

Manual check:

1. Launch the native app.
2. Open Calendar settings.
3. Request Calendar access.
4. Choose an iCloud calendar.
5. Confirm no Apple ID password or app-specific password is requested.

Commit:

```bash
git add native/DrumLessonOS/DrumLessonOS/Data/Calendar native/DrumLessonOS/DrumLessonOS/Domain/Repositories/CalendarRepository.swift native/DrumLessonOS/DrumLessonOS/Features/Settings/CalendarSettingsView.swift native/DrumLessonOS/DrumLessonOSTests/EventKitLessonEventBuilderTests.swift
git commit -m "feat: add native eventkit calendar adapter"
```

## Task 07-08: Native Calendar Dashboard

**Goal:** Replace the web dashboard with a SwiftUI calendar-first workbench.

**Files:**

- Create: `native/DrumLessonOS/DrumLessonOS/Features/Dashboard/DashboardView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Dashboard/DashboardViewModel.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Dashboard/WeekCalendarView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Dashboard/TodayLessonListView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Dashboard/LessonEventCard.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Dashboard/SelectedLessonPanel.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/StudentRosterView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/DesignSystem/Components/StatusBadge.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/DesignSystem/Formatters/LessonDateFormatters.swift`

Steps:

- [ ] Render header with week range, Today, previous week, next week, add lesson, and Calendar status.
- [ ] Render week grid at normal and wide window sizes.
- [ ] Render today-first list at compact window sizes.
- [ ] Render selected lesson panel with:
  - student name
  - time
  - watch flags
  - first check
  - start lesson
  - edit schedule
  - cancel occurrence
  - sync status
- [ ] Render roster below or beside the calendar depending on width.
- [ ] Add loading, empty, error, and signed-out states.
- [ ] Add keyboard shortcuts:
  - `Command+N` add lesson
  - `Command+R` refresh
  - left/right arrows move week when focus is in dashboard

Verification:

```bash
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
```

Manual visual check:

1. Launch app signed in.
2. Confirm calendar-first dashboard appears.
3. Resize to 430 px width and confirm the today-first layout stays readable.
4. Resize to 1280 px width and confirm the week grid stays aligned.
5. Select an occurrence and confirm selected panel updates.

Commit:

```bash
git add native/DrumLessonOS/DrumLessonOS/Features/Dashboard native/DrumLessonOS/DrumLessonOS/Features/Students/StudentRosterView.swift native/DrumLessonOS/DrumLessonOS/DesignSystem
git commit -m "feat: build native calendar dashboard"
```

## Task 07-09: Native Student Detail And Lesson Flow

**Goal:** Implement the student detail surface and the Phase 5 lesson-flow workspace.

**Files:**

- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/StudentDetailView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/StudentDetailViewModel.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/StudentHeaderView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/LessonFlow/LessonBriefView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/LessonFlow/LessonRunPanelView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/LessonFlow/LessonCloseoutView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/SummaryTabView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/ProgressTabView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/NotesTabView.swift`

Steps:

- [ ] Add route from dashboard occurrence to student detail with occurrence context.
- [ ] Render student header with profile cue, status badges, current focus, and next action.
- [ ] Render calendar lesson context when opened from an occurrence.
- [ ] Render Lesson Brief before tabs.
- [ ] Render Run Panel with session-local fields.
- [ ] Implement `Use in closeout` to populate closeout draft.
- [ ] Render Closeout form with expandable detail.
- [ ] Render Summary, Progress, and Notes tabs.
- [ ] Ensure the page remains useful when opened without an occurrence.

Verification:

Manual check:

1. From dashboard, select a lesson.
2. Open `Start lesson`.
3. Confirm the student detail displays calendar context.
4. Add run notes locally.
5. Use notes in closeout.
6. Confirm closeout fields receive covered, observation, practice, next hint, and focus.

Commit:

```bash
git add native/DrumLessonOS/DrumLessonOS/Features/Students native/DrumLessonOS/DrumLessonOS/Features/LessonFlow
git commit -m "feat: build native student lesson flow"
```

## Task 07-10: Native Editing Workflows

**Goal:** Port every durable student-domain write workflow from the web app.

**Files:**

- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Validation/StudentEditingValidation.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Data/Supabase/SupabaseStudentWriteRepository.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/NewStudentView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/ProfileEditorView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/TraitEditorView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/ProgressEditorView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/AssignmentEditorView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/LessonNoteEditorView.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Students/NextPlanEditorView.swift`
- Create: `native/DrumLessonOSTests/StudentEditingValidationTests.swift`

Steps:

- [ ] Port validation from `src/lib/students/editing-schemas.ts`.
- [ ] Implement add student.
- [ ] Implement edit profile.
- [ ] Implement edit traits.
- [ ] Implement create/update progress item.
- [ ] Implement quick progress status transition.
- [ ] Implement tempo note editing.
- [ ] Implement assignment create/update.
- [ ] Implement lesson note creation.
- [ ] Implement next plan update.
- [ ] Implement closeout RPC call against `closeout_lesson`.
- [ ] Re-fetch the affected student/dashboard after every successful write.
- [ ] Show inline validation errors and preserve unsaved form values.

Verification:

```bash
npm test -- src/lib/students/editing-schemas.test.mts src/lib/students/closeout-schema.test.mts
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test -only-testing:DrumLessonOSTests/StudentEditingValidationTests
```

Manual check:

1. Add a student.
2. Edit profile.
3. Add a trait.
4. Add a progress item.
5. Mark it as current focus.
6. Add tempo note.
7. Add assignment.
8. Add lesson note.
9. Update next plan.
10. Save closeout.
11. Refresh and confirm dashboard/detail agree.

Commit:

```bash
git add native/DrumLessonOS/DrumLessonOS/Domain/Validation native/DrumLessonOS/DrumLessonOS/Data/Supabase/SupabaseStudentWriteRepository.swift native/DrumLessonOS/DrumLessonOS/Features/Students native/DrumLessonOSTests/StudentEditingValidationTests.swift
git commit -m "feat: port native student editing workflows"
```

## Task 07-11: Native Scheduling Writes

**Goal:** Port schedule create/edit/cancel and weekly expansion, then write changes to EventKit.

**Files:**

- Create: `supabase/migrations/0019_native_eventkit_sync.sql`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/Validation/ScheduleValidation.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Domain/ReadModels/WeeklyOccurrenceExpander.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Data/Supabase/SupabaseScheduleRepository.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Data/Sync/CalendarSyncCoordinator.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Scheduling/ScheduleLessonSheet.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Scheduling/EditOccurrenceSheet.swift`
- Create: `native/DrumLessonOSTests/ScheduleValidationTests.swift`
- Create: `native/DrumLessonOSTests/WeeklyOccurrenceExpanderTests.swift`
- Create: `native/DrumLessonOSTests/CalendarSyncCoordinatorTests.swift`

Steps:

- [ ] Add migration `0019_native_eventkit_sync.sql`.
- [ ] Port `expandWeeklyOccurrences` behavior.
- [ ] Implement one-off lesson create:
  - insert Supabase occurrence
  - mark native sync pending
  - create EventKit event
  - update Supabase sync fields
- [ ] Implement weekly lesson create:
  - insert schedule template
  - expand 8 weeks of occurrences
  - write each occurrence to EventKit
  - mark individual sync status
- [ ] Implement occurrence edit:
  - update Supabase occurrence first
  - update or recreate EventKit event
  - update Supabase sync fields
- [ ] Implement occurrence cancel:
  - set Supabase status to `canceled`
  - delete EventKit event when possible
  - mark native sync state
- [ ] Implement retry failed native calendar sync.
- [ ] Keep Phase 6 CalDAV outbox unused by the native app.

Verification:

```bash
supabase db push --dry-run
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test -only-testing:DrumLessonOSTests/ScheduleValidationTests
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test -only-testing:DrumLessonOSTests/WeeklyOccurrenceExpanderTests
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test -only-testing:DrumLessonOSTests/CalendarSyncCoordinatorTests
```

Manual check:

1. Grant Calendar permission.
2. Choose an iCloud calendar.
3. Add one-off lesson.
4. Confirm the lesson appears in Apple Calendar on Mac.
5. Confirm the same event appears on iPhone after iCloud sync.
6. Edit the lesson time.
7. Confirm Apple Calendar updates.
8. Cancel the lesson.
9. Confirm Apple Calendar event is removed or clearly canceled according to the implemented behavior.

Commit:

```bash
git add supabase/migrations/0019_native_eventkit_sync.sql native/DrumLessonOS/DrumLessonOS/Domain/Validation/ScheduleValidation.swift native/DrumLessonOS/DrumLessonOS/Domain/ReadModels/WeeklyOccurrenceExpander.swift native/DrumLessonOS/DrumLessonOS/Data/Supabase/SupabaseScheduleRepository.swift native/DrumLessonOS/DrumLessonOS/Data/Sync/CalendarSyncCoordinator.swift native/DrumLessonOS/DrumLessonOS/Features/Scheduling native/DrumLessonOS/DrumLessonOSTests
git commit -m "feat: add native scheduling and eventkit sync"
```

## Task 07-12: Offline And Retry Behavior

**Goal:** Make native write failures visible and recoverable.

**Files:**

- Create: `native/DrumLessonOS/DrumLessonOS/Data/Persistence/LocalWriteQueue.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Data/Persistence/LocalCacheStore.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Data/Sync/RetryScheduler.swift`
- Create: `native/DrumLessonOS/DrumLessonOS/Features/Settings/SyncStatusView.swift`
- Create: `native/DrumLessonOSTests/LocalWriteQueueTests.swift`
- Create: `native/DrumLessonOSTests/RetrySchedulerTests.swift`

Steps:

- [ ] Cache the last successful dashboard and selected student detail read.
- [ ] Queue failed Supabase writes with operation type and payload.
- [ ] Queue failed EventKit writes separately from Supabase writes.
- [ ] Show a non-blocking sync status surface.
- [ ] Add retry now.
- [ ] Add automatic retry on app foreground and network recovery.
- [ ] Keep closeout writes conservative: if closeout RPC fails, do not mark local closeout as saved.

Verification:

```bash
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test -only-testing:DrumLessonOSTests/LocalWriteQueueTests
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test -only-testing:DrumLessonOSTests/RetrySchedulerTests
```

Manual check:

1. Launch signed in.
2. Disable network.
3. Confirm cached dashboard remains readable.
4. Attempt a schedule write.
5. Confirm the app shows pending or failed sync without losing data.
6. Re-enable network.
7. Retry.
8. Confirm Supabase and Apple Calendar agree.

Commit:

```bash
git add native/DrumLessonOS/DrumLessonOS/Data/Persistence native/DrumLessonOS/DrumLessonOS/Data/Sync native/DrumLessonOS/DrumLessonOS/Features/Settings/SyncStatusView.swift native/DrumLessonOS/DrumLessonOSTests
git commit -m "feat: add native offline retry flow"
```

## Task 07-13: Visual, Accessibility, And macOS Polish

**Goal:** Make the native app feel intentional and usable under real lesson conditions.

**Files:**

- Modify: `native/DrumLessonOS/DrumLessonOS/DesignSystem/**`
- Modify: `native/DrumLessonOS/DrumLessonOS/Features/**`
- Create: `.planning/phases/07-swiftui-native-migration/07-UAT.md`

Steps:

- [ ] Verify compact window around 430 px width.
- [ ] Verify default window around 1100 px width.
- [ ] Verify wide window around 1440 px width.
- [ ] Verify Light Mode.
- [ ] Verify Dark Mode.
- [ ] Verify keyboard navigation through main actions.
- [ ] Verify VoiceOver labels for all icon-only controls.
- [ ] Verify text does not clip for Korean seeded data.
- [ ] Verify destructive actions use confirmation dialogs.
- [ ] Verify Add/Edit sheets can be dismissed without saving.
- [ ] Verify Calendar permission denied state is understandable and recoverable.
- [ ] Record findings in `07-UAT.md`.

Verification:

```bash
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
```

Manual UAT must include:

1. Sign in.
2. View dashboard.
3. Add lesson.
4. Edit lesson.
5. Cancel lesson.
6. Start lesson.
7. Draft run notes.
8. Save closeout.
9. Edit progress.
10. Edit assignment.
11. Add note.
12. Confirm Apple Calendar on Mac.
13. Confirm Apple Calendar on iPhone after iCloud sync.

Commit:

```bash
git add native/DrumLessonOS .planning/phases/07-swiftui-native-migration/07-UAT.md
git commit -m "polish: verify native macos experience"
```

## Task 07-14: Native Release Gate And Cutover

**Goal:** Decide whether the native app can replace the web app for real daily use.

**Files:**

- Modify: `.planning/ROADMAP.md`
- Modify: `.planning/STATE.md`
- Modify: `.planning/REQUIREMENTS.md`
- Modify: `README.md`
- Create: `.planning/phases/07-swiftui-native-migration/07-CHECKPOINT.md`
- Create: `.planning/phases/07-swiftui-native-migration/07-RELEASE-GATE.md`

Steps:

- [ ] Run all web checks to prove the fallback was not broken.
- [ ] Run all native tests.
- [ ] Run native manual UAT.
- [ ] Confirm Supabase RLS with a signed-out/native unauthenticated state.
- [ ] Confirm the native app binary contains no service-role key.
- [ ] Confirm no Apple credentials are stored.
- [ ] Confirm EventKit permission can be revoked and the app degrades cleanly.
- [ ] Confirm iPhone receives calendar events through iCloud Calendar.
- [ ] Update roadmap to mark Phase 7 complete only after every gate passes.
- [ ] Update README with native setup, build, test, and release instructions.
- [ ] Keep web app documented as fallback until one week of native daily use passes.

Verification:

```bash
npm test
npm run build
npm run lint
supabase db push --dry-run
xcodebuild -project native/DrumLessonOS/DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
```

Release gate expected result:

- All automated checks pass.
- Manual UAT is recorded.
- Calendar EventKit flow is proven on Mac and iPhone.
- No serious known data-loss, auth, or calendar-sync issue remains.

Commit:

```bash
git add .planning/ROADMAP.md .planning/STATE.md .planning/REQUIREMENTS.md README.md .planning/phases/07-swiftui-native-migration/07-CHECKPOINT.md .planning/phases/07-swiftui-native-migration/07-RELEASE-GATE.md
git commit -m "docs: close native swiftui migration gate"
```

## Implementation Order

Execute in this exact order:

1. `07-01` freeze contracts.
2. `07-02` create shell.
3. `07-03` domain models.
4. `07-04` auth/data client.
5. `07-05` read-model parity.
6. `07-06` native RPC write boundary.
7. `07-07` EventKit adapter.
8. `07-08` dashboard.
9. `07-09` student detail and lesson flow.
10. `07-10` editing workflows.
11. `07-11` scheduling writes.
12. `07-12` offline/retry.
13. `07-13` visual/accessibility polish.
14. `07-14` release gate.

Do not jump to UI before `07-03` through `07-07` are verified. The native UI should be thin over tested domain and data boundaries.

## Risk Register

| Risk | Mitigation |
|------|------------|
| EventKit identifiers change after iCloud sync | Store occurrence marker in notes and recover by searching app-owned events in the selected calendar. |
| Supabase Swift auth differs from web session assumptions | Keep auth isolated in `AuthRepository` and verify signed-out/signed-in owner reads early. |
| Native migration expands scope | Treat `.planning/REQUIREMENTS.md` as the scope contract and reject new product features during Phase 7. |
| Calendar write succeeds but Supabase update fails | Supabase is written first. EventKit write result is retried until sync fields update. |
| Supabase write succeeds but EventKit fails | Keep occurrence saved and mark native calendar sync failed. |
| Korean text clips in SwiftUI cards | Use dynamic type, fixed minimum card dimensions, and visual UAT with seed data. |
| Web and native behavior drift | Keep parity fixtures and run web/native tests together during closeout. |

## Success Criteria Traceability

| Existing Requirement | Native Task |
|----------------------|-------------|
| FND-01, FND-02, FND-03 | 07-02, 07-03, 07-04 |
| ROST-01 through ROST-05 | 07-05, 07-08, 07-10 |
| STUD-01 through STUD-03 | 07-09, 07-10 |
| PROG-01 through PROG-05 | 07-05, 07-09, 07-10 |
| NOTE-01 through NOTE-03 | 07-09, 07-10 |
| NEXT-01 through NEXT-04 | 07-05, 07-09, 07-10 |
| CLOSE-01 through CLOSE-03 | 07-05, 07-09, 07-10 |
| QUICK-01 | 07-08, 07-10 |
| FLOW-01 through FLOW-05 | 07-05, 07-09 |
| CAL-01 through CAL-09 | 07-07, 07-08, 07-11, 07-12 |
| CAL-10 | Deferred unless marker-based EventKit recovery is explicitly promoted after Phase 7 |

## Self-Review Checklist

- [x] The plan preserves current MVP scope.
- [x] The plan replaces Apple credential storage with EventKit.
- [x] The plan keeps Supabase as canonical data storage.
- [x] The plan does not require a service-role key in the native app.
- [x] The plan keeps the web app as rollback until native release verification passes.
- [x] Every current requirement has a native task.
- [x] Every task has files, steps, verification, and commit guidance.
- [x] No task depends on an unstated product feature.
