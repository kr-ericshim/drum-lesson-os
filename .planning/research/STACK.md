# Stack Research: Drum Lesson OS

## Recommendation

Use a small full-stack TypeScript web app:

- **App framework**: Next.js App Router with TypeScript
- **UI**: Tailwind CSS v4 plus shadcn/ui components
- **Data access**: Prisma ORM
- **Database for MVP**: SQLite for fast local iteration
- **Future production path**: Postgres or Supabase Postgres if the app needs hosted sync, accounts, or multi-device access

## Rationale

Next.js App Router fits this project because the MVP is mostly CRUD, dashboards, detail views, and forms. Its file-based routing and server component model are enough without splitting a separate backend too early.

Tailwind v4 and shadcn/ui fit the dashboard surface: forms, tables, tabs, badges, dialogs, and compact cards can be built quickly while staying accessible and consistent.

Prisma keeps the early data model explicit and migration-friendly. SQLite is enough for an instructor-side MVP while the product validates fields and workflows. If hosted use becomes important, Postgres is the safer next database target.

## What Not To Use Yet

- **Student portal stack**: Defer until student-facing accounts are in scope.
- **Realtime sync**: Defer until there is a real multi-device or collaborative need.
- **Audio/video analysis**: Defer; it distracts from the CRM memory/progress workflow.
- **Full separate API service**: Defer; a single Next.js app is simpler for the MVP.

## Sources

- Next.js App Router docs: https://en.nextjs.im/docs/app/
- Prisma Next.js guide: https://www.prisma.io/docs/guides/frameworks/nextjs
- Tailwind CSS Next.js guide: https://tailwindcss.com/docs/installation/framework-guides/nextjs
- shadcn/ui Next.js guide: https://v3.shadcn.com/docs/installation/next
- Supabase RLS docs for future hosted auth/data boundary: https://supabase.com/docs/guides/database/postgres/row-level-security
