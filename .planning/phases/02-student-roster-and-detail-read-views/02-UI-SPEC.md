---
phase: 2
slug: student-roster-and-detail-read-views
status: approved
shadcn_initialized: true
preset: custom-instructor-workbench
created: 2026-05-25
---

# Phase 2 - UI Design Contract

> Visual and interaction contract for the Phase 2 read-only roster and student detail workflow. Generated inline because GSD UI agents are not installed in this runtime.

---

## Design Intent

Phase 2 should feel like opening a reliable lesson notebook before a student arrives. It extends the Phase 1 instructor workbench rather than introducing a new visual language.

The UI must help an instructor answer two questions quickly:

1. Which student am I looking at?
2. What should I remember before teaching them?

Avoid AI-dashboard aesthetics, purple gradients, decorative charts, fake productivity metrics, oversized hero copy, and card grids that make comparison slower. The product should feel calm, specific, and useful for repeated lesson prep.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Tailwind CSS v4 with shadcn-style local primitives |
| Preset | custom-instructor-workbench |
| Component library | Radix-compatible local shadcn/ui primitives |
| Icon library | lucide-react |
| Font | `IBM Plex Sans` for interface, `Newsreader` only for restrained display labels |

### Required Components

- `button`
- `badge`
- `card`
- `separator`
- `skeleton`
- `tabs`
- `table` only if progress or note metadata needs tighter alignment

### Existing Components To Extend

- `StudentRosterPreview` becomes the roster surface for active students.
- `StudentSummaryRow` becomes a clickable roster row or contains one clear open affordance.
- `SetupStatusPanel` remains available for Supabase setup states.

---

## Phase 2 Screen Contract

### Roster Screen

The roster screen must show all active students in a compact list, not a decorative grid.

Each row must include:

- student name
- profile cue
- current focus
- primary weak point
- assignment status badge
- next lesson action
- a clear link or affordance to open the student detail view

Rows should preserve Phase 1 density and comparison rhythm. On mobile, rows may stack into compact cards, but the information order must remain stable.

### Student Detail Screen

The student detail route must be read-only and tabbed.

Required structure:

- Header area: student name, profile cue, current focus, assignment status, next lesson action
- `Summary` tab: current progress highlights, traits, weak points, assignment, next plan
- `Progress` tab: progress items grouped or listed with category, status, title, observed date, and detail
- `Notes` tab: latest 3 lesson notes in reverse chronological order

The summary tab must be the default view. The instructor should not need to click into every tab to get the pre-lesson gist.

### Recent Notes

The notes view must show exactly the latest 3 notes by default, sorted by `lesson_date` descending.

Each note must show:

- lesson date
- covered material
- observations
- practice assigned
- next step hint

Use compact labels and restrained dividers. Do not turn notes into oversized editorial cards.

---

## Spacing Scale

Declared values, all multiples of 4:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Badge gaps, metadata gaps |
| sm | 8px | Compact inline spacing, tab label/icon gaps |
| md | 16px | Row internals, note field rhythm |
| lg | 24px | Panel padding, detail section gaps |
| xl | 32px | Page column and tab content gaps |
| 2xl | 48px | Top-level vertical breathing room |
| 3xl | 64px | Rare wide-screen page spacing |

Exceptions: none

### Density Rules

- Roster rows should remain stable in height on desktop.
- Detail sections may be denser than a marketing site, but labels and grouping must make scanning easy.
- Text should wrap or clamp intentionally; it must not overflow buttons, badges, tabs, or rows.
- Do not put cards inside cards.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 15px | 400 | 1.55 |
| Label | 12px | 600 | 1.3 |
| Detail heading | 18px | 650 | 1.25 |
| Page heading | 24px | 650 | 1.2 |
| Display | 30px | 500 | 1.1 |

### Typography Rules

- Body and interface text use `IBM Plex Sans`.
- `Newsreader` is allowed only for the product title or one restrained page label.
- Letter spacing is `0`.
- Do not scale font size with viewport width.
- Tab labels must remain compact and readable on mobile.
- Dense detail panels use `Detail heading`, not hero-scale type.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#F7F7F2` | Page background and quiet workspace base |
| Secondary (30%) | `#FFFFFF` | Rows, panels, tab content surfaces |
| Ink | `#242520` | Primary text |
| Muted Ink | `#6A6D63` | Labels, metadata, secondary notes |
| Border | `#DAD8CD` | Separators, row borders, tab dividers |
| Accent (10%) | `#8E3B46` | Current focus marker, selected tab, primary open action |
| Support Accent | `#7A8B73` | Steady or complete status |
| Warm Marker | `#B78A35` | Needs-review attention |
| Destructive | `#B42318` | Destructive or critical error only |

Accent reserved for:

- selected tab state
- current focus marker
- primary open action
- important attention badge

Do not use accent color on every link or label.

---

## Interaction Contract

### Required Interactions

- Roster rows must be keyboard reachable and clearly open the student detail route.
- Detail tabs must support keyboard navigation and visible selected state.
- Missing Supabase setup should show setup-aware empty state instead of a broken route.
- Missing or unknown student id should show a quiet not-found state with a route back to roster.
- Query failure should show a readable error state with a short setup/check message.

### Not Required In Phase 2

- Create/edit student data
- Search/filtering
- Scheduling or billing navigation
- Student portal actions
- Audio/video attachment preview

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Roster heading | `Student roster` |
| Roster helper | `Open a student to review progress, traits, notes, and next lesson cues.` |
| Open detail action | `Open student` |
| Detail summary tab | `Summary` |
| Detail progress tab | `Progress` |
| Detail notes tab | `Notes` |
| Empty roster heading | `No active students yet` |
| Empty roster body | `Add seed data or create students later to review lesson context here.` |
| Missing setup heading | `Supabase setup needed` |
| Missing setup body | `Add environment variables and run the seed step before loading student records.` |
| Missing student heading | `Student not found` |
| Missing student body | `Return to the roster and choose an active student.` |
| Query error heading | `Student data could not be loaded` |
| Query error body | `Check Supabase environment variables, database access, and seed state.` |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official/local primitives | button, badge, card, separator, skeleton, tabs, table if needed | Use existing local component patterns |
| third-party blocks | none | Do not add without explicit review |

---

## Responsive Contract

- Desktop roster: compact rows with stable columns.
- Desktop detail: constrained content width with tabs and readable section rhythm.
- Mobile roster: stacked row/card layout with the same information order.
- Mobile detail: tabs must remain usable without horizontal overflow; use compact labels if needed.
- Text must not overlap or overflow at common mobile widths.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-05-25
