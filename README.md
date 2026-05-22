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

Apply the schema and seed data with the Supabase CLI:

```bash
supabase db push
supabase db execute --file supabase/seed.sql
```

For a local Supabase stack, reset and seed together:

```bash
supabase db reset
```

The seed data uses demo instructor id `11111111-1111-4111-8111-111111111111`. To preview the RLS-protected data in a hosted project, use an authenticated Supabase user with a matching instructor id or update `NEXT_PUBLIC_DEMO_INSTRUCTOR_ID` and the seed rows together.

## Verification

```bash
npm run build
npm run lint
rg "SERVICE_ROLE|service_role" src .env.example
```
