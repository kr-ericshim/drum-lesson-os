# Phase 2: Student Roster And Detail Read Views - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 2-student-roster-and-detail-read-views
**Areas discussed:** Roster density, Student detail structure, Recent notes, State and exception UX

---

## Roster Density

| Option | Description | Selected |
|--------|-------------|----------|
| Existing row extended | Keep Phase 1 row shape with name, profile cue, current focus, weak point, assignment, and next action; make it clickable. | ✓ |
| Simpler list | Reduce the roster to name and current focus, leaving most context to detail. | |
| Card grid | Use stronger visual separation with student cards. | |

**User's choice:** A
**Notes:** Preserve the fast-scan instructor CRM feel from Phase 1.

---

## Student Detail Structure

| Option | Description | Selected |
|--------|-------------|----------|
| One-page sections | Show summary, progress, traits, assignments, next plan, and notes as stacked sections. | |
| Tabs | Use tabs such as Summary, Progress, and Notes to organize dense read-only context. | ✓ |
| Timeline centered | Make recent notes and progress records the primary time-ordered reading experience. | |

**User's choice:** B
**Notes:** Detail should stay read-only in Phase 2 and use tabs to reduce density pressure.

---

## Recent Notes

| Option | Description | Selected |
|--------|-------------|----------|
| Recent 3 notes | Show the latest 3 notes by lesson_date descending with covered, observations, practice, and next hint. | ✓ |
| Recent 5 notes | Show up to 5 notes in detail. | |
| One featured note | Emphasize the latest note and collapse the rest. | |

**User's choice:** A
**Notes:** Reverse chronological order is required by NOTE-03.

---

## State And Exception UX

| Option | Description | Selected |
|--------|-------------|----------|
| Quiet workbench states | Handle no students, missing id, missing Supabase env, and query failure with readable empty/error states in the same visual tone. | ✓ |
| Developer debug focus | Surface setup and error details more aggressively. | |
| Minimal handling | Cover only not-found and empty roster for now. | |

**User's choice:** A
**Notes:** Keep the app feeling like a teaching tool even when data is unavailable.

---

## the agent's Discretion

- Exact route names, tab implementation, and component boundaries may be chosen during planning.
- The planner may decide whether the whole row is a link or a focused open affordance, provided accessibility remains clear.

## Deferred Ideas

- Search/filtering, editing, dashboard briefing polish, student portal, scheduling, payments, and media analysis remain out of Phase 2.
