# Drum Lesson OS

Instructor-side mini CRM for drum lessons. Phase 1 proves the runnable app foundation, Supabase/Postgres data model, and seed-backed student dashboard preview.

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
SUPABASE_DB_URL=
NEXT_PUBLIC_DEMO_INSTRUCTOR_ID=
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

The seed data uses demo instructor id `11111111-1111-4111-8111-111111111111`. If you change the demo instructor, update `NEXT_PUBLIC_DEMO_INSTRUCTOR_ID`, the seed rows, and the demo migration policies together.

For the early MVP demo, `0002_demo_read_policy.sql` temporarily allows anonymous read access only to rows owned by the seeded demo instructor id. Phase 3A adds `0003_demo_lesson_note_next_plan_write_policy.sql`, which temporarily allows anonymous demo writes only for lesson note creation and next lesson plan creation/update under the same seeded instructor id. Phase 3B adds `0004_demo_progress_item_write_policy.sql`, which temporarily allows anonymous demo writes only for progress item creation/update under the same seeded instructor id. Phase 3C adds `0005_progress_focus_source_of_truth.sql`, which normalizes duplicate focused progress rows, enforces one focused progress item per student, and removes the old student-level focus column.

These demo policies are not production auth. Anyone with the public Supabase key could call the Supabase REST API directly and mutate the scoped demo rows. Remove or replace these policies when real instructor authentication is added.

## Verification

```bash
npm test
npm run build
npm run lint
rg "SERVICE_ROLE|service_role" src .env.example
```

For a first-screen smoke check:

```bash
npm run dev
```

Inspect http://localhost:3000 at desktop width and at 320px mobile width. Without Supabase env vars, the page should show `Review setup` and the `Supabase setup needed` empty state instead of crashing.

## Phase 2 Read-View Smoke Check

With Supabase env and seed data configured, the dashboard should show active students in the `Student roster`. Each row should link to `/students/{id}` with an `Open student` action.

The student detail route is read-only. It should render `Summary`, `Progress`, and `Notes` tabs. The `Notes` tab should show the latest three lesson notes newest-first by lesson date.

## Phase 3A Editing Smoke Check

With Supabase env, seed data, and migrations through `0003` applied:

1. Open `/students/22222222-2222-4222-8222-222222222222`.
2. In `Summary`, edit `Next lesson`, save, and confirm the header and panel reflect the saved next action.
3. In `Notes`, add a dated lesson note and confirm it appears in the latest notes list.

The app should still have no service-role key usage:

```bash
rg "SERVICE_ROLE|service_role" src .env.example
```

## Phase 3B Progress Editing Smoke Check

With Supabase env, seed data, and migrations through `0004` applied:

1. Open `/students/22222222-2222-4222-8222-222222222222`.
2. In `Progress`, add a progress item, save it, and confirm it appears in the progress list.
3. Mark the saved item as `Current focus` and confirm only that progress item has the focus badge.
4. Edit status, detail, and observed date, then confirm the refreshed list reflects the saved values.

## Phase 3C Pre-Lesson Routine Smoke Check

With Supabase env, seed data, and migrations through `0005` applied:

1. Open `/` and confirm `Today and upcoming` appears above the student roster.
2. Confirm each dated queue row shows date state, student, priority, next lesson action, assignment status, current focus, and an `Open student` action.
3. Open a student detail page and confirm `Lesson brief` appears between the detail header and tabs.
4. Confirm the detail header, Lesson Brief, Summary current progress, and Progress tab agree on the same `Current focus` progress item.
5. Mark a different progress item as `Current focus`, refresh the dashboard and detail page, and confirm the new focus appears everywhere.
