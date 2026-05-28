# Drum Lesson OS

Instructor-side mini CRM for drum lessons. The current MVP covers the instructor workflow from pre-lesson briefing through post-lesson closeout: roster, student detail, progress/current focus, traits, assignments, lesson notes, next lesson planning, dashboard filters, tempo notes, quick actions, lesson operating board, and in-lesson run panel. Phase 6 is planned around calendar-first scheduling and Apple Calendar sync.

## Local Development

```bash
npm install
npm run dev
```

Open http://localhost:3000.

## Supabase Setup

Create `.env.local` from `.env.example`:

```bash
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
NEXT_PUBLIC_APP_ORIGIN=http://localhost:3000
SUPABASE_DB_URL=
```

Phase 1 uses hosted Supabase/Postgres assumptions from the start. The browser bundle only uses the public Supabase URL and publishable key. Legacy projects can use `NEXT_PUBLIC_SUPABASE_ANON_KEY` instead of `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`.

Apply the schema and seed data with the Supabase CLI:

```bash
supabase db push
supabase db execute --file supabase/seed.sql
```

For a local Supabase stack, reset and seed together:

```bash
supabase db reset
```

The seed data uses instructor id `11111111-1111-4111-8111-111111111111` with Korean roster content and short student slugs such as `kim-daniel`.

`0013_real_instructor_auth.sql` adds the `instructors.auth_user_id` link, removes anonymous access grants, and scopes every student-domain table through the authenticated instructor owner. After creating your Supabase Auth user, bind the existing instructor row to that user:

```sql
update public.instructors
set auth_user_id = '<your-supabase-auth-user-id>'
where id = '11111111-1111-4111-8111-111111111111';
```

For hosted Supabase projects, disable public signup in Auth settings after creating the single instructor account.
This repo also records that release-gate default in `supabase/config.toml` with `auth.enable_signup = false`.

Password recovery emails should redirect to the app reset screen. In Supabase Auth URL settings, allow:

```text
http://localhost:3000/reset-password
```

Then use the app's `/forgot-password` page or `Authentication` -> `Users` -> `Send password recovery` and open the newest email link.

## Current Roadmap Scope

The documented MVP phases stay inside the instructor-side workflow and are complete through Phase 5. Phase 6 is planned:

- Phase 3D: student profile and trait editing.
- Phase 3E: assignment/homework review editing.
- Phase 3F: post-lesson closeout.
- Phase 4A: dashboard filters and progress status polish.
- Phase 4B: small tempo checkpoints and limited dashboard quick actions.
- Phase 4C: Lesson Brief and Closeout tightening.
- Phase 5: lesson operating board and in-lesson run panel with closeout draft handoff.
- Phase 6: calendar-first scheduling with Drum Lesson OS as the source of truth and Apple Calendar as the sync target.

Student portal, payments, attendance, reminders, external booking, AI summaries, and audio/video analysis are not planned in the near-term roadmap. Real instructor auth and production RLS cleanup are now part of the release gate.

## Verification

```bash
npm test
npm run build
npm run lint
```

For a first-screen smoke check:

```bash
npm run dev
```

Inspect http://localhost:3000 at desktop width and at 320px mobile width. Without Supabase env vars, the page should show `Review setup` and the `Supabase setup needed` empty state instead of crashing. With Supabase configured, signed-out visitors should be redirected to `/login`.

## Phase 2 Read-View Smoke Check

With Supabase env and seed data configured, the dashboard should show active students in the `Student roster`. Each row should link to `/students/{id}` with an `Open student` action.

The student detail route is read-only. It should render `Summary`, `Progress`, and `Notes` tabs. The `Notes` tab should show the latest three lesson notes newest-first by lesson date.

## Phase 3A Editing Smoke Check

With Supabase env, seed data, auth user binding, and migrations through `0003` applied:

1. Open `/students/22222222-2222-4222-8222-222222222222`.
2. In `Summary`, edit `Next lesson`, save, and confirm the header and panel reflect the saved next action.
3. In `Notes`, add a dated lesson note and confirm it appears in the latest notes list.

## Phase 3B Progress Editing Smoke Check

With Supabase env, seed data, auth user binding, and migrations through `0004` applied:

1. Open `/students/22222222-2222-4222-8222-222222222222`.
2. In `Progress`, add a progress item, save it, and confirm it appears in the progress list.
3. Mark the saved item as `Current focus` and confirm only that progress item has the focus badge.
4. Edit status, detail, and observed date, then confirm the refreshed list reflects the saved values.

## Phase 3C Pre-Lesson Routine Smoke Check

With Supabase env, seed data, auth user binding, and migrations through `0005` applied:

1. Open `/` and confirm `Today and upcoming` appears above the student roster.
2. Confirm each dated queue row shows date state, student, priority, next lesson action, assignment status, current focus, and an `Open student` action.
3. Open a student detail page and confirm `Lesson brief` appears between the detail header and tabs.
4. Confirm the detail header, Lesson Brief, Summary current progress, and Progress tab agree on the same `Current focus` progress item.
5. Mark a different progress item as `Current focus`, refresh the dashboard and detail page, and confirm the new focus appears everywhere.

## Phase 3D Student Profile And Trait Editing Smoke Check

With Supabase env, seed data, auth user binding, and migrations through `0006` applied:

1. Open `/` and click `Add student`.
2. Create a student and confirm the app redirects to that student's detail page.
3. In `Summary`, edit the student's name, profile cue, and primary weak point.
4. Add one `learning_style` trait.
5. Refresh `/` and `/students/{id}` and confirm the dashboard, header, Lesson Brief, Summary, and trait list reflect the saved values.
6. Confirm the page stays readable at desktop width and at 320px mobile width.

## Phase 3E Assignment Review Editing Smoke Check

With Supabase env, seed data, auth user binding, and migrations through `0007` applied:

1. Open a seeded student detail page.
2. In `Summary`, expand `Edit assignment`.
3. Create or update the assignment title, status, due date, and detail.
4. Set status to `Needs review`, refresh `/`, and confirm roster and queue badges match.
5. Open the student detail page again and confirm Lesson Brief assignment review cue matches the saved assignment.
6. Confirm the page stays readable at desktop width and at 320px mobile width.

## Phase 3F Post-Lesson Closeout Smoke Check

With Supabase env, seed data, and migrations through `0007` applied:

1. Open a seeded student detail page.
2. Expand `Closeout form`.
3. Submit a closeout with lesson note, next lesson, assignment review, and progress status fields.
4. Refresh the detail page and confirm Lesson Brief uses the new observation and next action.
5. Confirm the Notes tab shows the new note newest-first.
6. Refresh `/` and confirm dashboard queue/roster reflect the updated next action and assignment status.
7. If current focus was changed, confirm only one Progress item has the focus badge.
8. Use the Browser plugin to confirm dashboard and student detail stay readable at desktop width and 320px mobile width.

## Phase 4A Workbench Filters And Progress Polish Smoke Check

With Supabase env, seed data, and migrations through `0007` applied:

1. Open `/` and confirm the roster filter bar shows student count plus `Needs review`, `High priority`, `No recent note`, and `Missing focus`.
2. Toggle `Needs review` and confirm only matching students remain.
3. Toggle `High priority` too and confirm filters combine with AND behavior.
4. Clear filters and confirm the full active roster returns.
5. Open a student detail page, select `Progress`, and confirm quick status buttons appear on each progress item.
6. Submit one allowed quick status transition, refresh, and confirm the status persists.
7. Use the Browser plugin to confirm dashboard filters and Progress controls stay readable at desktop width and 320px mobile width.

## Phase 4B Tempo And Quick Add Smoke Check

With Supabase env, seed data, and migrations through `0009` applied:

1. Open a student detail page and add or edit a progress item with a `Tempo note`.
2. Refresh the detail page and confirm the Progress row and Lesson Brief current-focus field show the tempo note.
3. Open `/`, expand a student's `Quick actions`, and add a short note.
4. Open that student's `Notes` tab and confirm the quick note appears newest-first.
5. From `/`, update a student's next action and confirm the queue plus detail header reflect it.
6. From `/`, mark a student assignment as `Needs review` and confirm roster, queue, Summary, and Lesson Brief cues update.
7. Use the Browser plugin to confirm dashboard quick actions stay readable at desktop width and 320px mobile width.

## Phase 4C Brief And Closeout Tightening Smoke Check

With Supabase env, seed data, and migrations through `0009` applied:

1. Open a seeded student detail page and confirm Lesson Brief shows `Start here` above `Remember`.
2. Add or submit a newest lesson note whose next-step hint differs from the next lesson action, then confirm Lesson Brief `First check` uses the note hint.
3. Set an assignment to `Needs review` with a detail, then confirm Lesson Brief includes that detail in the assignment review cue.
4. Submit closeout with a progress item selected, `No status change`, and `Set selected item as current focus` checked.
5. Refresh `/` and `/students/{id}` and confirm dashboard, header, Lesson Brief, Summary, and Progress tab show the same focused progress item.
6. Clear `Next detail` in closeout, save, and confirm the next lesson action still saves without violating the existing next-plan detail constraint.
7. Use the Browser plugin to confirm dashboard and student detail stay readable at desktop width and 320px mobile width.

## Phase 5 Lesson Flow Smoke Check

With Supabase env, seed data, and migrations through `0014` applied:

1. Sign in as the instructor.
2. Open `/` and confirm the lesson operating board groups queued lessons into overdue, today, and upcoming sections.
3. Confirm each queued lesson shows a first check and attention flags where relevant.
4. Use `Start lesson` to open a student detail page.
5. Use `Run the lesson` to draft covered material, observation, practice, next hint, and optional focus carry-over.
6. Send the draft into `Closeout`.
7. Confirm `Closeout` opens and the draft next hint fills both note hint and next action unless edited.
8. Save closeout and refresh.
9. Confirm the dashboard operating board, Lesson Brief, Notes, and Progress/current focus agree.
10. Use the Chrome extension to confirm dashboard and student detail stay readable at desktop width and 320px mobile width.

## Phase 6 Calendar Planning Notes

Phase 6 is planned but not implemented. The plan is documented in `.planning/phases/06-calendar-apple-sync/06-PLAN.md`.

The planned direction:

1. Drum Lesson OS owns lesson schedules.
2. Apple Calendar receives synced app-owned lesson occurrences.
3. Recurring lessons are expanded by Drum Lesson OS into individual occurrences.
4. Apple sync uses an outbox so app schedule saves remain durable when CalDAV sync fails.
5. Optional reverse sync only imports Apple-side changes for events originally created by Drum Lesson OS.

## Phase Plan Docs

- `.planning/phases/03d-student-profile-and-trait-editing/03D-PLAN.md`
- `.planning/phases/03d-student-profile-and-trait-editing/03D-CHECKPOINT.md`
- `.planning/phases/03e-assignment-review-editing/03E-PLAN.md`
- `.planning/phases/03e-assignment-review-editing/03E-CHECKPOINT.md`
- `.planning/phases/03f-post-lesson-closeout/03F-PLAN.md`
- `.planning/phases/03f-post-lesson-closeout/03F-CHECKPOINT.md`
- `.planning/phases/04a-workbench-filters-and-progress-polish/04A-PLAN.md`
- `.planning/phases/04a-workbench-filters-and-progress-polish/04A-CHECKPOINT.md`
- `.planning/phases/04b-tempo-and-quick-add-refinements/04B-PLAN.md`
- `.planning/phases/04b-tempo-and-quick-add-refinements/04B-CHECKPOINT.md`
- `.planning/phases/04c-brief-closeout-tightening/04C-PLAN.md`
- `.planning/phases/04c-brief-closeout-tightening/04C-CHECKPOINT.md`
- `.planning/phases/05-lesson-flow-operating-board/05-PLAN.md`
- `.planning/phases/05-lesson-flow-operating-board/05-CHECKPOINT.md`
- `.planning/phases/06-calendar-apple-sync/06-PLAN.md`
