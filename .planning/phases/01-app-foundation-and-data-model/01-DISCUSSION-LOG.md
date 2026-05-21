# Phase 1: App Foundation And Data Model - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-22
**Phase:** 1-App Foundation And Data Model
**Areas discussed:** Storage and execution scope, Data model structure, Sample data realism, First screen minimum

---

## Storage And Execution Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Fully local-first MVP | Use SQLite and Prisma for speed; add ownership/workspace later if needed. | |
| Local-first with ownership path | Start locally but include owner/workspace boundaries for easier hosted migration. | |
| Hosted from the start | Plan around Supabase/Postgres, instructor ownership, and RLS from Phase 1. | ✓ |

**User's choice:** Hosted from the start.
**Notes:** User selected the hosted approach over the recommended local-first-with-ownership path. The decision was then grounded against Supabase Auth and RLS official docs. Student portal remains out of scope.

---

## Data Model Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Loose note-centered model | Mostly free text notes and recent lesson records. | |
| Hybrid model | Structure dashboard-critical fields while leaving lesson detail flexible. | ✓ |
| Highly structured model | Strict enums/tables for most progress, weakness, learning style, and lesson data. | |

**User's choice:** Hybrid model.
**Notes:** This supports dashboard summaries without making drum lesson reality too rigid.

---

## Sample Data Realism

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal sample data | Two or three students, mostly to prove the schema works. | |
| MVP demo data | Five to seven students with distinct teaching situations. | ✓ |
| Rich long-history data | Eight or more students with multiple lesson-history records each. | |

**User's choice:** MVP demo data.
**Notes:** Seed data should make the dashboard useful immediately and show varied students, not generic placeholders.

---

## First Screen Minimum

| Option | Description | Selected |
|--------|-------------|----------|
| App shell only | Base layout, title, and empty state. | |
| Sample student dashboard preview | Render seeded students with current focus, weak point, assignment status, and next action. | ✓ |
| Near Phase 2 read view | Include roster plus partial student detail views in Phase 1. | |

**User's choice:** Sample student dashboard preview.
**Notes:** User replied `dd`, interpreted as agreement with the recommended second option. The assistant reflected that assumption and the user approved proceeding.

---

## the agent's Discretion

- Exact schema names and enum values may be chosen during planning.
- Exact Supabase/Prisma query boundary may be chosen during planning.
- Exact dashboard preview layout may be chosen during planning as long as it remains a sample-data-backed roster preview and does not absorb full Phase 2 detail scope.

## Deferred Ideas

- Student-facing portal.
- Scheduling automation.
- Payments and invoices.
- Audio/video analysis.
- Full student detail read views.
- Editing workflows.
- Dashboard briefing polish.
