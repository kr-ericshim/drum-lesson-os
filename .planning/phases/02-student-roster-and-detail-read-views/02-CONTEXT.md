# Phase 2: Student Roster And Detail Read Views - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase turns the Phase 1 roster preview into a read-only student browsing workflow. The instructor must be able to scan all active students, open one student, and read the lesson context needed before teaching: current progress, recent lesson notes, traits, weak points, assignment status, and next lesson plan.

This phase does not add create/edit workflows, search/filtering, student accounts, scheduling, billing, or dashboard briefing polish beyond what is needed to make the read views coherent.

</domain>

<decisions>
## Implementation Decisions

### Roster Density
- **D-01:** Keep the Phase 1 roster row structure and extend it into a clickable read-view roster instead of replacing it with a simplified list or decorative card grid.
- **D-02:** Roster rows should continue surfacing name, profile cue, current focus, primary weak point, assignment status, and next lesson action so the instructor can decide which student to open without losing the fast-scan workflow.
- **D-03:** The roster should feel like a compact instructor workbench. Avoid a marketing-style dashboard, fake metrics, large hero sections, or card grids that make comparison slower.

### Student Detail Structure
- **D-04:** Use a tabbed detail structure for the student page, with a default summary tab and separate readable areas for progress and notes.
- **D-05:** The summary view must still bring the important teaching context together: current progress, traits, weak points, assignment status, and next lesson plan should be visible without editing.
- **D-06:** Tabs should organize dense read-only context; they must not hide the core pre-lesson memory behind decorative navigation.

### Recent Notes
- **D-07:** Show the most recent 3 lesson notes on the student detail page.
- **D-08:** Recent notes must be ordered by `lesson_date` descending.
- **D-09:** Each visible note should show short, scannable fields for `covered_material`, `observations`, `practice_assigned`, and `next_step_hint`.

### State And Exception UX
- **D-10:** Preserve the quiet instructor workbench tone for empty and error states.
- **D-11:** Handle no students, missing student id, missing Supabase env, and query failure as distinct readable states.
- **D-12:** Error states may expose enough setup detail for local development, but they should not dominate the teaching workflow or turn the screen into a debug console.

### the agent's Discretion
- The planner may choose the exact tab component implementation, route segment names, and component boundaries as long as the read-only scope and tabbed detail structure are preserved.
- The planner may decide whether the roster row itself is a link or contains a single explicit open affordance, provided keyboard and screen-reader navigation remain clear.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope
- `.planning/PROJECT.md` — Defines the instructor-side MVP, core value, and scope boundaries.
- `.planning/REQUIREMENTS.md` — Defines Phase 2 requirements ROST-01, STUD-01, STUD-02, and NOTE-03.
- `.planning/ROADMAP.md` — Defines Phase 2 goal, success criteria, MVP mode, dependencies, and plan outline.
- `.planning/STATE.md` — Tracks Phase 1 completion and current project position.
- `AGENTS.md` — Defines repository-specific working rules and response/reporting expectations.

### Prior Phase Decisions
- `.planning/phases/01-app-foundation-and-data-model/01-CONTEXT.md` — Locks Supabase/Postgres ownership, hybrid data model, seed data, and Phase 1/2 boundary decisions.
- `.planning/phases/01-app-foundation-and-data-model/01-UI-SPEC.md` — Defines the instructor workbench visual language, density rules, color system, and anti-AI-slop constraints to carry forward.
- `.planning/phases/01-app-foundation-and-data-model/01-03-SUMMARY.md` — Records the dashboard preview patterns that Phase 2 should extend.

### Existing Code
- `src/app/page.tsx` — Current setup-aware dashboard route and roster preview entry point.
- `src/components/dashboard/student-roster-preview.tsx` — Existing roster state wrapper, loading state, empty state, and error state.
- `src/components/dashboard/student-summary-row.tsx` — Existing compact student row structure and assignment badge mapping.
- `src/lib/supabase/queries.ts` — Existing Supabase server query pattern and preview DTO mapping.
- `src/types/database.ts` — Generated database shape used by Supabase clients.
- `supabase/migrations/0001_foundation.sql` — Source of truth for tables, fields, relationships, indexes, and RLS policies.
- `src/app/globals.css` — Existing design tokens, field labels, row sizing, and line-clamp helpers.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `StudentRosterPreview` can evolve from a preview surface into the Phase 2 roster container.
- `StudentSummaryRow` already encodes the row density, assignment badge status mapping, and roster comparison layout.
- `getStudentDashboardPreview` shows the current Supabase server query pattern and setup-aware data flow.
- Existing UI primitives include `Badge`, `Button`, `Card`, `Separator`, `Skeleton`, and `Table`.

### Established Patterns
- The dashboard route gates Supabase queries on env setup status and renders local setup/empty states when configuration is missing.
- Student rows use fixed labels for `Current focus`, `Weak point`, `Assignment`, and `Next lesson`.
- Current styling uses Tailwind v4 tokens from `globals.css`, compact 8px-radius cards/rows, line clamping, and quiet labels.

### Integration Points
- Phase 2 should add a student detail route under the App Router and link roster rows to it.
- Data loading should stay server-side for read views and reuse typed Supabase clients.
- Detail queries should use the existing schema: `students`, `progress_items`, `student_traits`, `lesson_notes`, `assignments`, and `next_lesson_plans`.

</code_context>

<specifics>
## Specific Ideas

- Roster should keep the Phase 1 teaching-memory row shape and become clickable.
- Student detail should use tabs, with summary first and progress/notes separated for readability.
- Recent notes should show exactly 3 notes by default and make reverse chronological order visible.
- Empty and error states should feel like part of the instructor workbench, not a developer console.

</specifics>

<deferred>
## Deferred Ideas

- Search and filtering remain outside Phase 2 unless later promoted to roadmap scope.
- Create/edit workflows remain Phase 3.
- Dashboard briefing polish and stronger current-focus indicators remain Phase 4.
- Student-facing portal, scheduling, payments, and audio/video analysis remain future scope.

</deferred>

---

*Phase: 2-Student Roster And Detail Read Views*
*Context gathered: 2026-05-25*
