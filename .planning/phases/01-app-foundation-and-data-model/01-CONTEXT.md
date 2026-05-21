# Phase 1: App Foundation And Data Model - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase creates the runnable full-stack foundation for Drum Lesson OS and establishes the hosted data model that later phases will build on. It must deliver a working first screen, persistent Supabase/Postgres-backed data, and realistic sample teaching data for multiple drum students.

This phase does not build full student detail workflows, editing workflows, student-facing accounts, scheduling automation, billing, or audio/video analysis.

</domain>

<decisions>
## Implementation Decisions

### Storage And Ownership
- **D-01:** Phase 1 should be designed for a hosted Supabase/Postgres deployment from the start, not as a SQLite-only local prototype.
- **D-02:** Supabase Auth should be considered for instructor accounts only. Student accounts and portals remain out of scope.
- **D-03:** Student and lesson data must include instructor ownership boundaries from the first schema design.
- **D-04:** Tables exposed through Supabase should be planned with Row Level Security in mind. Planner should avoid designs that assume globally readable student data.
- **D-05:** Local development may still use environment-based Supabase/Postgres connection settings, but the schema should not depend on local-only assumptions.

### Data Model Shape
- **D-06:** Use a hybrid model: structure the fields needed for dashboard summaries and filtering, while preserving free-text detail for lesson reality.
- **D-07:** Core entities should include students, progress items, student traits, lesson notes, assignments, and next lesson plans.
- **D-08:** Structure progress category/status, trait type, assignment status, current-focus markers, dates, and ownership fields.
- **D-09:** Keep detailed observations, weak point descriptions, lesson reflections, and next-lesson details as free text where strict enums would be too limiting.

### Seed Data
- **D-10:** Seed data should be MVP demo quality, not minimal fixtures.
- **D-11:** Include 5-7 students with clearly different teaching situations.
- **D-12:** Seed cases should include examples such as complete beginner, hobby adult, audition/practical-music student, student with weak fills, student with poor practice consistency, and student who learns best through demonstration.
- **D-13:** Seed data should make the dashboard meaningful immediately by showing current focus, weak point, assignment status, and next lesson action differences.

### First Screen
- **D-14:** The first working screen should show a sample student dashboard preview backed by seeded database data.
- **D-15:** The preview should surface current focus, primary weak point, assignment status, and next action in a compact list or card layout.
- **D-16:** Do not pull Phase 2 fully into Phase 1. Full student detail read views remain Phase 2 scope.

### the agent's Discretion
- The planner may choose the exact Supabase project setup sequence, migration tooling, and whether Prisma or Supabase client owns each query path, as long as the hosted Supabase/Postgres + ownership/RLS direction is preserved.
- The planner may choose the exact field names and enums, provided the dashboard-summary fields are structured and lesson-specific details remain flexible.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope
- `.planning/PROJECT.md` — Defines the instructor-side MVP, core value, constraints, and out-of-scope boundaries.
- `.planning/REQUIREMENTS.md` — Defines Phase 1 requirements FND-01, FND-02, and FND-03 and the v1 traceability map.
- `.planning/ROADMAP.md` — Defines Phase 1 goal, success criteria, MVP mode, and plan outline.
- `.planning/STATE.md` — Tracks current project position and resume context.
- `.planning/config.json` — Captures workflow settings, including Quality model profile and enabled planning checks.

### Research
- `.planning/research/SUMMARY.md` — Summarizes recommended stack, MVP table stakes, and roadmap implications.
- `.planning/research/STACK.md` — Recommends Next.js App Router, TypeScript, Tailwind CSS v4, shadcn/ui, Prisma, and hosted Postgres/Supabase path.
- `.planning/research/ARCHITECTURE.md` — Describes dashboard, student detail, progress model, lesson note model, and data flow.
- `.planning/research/PITFALLS.md` — Warns against generic CRM scope creep, over-structured progress, unscannable notes, privacy gaps, and dashboard noise.

### External Official References Checked During Discussion
- Supabase Next.js Auth quickstart — https://supabase.com/docs/guides/auth/quickstarts/nextjs
- Supabase Row Level Security docs — https://supabase.com/docs/guides/database/postgres/row-level-security

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None yet. The repository currently contains planning documents and generated project guidance only.

### Established Patterns
- No application code patterns exist yet.
- Planning documents establish a TypeScript/Next.js dashboard direction and a GSD MVP phase workflow.

### Integration Points
- New application code should be introduced from Phase 1.
- Generated `AGENTS.md` should guide future agents to preserve GSD workflow context.

</code_context>

<specifics>
## Specific Ideas

- The seeded dashboard should make “several students with different progress and traits” visible immediately.
- Student examples should feel like real drum lesson cases, including weak fills, inconsistent practice, demonstration-friendly learning, beginner rhythm basics, hobby song goals, and audition/practical-music preparation.
- The first screen should prove the database and seed data are wired by rendering actual sample student summaries, not just a static shell.

</specifics>

<deferred>
## Deferred Ideas

- Student-facing portal remains future scope.
- Scheduling automation remains future scope.
- Payments and invoices remain future scope.
- Audio/video analysis remains future scope.
- Full student detail read views remain Phase 2.
- Editing workflows remain Phase 3.
- Dashboard briefing polish remains Phase 4.

</deferred>

---

*Phase: 1-App Foundation And Data Model*
*Context gathered: 2026-05-22*
