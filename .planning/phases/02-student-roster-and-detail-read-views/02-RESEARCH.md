# Phase 2: Student Roster And Detail Read Views - Research

**Researched:** 2026-05-25
**Domain:** Next.js App Router read-only roster/detail workflow backed by Supabase seed data
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md and UI-SPEC.md)

### Locked Decisions

- **D-01:** Keep the Phase 1 roster row structure and extend it into a clickable read-view roster.
- **D-02:** Roster rows continue surfacing name, profile cue, current focus, primary weak point, assignment status, and next lesson action.
- **D-03:** Roster stays compact and workbench-like, without marketing dashboard or decorative card grid patterns.
- **D-04:** Student detail uses a tabbed structure.
- **D-05:** Summary tab brings current progress, traits, weak points, assignment status, and next lesson plan together.
- **D-06:** Tabs organize dense read-only context without hiding the pre-lesson memory.
- **D-07:** Show the most recent 3 lesson notes.
- **D-08:** Lesson notes sort by `lesson_date` descending.
- **D-09:** Each note shows `covered_material`, `observations`, `practice_assigned`, and `next_step_hint`.
- **D-10:** Empty and error states preserve the quiet instructor workbench tone.
- **D-11:** Handle no students, missing student id, missing Supabase env, and query failure as distinct states.
- **D-12:** Error states can expose setup detail without becoming debug-console screens.

### Deferred Ideas

- Search/filtering.
- Create/edit workflows.
- Dashboard briefing polish.
- Student portal, scheduling, payments, and media analysis.
</user_constraints>

<architectural_responsibility_map>
## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Active student roster | Next.js server route | Supabase query layer | Roster is read-only and can render from server data using the existing env-gated pattern. |
| Detail route | Next.js App Router | Supabase query layer | `students/[studentId]` should own route-level not-found/error states and pass normalized data to components. |
| Detail tabs | Browser component | Local shadcn/Radix primitive | Tabs require client interactivity and keyboard behavior; keep the content data server-loaded. |
| Note ordering | Supabase query layer | UI component | Query should request lesson notes in `lesson_date` descending order and cap to 3. |
| Workbench states | UI components | Env helper and query result shape | Existing setup-aware empty/error patterns should be reused. |
</architectural_responsibility_map>

<research_summary>
## Summary

Phase 2 can build directly on Phase 1 without schema changes. The schema already includes all entities the detail view needs: `students`, `progress_items`, `student_traits`, `lesson_notes`, `assignments`, and `next_lesson_plans`.

The safest implementation path is:

1. Expand the Supabase query module with typed read models for roster rows and full student detail.
2. Turn the existing roster preview into a real roster surface with links to a detail route.
3. Add a new App Router detail route that renders a tabbed read-only student record.
4. Verify recent notes ordering and read-state behavior with build/lint plus source assertions.

No database migration is needed in Phase 2 unless implementation discovers a missing index or field. Current migration already has `lesson_notes_student_date_idx` and ownership-aware foreign keys.
</research_summary>

<existing_patterns>
## Existing Patterns To Reuse

### Setup-Aware Server Rendering

`src/app/page.tsx` reads `getSupabaseSetupStatus()` before querying. Phase 2 should reuse that pattern for roster and detail screens:

- if env is missing, do not call Supabase
- render a readable setup state
- keep the page usable for local setup

### Query Module Boundary

`src/lib/supabase/queries.ts` already normalizes raw Supabase rows into UI-ready DTOs. Phase 2 should add:

- `StudentRosterItem`
- `StudentDetail`
- `StudentProgressItem`
- `StudentTrait`
- `StudentLessonNote`
- `StudentAssignment`
- `StudentNextLessonPlan`
- `getStudentRoster()`
- `getStudentDetail(studentId: string)`

### Roster Row Component

`StudentSummaryRow` already has:

- assignment status label/variant mapping
- compact column layout
- field label conventions
- current focus / weak point / next lesson labels

Phase 2 should preserve this and add navigation behavior.

### Styling

`src/app/globals.css` already defines the Phase 1 token system:

- background `#F7F7F2`
- ink `#242520`
- primary `#8E3B46`
- support accent `#7A8B73`
- warm marker `#B78A35`
- radius `8px`

New detail components should not introduce new global visual systems.
</existing_patterns>

<recommended_structure>
## Recommended File Structure

```text
src/
├── app/
│   ├── page.tsx
│   └── students/
│       └── [studentId]/
│           └── page.tsx
├── components/
│   ├── dashboard/
│   │   ├── student-roster-preview.tsx
│   │   └── student-summary-row.tsx
│   ├── students/
│   │   ├── student-detail-header.tsx
│   │   ├── student-detail-tabs.tsx
│   │   ├── student-summary-panel.tsx
│   │   ├── student-progress-list.tsx
│   │   └── student-notes-list.tsx
│   └── ui/
│       └── tabs.tsx
└── lib/
    └── supabase/
        └── queries.ts
```

The planner may split exact components differently, but route, query, and tab responsibilities should stay clear.
</recommended_structure>

<data_requirements>
## Data Requirements

### Roster

Roster rows need:

- `students.id`
- `students.name`
- `students.profile_cue`
- `students.current_focus`
- `students.primary_weak_point`
- latest assignment status from `assignments`
- highest-priority/latest next action from `next_lesson_plans`

### Detail

Student detail needs:

- base student fields
- progress items ordered by `current_focus desc`, then `observed_on desc`
- traits grouped by `trait_type`
- latest assignment or visible assignment list
- next lesson plan, prioritizing `high`, then latest created/planned date
- lesson notes ordered by `lesson_date desc`, limited to 3

No write operations are in scope.
</data_requirements>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Building Edit Workflows Early

**What goes wrong:** Detail view adds forms, mutations, or save buttons.
**How to avoid:** Keep Phase 2 components read-only. Phase 3 owns editing.

### Pitfall 2: Hiding Summary Context Behind Tabs

**What goes wrong:** Tabs organize content, but the default tab does not answer the pre-lesson memory question.
**How to avoid:** Summary tab must include current progress, traits/weak points, assignment status, and next plan.

### Pitfall 3: Client-Side Data Fetching Drift

**What goes wrong:** Detail tabs fetch each section separately in the browser and duplicate setup/error handling.
**How to avoid:** Load detail data in the App Router server page, then pass normalized data into client tabs.

### Pitfall 4: Recent Notes Order Is Only Visual

**What goes wrong:** UI appears sorted but query does not enforce `lesson_date desc`.
**How to avoid:** Add ordering in `getStudentDetail` and source assertions for `.order("lesson_date", { ascending: false })` or an equivalent deterministic sort.

### Pitfall 5: Adding a New Visual System

**What goes wrong:** Detail page introduces generic SaaS cards, new colors, or hero typography.
**How to avoid:** Reuse Phase 1 tokens, labels, density, and 8px radius constraints.
</common_pitfalls>

<verification_guidance>
## Verification Guidance

- `npm run build` must pass.
- `npm run lint` must pass.
- Source should include a detail route at `src/app/students/[studentId]/page.tsx`.
- Source should include a tabs primitive or accessible tab component.
- `getStudentDetail` should cap notes to 3 and order by `lesson_date` descending.
- Roster should link to `/students/{id}` or an equivalent App Router path.
- Search source to confirm Phase 2 does not introduce create/edit forms or mutation calls.
</verification_guidance>
