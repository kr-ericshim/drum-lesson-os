# Walking Skeleton — Drum Lesson OS

**Phase:** 1
**Generated:** 2026-05-22

## Capability Proven End-to-End

An instructor can run the app, connect to Supabase/Postgres, seed realistic drum student data, and see a database-backed student dashboard preview.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Next.js App Router with TypeScript | Fits dashboard routes, server rendering, environment-aware setup states, and later vertical slices. |
| Styling | Tailwind CSS with shadcn/ui and lucide-react | Matches UI-SPEC, provides accessible primitives, and avoids ad-hoc dashboard styling. |
| Data layer | Supabase/Postgres with SQL migrations | Honors hosted-first decision, keeps RLS and ownership policies visible, and avoids SQLite drift. |
| Auth | Supabase Auth foundation for instructor ownership | Student accounts remain out of scope, but instructor-owned records need an auth-compatible schema from Phase 1. |
| Deployment target | Local full-stack run with hosted Supabase env vars; later Vercel-compatible | Phase 1 must run locally while preserving hosted deployment assumptions. |
| Directory layout | `src/app`, `src/components/dashboard`, `src/lib/supabase`, `src/types`, `supabase/migrations` | Keeps app routes, dashboard components, Supabase utilities, types, and SQL ownership contracts separate. |

## Stack Touched in Phase 1

- [ ] Project scaffold (framework, build, lint, test runner)
- [ ] Routing — at least one real route
- [ ] Database — at least one real read AND one real write
- [ ] UI — at least one interactive element wired to the API
- [ ] Deployment — running on dev environment OR documented local full-stack run command

## Out of Scope (Deferred to Later Slices)

- Student-facing login or portal
- Payments, invoices, and scheduling automation
- Full student detail read view
- Student editing workflows
- Assignment editing workflows
- Audio/video analysis
- Hardcoded complete drum syllabus

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this skeleton without altering its architectural decisions:

- Phase 2: Student roster and detail read views
- Phase 3: Teaching workflow editing for students, traits, progress, lesson notes, assignments, and next plans
- Phase 4: Pre-lesson briefing polish and responsive dashboard hardening
