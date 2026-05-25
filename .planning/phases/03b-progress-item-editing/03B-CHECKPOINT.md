# Phase 3B Implementation Checkpoint

Date: 2026-05-25
Status: Complete

## Historical Note

This checkpoint records the Phase 3B behavior before Phase 3C unified current focus on progress items. Use `.planning/phases/03c-pre-lesson-routine/03C-CHECKPOINT.md` for the current source-of-truth behavior.

## Scope

Phase 3B adds progress item create/update flows to the existing student detail `Progress` tab.

Included:

- Add a progress item for the current student.
- Update existing progress item category, status, title, observed date, detail, and current-focus flag.
- Keep at most one highlighted progress item when a saved item is marked `Current focus`.
- Phase 3B still used a split focus display; Phase 3C superseded this.

Out of scope:

- Student profile editing.
- Trait editing.
- Assignment editing.
- Delete flows.
- Real instructor authentication.
- Phase 4 roster briefing polish.

## Implemented Locally

- Added progress item categories, statuses, validation schema, and tests in `src/lib/students/editing-schemas.ts`.
- Added `saveProgressItemAction` in `src/app/students/[studentId]/actions.ts`.
- Added `ProgressItemForm` and wired it into `StudentProgressList`.
- Added `supabase/migrations/0004_demo_progress_item_write_policy.sql` for scoped temporary demo writes to `progress_items`.
- Updated current-focus save order so other progress items are cleared only after the target insert/update is confirmed.

## Verification Completed

- `npm test` passed with 11 tests.
- `npm run build` passed.
- `npm run lint` passed.
- `rg "SERVICE_ROLE|service_role" src .env.example` returned no matches.
- `supabase db push --linked --dry-run` reported only `0004_demo_progress_item_write_policy.sql` would be pushed.
- `supabase db push --linked` applied `0004_demo_progress_item_write_policy.sql` to the linked remote Supabase project after explicit approval for temporary anonymous demo writes.
- Browser DOM check against `http://localhost:3000/students/22222222-2222-4222-8222-222222222222` confirmed:
  - `Progress` tab renders `Add progress item`.
  - existing progress rows expose `Edit progress`.
  - current-focus labels render.
  - dashboard/header focus text remained visible and separate in the pre-03C implementation.
- Browser write UAT confirmed:
  - added a progress item from `Progress`
  - marked it as `Current focus`
  - confirmed exactly one visible progress item has the current-focus badge
  - edited status, detail, and observed date
  - confirmed the pre-03C split focus display

## Demo Risk

The accepted demo risk is that `0004` is public-key RLS, not server-action-only access. Anyone with the public Supabase key could directly mutate scoped demo `progress_items` rows until real instructor authentication replaces these policies.
