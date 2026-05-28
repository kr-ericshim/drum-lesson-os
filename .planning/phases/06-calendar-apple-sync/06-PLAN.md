# Phase 6 Calendar-First Scheduling And Apple Calendar Sync Plan

> **For agentic workers:** Phase 6 is integration-heavy. Do not implement from this plan until Phase 5 verification is closed and this plan has been reviewed. Use `superpowers:test-driven-development` for schedule mutation and sync behavior, `superpowers:systematic-debugging` for CalDAV failures, and `superpowers:verification-before-completion` before closeout.

**Goal:** Make Drum Lesson OS schedule-aware by putting a lesson calendar on the first screen and syncing app-owned lesson schedule changes to the instructor's Apple Calendar.

**Product decision:** Drum Lesson OS is the source of truth for lesson schedules. Apple Calendar is the connected calendar target. Apple-side changes may be imported later, but conflicts should keep the Drum Lesson OS schedule as canonical.

**Architecture:** Add first-class lesson schedule records, expand recurring lesson templates into individual lesson occurrences, and sync occurrence create/update/delete events to Apple Calendar through an outbox worker. Store Apple Calendar identifiers and sync status per occurrence. Use iCloud CalDAV with app-specific password credentials, not Apple device-only EventKit.

**Tech Stack:** Next.js App Router, TypeScript, Supabase/Postgres migrations, server actions, RLS, scheduled/manual sync route, CalDAV client module, Zod, Tailwind CSS v4, shadcn-style local UI primitives, Node test runner.

---

## Product Direction

The first screen should move from a queue-first lesson operating board to a calendar-first work surface.

The instructor should be able to:

1. Open Drum Lesson OS and see today's lessons and the current week in calendar context.
2. Add, edit, or delete a lesson schedule from the app.
3. Connect an Apple Calendar account through iCloud CalDAV credentials.
4. Have app-created lesson occurrences appear in Apple Calendar.
5. Open a scheduled lesson and continue the existing Phase 5 flow: brief, run panel, and closeout.

The Apple integration should serve the instructor's existing daily calendar habit. It should not turn Phase 6 into a full studio scheduling product.

## Decisions Locked In

- Drum Lesson OS owns schedule data.
- Apple Calendar receives synced events for app-owned occurrences.
- Recurring lessons are managed by Drum Lesson OS and expanded into individual occurrences.
- Apple Calendar receives individual events for each expanded occurrence.
- The first implementation should use an outbox so app saves do not fail just because Apple sync is slow or unavailable.
- Full bidirectional sync is optional and should be implemented only after one-way write-through is reliable.

## Scope

Included:

- Calendar-first dashboard for today and week-level lesson scanning.
- Lesson schedule create, update, and delete in Drum Lesson OS.
- One-off lessons.
- Recurring lesson templates with app-side occurrence expansion.
- Individual lesson occurrences linked to students.
- Apple Calendar account connection state.
- Apple Calendar selection or default connected calendar target.
- Outbox records for Apple create/update/delete operations.
- Sync status visible enough for the instructor to tell whether Apple Calendar is up to date.
- Manual "sync now" action.
- A server-side sync routine that can be called manually and later by a scheduled job.
- Safe retry behavior for transient CalDAV failures.
- Phase 5 lesson flow entry points from calendar events.

Out of scope for Phase 6:

- Student portal, student booking, or student rescheduling.
- Payments, invoices, or billing.
- Attendance tracking as a separate domain.
- SMS, email reminders, or push notifications.
- Google Calendar or Outlook Calendar.
- Device-local EventKit integration.
- A full conflict-resolution UI.
- True webhook-based realtime sync.
- Complex recurrence exceptions beyond app-expanded occurrences.
- Multi-instructor scheduling.

## Requirements Added

- `CAL-01`: Instructor can view today and the current week as a calendar-first lesson schedule.
- `CAL-02`: Instructor can create a one-off scheduled lesson for an existing student.
- `CAL-03`: Instructor can create a recurring lesson template that expands into individual upcoming lesson occurrences.
- `CAL-04`: Instructor can edit or delete a Drum Lesson OS lesson occurrence.
- `CAL-05`: Instructor can start the existing lesson-flow workspace from a scheduled calendar occurrence.
- `CAL-06`: Drum Lesson OS syncs app-owned occurrence creates, updates, and deletes to Apple Calendar.
- `CAL-07`: Instructor can see whether an occurrence is Apple-synced, pending, failed, or disconnected.
- `CAL-08`: Instructor can manually retry Apple Calendar sync.
- `CAL-09`: Apple Calendar credential failures do not corrupt app-owned schedule data.
- `CAL-10`: Optional reverse sync imports Apple-side changes only for events originally created by Drum Lesson OS.

## UX Shape

The dashboard should show a compact calendar at the top, not a marketing-style hero.

Recommended first-screen layout:

- Header row:
  - current date range
  - Today button
  - previous/next week controls
  - add lesson button
  - Apple sync status button
- Primary calendar:
  - week view by default
  - today column emphasized
  - each lesson block shows time, student, first check, and sync state
  - current/next lesson should be easy to spot
- Right or lower panel depending on viewport:
  - selected lesson details
  - Start lesson
  - Edit schedule
  - Delete occurrence
  - Apple sync status and retry if needed

Mobile should prioritize:

1. Today list.
2. Current week day strip.
3. Selected lesson actions.

Do not force a dense desktop calendar grid onto 320px screens.

## Data Model

Add schedule data without replacing lesson notes or next lesson plans.

Proposed tables:

### `lesson_schedule_templates`

Stores the instructor-owned scheduling intent.

Fields:

- `id uuid primary key`
- `instructor_id uuid not null`
- `student_id uuid not null`
- `title text not null`
- `default_duration_minutes integer not null`
- `timezone text not null`
- `recurrence_kind text not null` (`none`, `weekly`)
- `recurrence_interval integer not null default 1`
- `recurrence_weekday integer null`
- `starts_on date not null`
- `ends_on date null`
- `start_time time not null`
- `active boolean not null default true`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Notes:

- Keep recurrence intentionally small for Phase 6.
- Weekly recurring lessons are enough for the current drum lesson workflow.
- More complex RRULE support can wait until a real need appears.

### `lesson_occurrences`

Stores the actual app-owned lesson slots that the instructor sees and operates.

Fields:

- `id uuid primary key`
- `instructor_id uuid not null`
- `student_id uuid not null`
- `schedule_template_id uuid null`
- `starts_at timestamptz not null`
- `ends_at timestamptz not null`
- `timezone text not null`
- `status text not null` (`scheduled`, `completed`, `canceled`)
- `title text not null`
- `apple_calendar_event_uid text null`
- `apple_calendar_event_href text null`
- `apple_calendar_etag text null`
- `apple_sync_status text not null default 'not_connected'`
- `apple_sync_error text null`
- `apple_synced_at timestamptz null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Notes:

- Occurrences are the objects synced to Apple Calendar.
- Closeout can later attach to an occurrence, but Phase 6 should avoid rewriting the lesson-note model unless needed.
- `status = completed` can be set after closeout in a later tightening pass if Phase 6 grows too large.

### `calendar_connections`

Stores the Apple Calendar connection for the instructor.

Fields:

- `id uuid primary key`
- `instructor_id uuid not null`
- `provider text not null default 'apple_caldav'`
- `account_label text not null`
- `apple_principal_url text null`
- `apple_calendar_home_url text null`
- `apple_calendar_url text null`
- `apple_calendar_display_name text null`
- `username text not null`
- `encrypted_app_password text not null`
- `status text not null` (`connected`, `needs_attention`, `disabled`)
- `last_checked_at timestamptz null`
- `last_error text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Security notes:

- Store only app-specific password credentials.
- Encrypt the password server-side before persistence.
- Never expose stored credentials to the browser.
- Add an environment variable for the encryption key.
- Do not use service-role access from client components.

### `calendar_sync_outbox`

Stores durable sync work.

Fields:

- `id uuid primary key`
- `instructor_id uuid not null`
- `calendar_connection_id uuid not null`
- `lesson_occurrence_id uuid not null`
- `operation text not null` (`create`, `update`, `delete`)
- `status text not null` (`pending`, `processing`, `succeeded`, `failed`)
- `attempt_count integer not null default 0`
- `next_attempt_at timestamptz not null default now()`
- `last_error text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Rules:

- Schedule mutations write app data first.
- Each mutation then writes an outbox item.
- The sync worker processes due outbox items.
- Failed items remain visible and retryable.
- Deletes should keep enough Apple identifiers to delete the remote event after the local occurrence is canceled or tombstoned.

## Apple Calendar Integration

Use iCloud CalDAV.

Connection flow:

1. Instructor creates an Apple app-specific password outside Drum Lesson OS.
2. Instructor enters Apple ID email and app-specific password in Drum Lesson OS.
3. Server verifies CalDAV access.
4. Server discovers available calendars.
5. Instructor chooses the calendar target.
6. Server stores encrypted credentials and selected calendar URL.

Event write behavior:

- Create:
  - Generate an iCalendar `VEVENT` for the occurrence.
  - Include a stable UID derived from the occurrence id.
  - Include a private marker such as `X-DRUM-LESSON-OS-OCCURRENCE-ID`.
  - Save Apple `href`, `etag`, and UID after success.
- Update:
  - Use the saved Apple href where possible.
  - Update summary, start, end, description, and UID-preserving fields.
  - Save the latest etag after success.
- Delete:
  - Delete by saved href.
  - If remote event is already gone, mark the outbox item succeeded and clear sync state.

Event content:

- Summary: `Drum lesson - {student name}`
- Time: occurrence start/end in the occurrence timezone.
- Description:
  - current focus
  - first check / next action
  - Drum Lesson OS student link
  - occurrence id marker in a private-ish line

Do not write lesson notes, weaknesses, or sensitive profile details into Apple Calendar descriptions unless the user explicitly asks later. Calendar events are more shareable than the app.

## Sync Ownership And Conflict Rules

Phase 6A one-way write-through:

- App create -> Apple create.
- App update -> Apple update.
- App delete/cancel -> Apple delete or cancel, based on final UX choice.
- If Apple write fails, app schedule remains saved.
- The occurrence shows `failed` with retry.

Phase 6B optional reverse sync:

- Only inspect Apple events that have the Drum Lesson OS marker or known UID/href.
- Import Apple-side time/title changes into app occurrences only when the app occurrence has not changed since the last Apple sync.
- If both sides changed, keep the app version and mark the occurrence as needing attention.
- If Apple event is deleted, mark app occurrence as `needs_attention` first. Do not silently delete app-owned schedule data in the first version.

Recommended Phase 6 implementation should finish Phase 6A first. Phase 6B can be a separate task inside the same plan only if the CalDAV write-through path is stable.

## Recurring Lesson Expansion

Use app-side expansion, not Apple recurring events.

Rules:

- A weekly template creates individual `lesson_occurrences` for a bounded horizon.
- Default horizon: 8 weeks ahead.
- A maintenance function can extend occurrences when the horizon gets short.
- Editing the template should ask whether to affect:
  - future uncompleted occurrences only
  - this occurrence only
- Deleting the template should cancel future uncompleted occurrences.
- Completed or closeout-linked occurrences should not be rewritten by template edits.

This keeps the lesson workflow simple because each actual lesson has one occurrence that can later connect to closeout state.

## Files To Create

- `supabase/migrations/0015_calendar_scheduling.sql`
  - lesson schedule templates
  - lesson occurrences
  - calendar connections
  - sync outbox
  - RLS policies scoped by instructor owner
- `src/lib/calendar/schedule-types.ts`
  - shared schedule and sync status types
- `src/lib/calendar/recurrence.ts`
  - pure occurrence expansion helpers
- `src/lib/calendar/apple-caldav.ts`
  - server-only Apple CalDAV client wrapper
- `src/lib/calendar/ical.ts`
  - iCalendar event builder/parser helpers
- `src/lib/calendar/sync-outbox.ts`
  - server-side outbox enqueue/process helpers
- `src/lib/calendar/schedule-actions.ts`
  - server actions for app-owned schedule mutations
- `src/lib/calendar/calendar-read-models.ts`
  - dashboard calendar read model
- `src/components/dashboard/lesson-calendar-workbench.tsx`
  - calendar-first dashboard surface
- `src/components/dashboard/lesson-calendar-event.tsx`
  - compact event block
- `src/components/dashboard/lesson-calendar-details.tsx`
  - selected occurrence action panel
- `src/components/calendar/schedule-lesson-dialog.tsx`
  - create/edit occurrence or template
- `src/components/calendar/apple-calendar-settings.tsx`
  - connection, calendar target, status, and retry UI
- `src/app/api/calendar/sync/route.ts`
  - server-only manual/scheduled sync endpoint
- `src/lib/calendar/recurrence.test.mts`
- `src/lib/calendar/ical.test.mts`
- `src/lib/calendar/sync-outbox.test.mts`
- `src/lib/calendar/calendar-read-models.test.mts`

## Files To Modify

- `src/app/page.tsx`
  - Replace or subordinate the operating board with `LessonCalendarWorkbench`.
  - Preserve a route from each occurrence into the Phase 5 lesson flow.
- `src/lib/supabase/read-models.ts`
  - Reuse existing lesson first-check and attention flag logic where possible.
  - Avoid duplicating student-summary logic in the calendar read model.
- `src/app/students/[studentId]/page.tsx`
  - Accept an optional occurrence id in links if needed.
  - Keep the current student page usable without a scheduled occurrence.
- `src/components/students/lesson-flow-workspace.tsx`
  - Optionally receive occurrence context.
  - Do not make closeout depend on calendar data in the first pass.
- `.env.example`
  - Add server-only calendar encryption and sync settings.
- `README.md`
  - Add Phase 6 setup notes and smoke checks after implementation.
- `.planning/REQUIREMENTS.md`
  - Add `CAL-01` through `CAL-10`.
- `.planning/ROADMAP.md`
  - Add Phase 6 and record the product decision that calendar integration is now planned.
- `.planning/STATE.md`
  - Keep planning and execution state accurate as Phase 6 moves from planned to active to complete.

## Environment Variables

Proposed:

```text
CALENDAR_CREDENTIAL_ENCRYPTION_KEY=
CALENDAR_SYNC_SECRET=
CALENDAR_SYNC_LOOKAHEAD_WEEKS=8
```

Rules:

- `CALENDAR_CREDENTIAL_ENCRYPTION_KEY` is required only when Apple connection is enabled.
- The key must be server-only.
- `CALENDAR_SYNC_SECRET` protects the sync route from unauthenticated calls.
- Do not add Apple credentials to `.env.local`; credentials should be user-entered and encrypted in the database.

## Detailed Tasks

### Task 06-01: Add Schedule Schema And RLS

**Goal:** Store app-owned schedules and sync state safely.

**Files:**

- Create: `supabase/migrations/0015_calendar_scheduling.sql`
- Create: `src/lib/calendar/schedule-types.ts`

Steps:

- [ ] Add `lesson_schedule_templates`.
- [ ] Add `lesson_occurrences`.
- [ ] Add `calendar_connections`.
- [ ] Add `calendar_sync_outbox`.
- [ ] Add indexes for instructor/date range reads and pending outbox reads.
- [ ] Add updated-at triggers.
- [ ] Add RLS policies scoped by authenticated instructor.
- [ ] Add status check constraints.

Verify:

- [ ] Apply migration locally or to linked dev database.
- [ ] Confirm signed-out users cannot read/write schedule tables.
- [ ] Confirm the authenticated instructor can read/write only owned schedule rows.

### Task 06-02: Build Recurrence Expansion

**Goal:** Convert simple weekly templates into individual occurrences.

**Files:**

- Create: `src/lib/calendar/recurrence.ts`
- Create: `src/lib/calendar/recurrence.test.mts`

Steps:

- [ ] Add a pure `expandWeeklyOccurrences` helper.
- [ ] Support timezone-aware start/end creation.
- [ ] Generate a bounded horizon, defaulting to 8 weeks.
- [ ] Avoid duplicating occurrences already created for a template/date.
- [ ] Keep one-off lessons as direct occurrences without a template.

Verify:

- [ ] Tests cover one-off, weekly expansion, horizon limits, timezone, and no duplicate generation.

### Task 06-03: Add Schedule Mutation Actions And Outbox Enqueue

**Goal:** Save app schedules first, then enqueue Apple work.

**Files:**

- Create: `src/lib/calendar/schedule-actions.ts`
- Create: `src/lib/calendar/sync-outbox.ts`
- Create/modify tests for action helpers where practical.

Steps:

- [ ] Add create one-off lesson action.
- [ ] Add create weekly recurring template action.
- [ ] Add edit occurrence action.
- [ ] Add cancel/delete occurrence action.
- [ ] Add edit future occurrences from a template.
- [ ] Enqueue `create`, `update`, or `delete` outbox records after successful app mutations.
- [ ] Make Apple disconnection produce `not_connected` sync state without blocking app saves.

Verify:

- [ ] Tests prove mutation helpers save occurrence state and enqueue the right outbox operation.
- [ ] Manual DB check confirms outbox rows are created only after schedule rows exist.

### Task 06-04: Build Apple CalDAV Client And iCalendar Helpers

**Goal:** Connect to iCloud Calendar and write app-owned events.

**Files:**

- Create: `src/lib/calendar/apple-caldav.ts`
- Create: `src/lib/calendar/ical.ts`
- Create: `src/lib/calendar/ical.test.mts`

Steps:

- [ ] Add credential verification against iCloud CalDAV.
- [ ] Discover available calendars.
- [ ] Build `VEVENT` text for a lesson occurrence.
- [ ] Include stable UID and Drum Lesson OS occurrence marker.
- [ ] Create event.
- [ ] Update event by href/etag.
- [ ] Delete event by href.
- [ ] Normalize CalDAV errors into user-safe failure reasons.

Verify:

- [ ] Unit tests cover generated iCalendar fields and escaping.
- [ ] Integration smoke uses a dedicated test Apple Calendar only after explicit manual credential setup.

### Task 06-05: Process The Sync Outbox

**Goal:** Make Apple sync durable and retryable.

**Files:**

- Modify: `src/lib/calendar/sync-outbox.ts`
- Create: `src/lib/calendar/sync-outbox.test.mts`
- Create: `src/app/api/calendar/sync/route.ts`

Steps:

- [ ] Claim pending due outbox rows.
- [ ] Mark rows `processing` before remote writes.
- [ ] On success, update occurrence Apple identifiers and sync status.
- [ ] On transient failure, increment attempt count and schedule retry.
- [ ] On credential failure, mark connection `needs_attention`.
- [ ] On permanent not-found delete, treat the delete as succeeded.
- [ ] Protect the sync route with `CALENDAR_SYNC_SECRET`.
- [ ] Add manual retry path for the instructor.

Verify:

- [ ] Tests cover create/update/delete success, retry, credential failure, and remote already-deleted behavior.
- [ ] Manual sync route rejects missing or wrong secret.

### Task 06-06: Add Calendar-First Dashboard UI

**Goal:** Replace the queue-first surface with an actionable calendar surface.

**Files:**

- Create: `src/lib/calendar/calendar-read-models.ts`
- Create: `src/components/dashboard/lesson-calendar-workbench.tsx`
- Create: `src/components/dashboard/lesson-calendar-event.tsx`
- Create: `src/components/dashboard/lesson-calendar-details.tsx`
- Create: `src/components/calendar/schedule-lesson-dialog.tsx`
- Modify: `src/app/page.tsx`

Steps:

- [ ] Load occurrences for the current visible range.
- [ ] Render week view at desktop sizes.
- [ ] Render today-first list at mobile sizes.
- [ ] Show sync status per occurrence.
- [ ] Add create/edit/delete schedule interactions.
- [ ] Add `Start lesson` link to the existing student lesson flow.
- [ ] Preserve first-check and attention flags in event details.

Verify:

- [ ] Browser smoke at desktop width.
- [ ] Browser smoke at 320px width with no horizontal overflow.
- [ ] Calendar event action opens the right student.
- [ ] Schedule create/edit/delete visibly updates the calendar after refresh.

### Task 06-07: Add Apple Calendar Settings UI

**Goal:** Let the instructor connect and monitor Apple Calendar safely.

**Files:**

- Create: `src/components/calendar/apple-calendar-settings.tsx`
- Modify route placement based on existing settings/navigation patterns.

Steps:

- [ ] Add connect form for Apple ID email and app-specific password.
- [ ] Verify credentials server-side before saving.
- [ ] List discovered calendars.
- [ ] Save selected calendar target.
- [ ] Show connected, needs attention, disabled, and last sync states.
- [ ] Add disconnect behavior that stops future sync without deleting app schedule data.

Verify:

- [ ] Invalid credentials show a safe error.
- [ ] Stored password never appears in HTML, logs, or client props.
- [ ] Disconnect leaves app occurrences intact and marks future sync as disabled/not connected.

### Task 06-08: Optional Reverse Sync Spike

**Goal:** Decide whether Apple-side changes can safely come back into Drum Lesson OS.

Only start this task after one-way write-through is verified.

Steps:

- [ ] Fetch Apple events by known href/UID or occurrence marker.
- [ ] Detect Apple-side time/title changes.
- [ ] Update app occurrence only if app row has not changed since last sync.
- [ ] Mark conflicts as `needs_attention`.
- [ ] Treat Apple deletion as `needs_attention`, not immediate app deletion.

Verify:

- [ ] Manual test with a dedicated Apple Calendar event.
- [ ] Conflict test proves app canonical data wins.

## Testing Strategy

Automated:

- Recurrence expansion tests.
- iCalendar generation tests.
- Outbox state-machine tests.
- Schedule read-model tests.
- RLS policy checks if the existing project pattern supports them.
- Server-action validation tests where practical.

Manual/browser:

- Dashboard week view desktop.
- Dashboard today list at 320px.
- Create one-off lesson.
- Create recurring weekly lesson and confirm occurrence expansion.
- Edit one occurrence.
- Delete/cancel one occurrence.
- Start lesson from an occurrence and complete existing closeout.
- Connect Apple Calendar using a test calendar.
- Confirm Apple event create/update/delete.
- Confirm failed Apple sync does not remove app schedule data.

Recommended verification commands:

```bash
npm test
npm run build
npm run lint
```

Browser verification should include signed-in instructor flows, not only static render checks.

## Risks And Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Apple app-specific password revoked | Sync fails | Mark connection `needs_attention`; keep app schedule intact. |
| CalDAV latency or outage | Save UX becomes slow if synchronous | Use outbox; process sync separately. |
| Remote event deleted in Apple Calendar | App and Apple disagree | In Phase 6A, keep app data and show needs attention/retry. |
| Recurrence complexity grows | Phase balloons | Support one-off and weekly only; expand into occurrences. |
| Sensitive lesson detail leaks to Apple Calendar | Privacy issue | Keep Apple description limited to schedule, first check, and app link. |
| Duplicate Apple events | Calendar clutter | Use stable UID and stored href; make create idempotent where possible. |
| Timezone mistakes | Wrong lesson times | Store timezone per template/occurrence and test DST-adjacent cases. |
| Sync route exposed | Unauthorized sync attempts | Require server secret and authenticated/manual paths. |

## Completion Criteria

Phase 6 is complete when:

1. The dashboard opens as a calendar-first schedule surface.
2. The instructor can create, edit, and delete one-off lessons.
3. The instructor can create a weekly recurring lesson template that expands into individual occurrences.
4. Each occurrence can open the existing lesson-flow workspace.
5. Apple Calendar connection can be configured with iCloud CalDAV credentials.
6. App-owned occurrence create/update/delete operations sync to Apple Calendar through the outbox.
7. Failed sync is visible, retryable, and does not corrupt app schedule data.
8. Desktop and 320px mobile browser checks pass.
9. `npm test`, `npm run build`, and `npm run lint` pass.

## Open Questions Before Implementation

- Should deleting an app occurrence delete the Apple event, or mark it canceled in Apple Calendar?
- Where should Apple Calendar settings live: dashboard sync popover, a settings route, or both?
- Should closeout mark the linked occurrence `completed` in Phase 6, or wait for a small Phase 6C tightening pass?
- What should the default generated horizon be after the initial 8 weeks: extend weekly, on demand, or during sync?
- Will deployment have a scheduled job runner, or should Phase 6 rely on manual sync until deployment automation is chosen?
