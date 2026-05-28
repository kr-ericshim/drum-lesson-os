# Phase 7 Legacy Web Reference

**Status:** Historical reference captured before native implementation.
**Source date:** 2026-05-28.
**Scope:** Former Next.js/Supabase web behavior that informed the macOS SwiftUI port. The web source files and runtime are no longer active in this repo.

## Native-Primary Note

This file is retained only as migration evidence. Do not use it as an instruction to restore `src/`, Next.js routes, server actions, or CalDAV web endpoints. Current work should start from `DrumLessonOS/`, `DrumLessonOSTests/`, `project.yml`, `supabase/`, and `tests/`.

## Current Routes

| Route | Current contract |
|-------|------------------|
| `/login` | Email/password Supabase sign-in, setup/error messages, link to password recovery. |
| `/forgot-password` | Requests Supabase password recovery email. |
| `/reset-password` | Browser-side recovery session check and password update flow. |
| `/` | Calendar-first dashboard using `getCalendarDashboard`, with week navigation, today list, selected lesson details, roster, quick actions, and Apple sync settings. |
| `/students/new` | Creates a student with basic lesson-relevant profile fields, then returns to roster/detail flow. |
| `/students/[studentId]` | Student detail by UUID or slug. Shows header, lesson-flow workspace, summary/progress/notes tabs, and optional `?occurrence=` calendar context. |
| `/api/calendar/sync` | Secret-protected POST endpoint that processes CalDAV sync outbox with server admin credentials and credential encryption key. |

## User-Visible Workflows

These workflows are required by `.planning/REQUIREMENTS.md` and current `src/` behavior.

| Area | Web workflow to preserve in native app |
|------|----------------------------------------|
| Auth | Sign in, sign out, request password recovery, reset password, protect student/dashboard routes when signed out. |
| Roster | View active students, see current focus, primary weak point, assignment status, and next action, filter by needs review/high priority/no recent note/missing current focus. |
| Student profile | Add student, edit name/profile cue/primary weak point/active state. |
| Traits | Add or update strengths, weak points, practice habits, learning style, musical preferences, and cautions. |
| Progress | Add/update progress items, set status, change status with quick transitions, mark current focus, store tempo checkpoints. |
| Notes | Add dated lesson note with covered material, observations, practice assigned, and next-step hint; show recent notes newest first. |
| Assignment | Add/update assignment title, status, due date, and detail; mark assignment as needs review from dashboard quick action. |
| Next lesson | Add/update next action, planned date, priority, and detail; surface the next action on dashboard and detail. |
| Quick actions | Add quick lesson note and quick next-action update from dashboard without opening the full detail flow. |
| Lesson flow | Show first action to check, attention flags, session-local run notes, `Use in closeout`, and durable closeout save. |
| Closeout | Save one compact closeout that creates a lesson note, updates next lesson plan, optionally updates assignment, optionally updates progress status/current focus. |
| Calendar | View today/week, create one-off lesson, create weekly lesson template with expanded occurrences, select occurrence, edit time/duration, cancel occurrence, start lesson from occurrence. |
| Apple sync | Connect Apple CalDAV, disable sync, show synced/pending/failed/disconnected/disabled status, retry failed sync, preserve schedule data on credential/sync failure. |

## Supabase Tables And Views

The native app must read and write against the same instructor-owned data model unless a Phase 7 migration explicitly extends it.

| Object | Purpose |
|--------|---------|
| `instructors` | Instructor profile and `auth_user_id` binding. |
| `students` | Student profile, primary weak point, active state, slug extension from later migration. |
| `progress_items` | Flexible learning items, status, current focus, observed date, tempo note fields from Phase 4B. |
| `student_traits` | Strengths, weak points, practice habits, learning style, musical preferences, cautions. |
| `lesson_notes` | Dated lesson notes and next-step hints. |
| `assignments` | Current assignment/practice work and review status. |
| `next_lesson_plans` | Next action, priority, planned date, and detail. |
| `lesson_schedule_templates` | One-off/weekly schedule intent for recurring lessons. |
| `lesson_occurrences` | App-owned lesson slots shown on the calendar and synced to Apple Calendar. |
| `calendar_connections` | Server-side Apple CalDAV connection metadata and encrypted app password. Native EventKit must not use this for Apple credentials. |
| `calendar_sync_outbox` | Durable Phase 6 CalDAV create/update/delete sync queue. Native EventKit sync must use its own fields/queue and leave this web outbox intact. |
| `calendar_connection_summaries` | Authenticated-safe connection state view without credentials. |

## Current RPC And Ownership Contract

- `public.student_owner_can_access(target_instructor_id uuid)` maps `auth.uid()` to `instructors.auth_user_id` and gates owner-scoped RLS.
- `public.closeout_lesson(...)` is the durable closeout write boundary. It creates a lesson note, upserts next lesson plan, optionally upserts assignment, and optionally updates progress status/current focus.
- Current web write flows still use server actions. Some Phase 6 schedule writes use server admin access on the server side, then rely on RLS-safe reads for the browser.
- The native app must not embed `SUPABASE_SERVICE_ROLE_KEY`. Phase 7 write access must move native writes behind authenticated RPCs that derive instructor ownership from `auth.uid()`.

## Current Read-Model Contract

Native parity tests should mirror these web read-model behaviors:

- `mapStudentRoster` selects latest assignment, current next plan, latest lesson note, current focus, and attention source fields.
- `mapStudentDetail` sorts progress by current focus then observed date, traits by type/label, and recent notes by lesson date then created time.
- `buildLessonBrief` derives first check, weak point, latest observation, assignment review cue, and next action.
- `mapLessonQueue` groups next-plan work into overdue, today, and upcoming with attention flags.
- `mapCalendarWorkbench` builds Monday-start week days, today events, selected event, sync labels, watch flags, and student links.
- `expandWeeklyOccurrences` expands weekly templates into individual occurrence rows using timezone-aware local start time.
- `buildLessonCloseoutDraft` fills covered material, observations, practice, next hint, next action, checklist summary, and optional current focus from session-local run notes.

## Calendar Contract

Current Phase 6 web behavior:

- Drum Lesson OS is canonical for schedules.
- Apple Calendar receives app-owned occurrence creates, updates, and deletes.
- Web sync uses iCloud CalDAV app-specific password stored server-side and encrypted.
- Web sync writes are queued through `calendar_sync_outbox`.
- App saves must remain durable when Apple sync fails.
- Failed sync is visible and retryable.
- Optional reverse sync (`CAL-10`) remains deferred.

Phase 7 native behavior must preserve the schedule contract while replacing Apple credentials with EventKit:

- Request Calendar permission through macOS EventKit.
- Let the instructor choose a writable calendar.
- Store EventKit calendar selection locally/Keychain as appropriate.
- Store native EventKit event identifiers in Phase 7 native sync fields.
- Include the stable note marker `Drum Lesson OS occurrence: <uuid>`.
- Supabase occurrence state remains canonical.
- EventKit failures must not corrupt Supabase schedule data.
- Phase 6 CalDAV fields and outbox stay in place for rollback.

## Historical Verification Commands

These were the web checks used while the native app was being ported:

```bash
npm test
npm run build
npm run lint
supabase db push --dry-run
```

They are no longer active after the native-primary reorganization. Current checks live in `README.md` and `07-NATIVE-PRIMARY-REORG.md`.

## Historical Manual Web Smoke

- Sign in and sign out.
- Open `/` and verify calendar-first dashboard renders today/week, selected lesson, roster, and Apple sync settings.
- Add/edit/cancel an occurrence and confirm web schedule data persists after refresh.
- Open a scheduled occurrence via `Start lesson` and confirm `/students/[studentId]?occurrence=...` shows calendar context.
- Save closeout and confirm dashboard/detail state agrees after refresh.
- Trigger failed Apple sync state and confirm retry remains visible without schedule data loss.
