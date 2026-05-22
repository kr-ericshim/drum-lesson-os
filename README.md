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
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_DB_URL=
NEXT_PUBLIC_DEMO_INSTRUCTOR_ID=
```

Phase 1 uses hosted Supabase/Postgres assumptions from the start. The browser bundle only uses the public Supabase URL and anon key.

## Verification

```bash
npm run build
npm run lint
rg "SERVICE_ROLE|service_role" src .env.example
```
