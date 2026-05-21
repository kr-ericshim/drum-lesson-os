---
phase: 1
slug: app-foundation-and-data-model
status: approved
shadcn_initialized: false
preset: custom-instructor-workbench
created: 2026-05-22
---

# Phase 1 — UI Design Contract

> Visual and interaction contract for the Phase 1 walking skeleton. Generated inline because GSD UI agents are not installed in this runtime.

---

## Design Intent

Phase 1 must feel like a real instructor workbench, not a SaaS landing page and not a generic AI dashboard. The first screen should communicate: "I can open this before a lesson and remember what matters about each student."

Use the Huashu-Design principle the user requested: avoid AI slop. The UI must not rely on purple gradients, emoji icons, decorative icon spam, fake stats, oversized hero sections, nested cards, or generic "beautiful dashboard" patterns. Every visible element earns its place by helping the instructor scan student progress, weak points, assignment status, or next action.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | shadcn/ui |
| Preset | custom-instructor-workbench |
| Component library | Radix via shadcn/ui |
| Icon library | lucide-react |
| Font | `IBM Plex Sans` for body/interface, `Newsreader` for restrained display labels only |

### Required shadcn Components

- `button`
- `badge`
- `card`
- `separator`
- `table`
- `tabs` only if needed for preview organization
- `skeleton` only for loading states

### UI Personality

- **Working surface**: compact, calm, readable, built for repeated use.
- **Music-specific but not themed**: subtle rhythm/ledger cues are allowed; drum clipart, music-note wallpaper, and decorative staff-line backgrounds are not.
- **Human but precise**: student details should feel like teaching memory, not analytics theater.

---

## Phase 1 Screen Contract

### First Screen

The first screen is a seeded student dashboard preview backed by database data.

It must include:

- App title: `Drum Lesson OS`
- Small context line: `Student progress, traits, and next lesson cues`
- Student roster preview with 5-7 seeded students
- For each visible student:
  - name
  - current focus
  - primary weak point or caution
  - assignment status
  - next lesson action
- A small system/state area showing hosted data foundation status, such as `Supabase connected` or a clear local setup fallback if env vars are missing

It must not include:

- Marketing hero copy
- Fake revenue/productivity stats
- Student portal CTAs
- Billing/scheduling navigation
- Full student detail panels; those belong to Phase 2

### Layout

- Desktop: two-column workbench layout.
  - Left/main: student roster preview.
  - Right/supporting: foundation/status panel and seed-data notes.
- Mobile: single-column stacked layout.
  - Status panel follows the roster.
  - Student rows become compact cards only on narrow screens.
- No cards inside cards.
- Cards may be used for individual students or status panels only.
- Card radius must be 8px or less.

### Student Row/Card Content

Each student item should use a stable structure:

1. Student name and brief profile cue
2. Current focus
3. Weak point/caution
4. Assignment status badge
5. Next action text

Keep every row scannable. Do not make each student item a decorative tile with unrelated icons.

---

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Badge gaps, inline metadata gaps |
| sm | 8px | Compact row padding, icon/text gaps |
| md | 16px | Default element spacing |
| lg | 24px | Panel padding, section rhythm |
| xl | 32px | Page columns and major groups |
| 2xl | 48px | Top-level page breathing room |
| 3xl | 64px | Rare; only for wide desktop outer spacing |

Exceptions: none

### Density Rules

- Student list is allowed to be information-dense.
- Density must come from useful teaching context, not icons or decorative labels.
- Keep row heights stable so assignment badges or long weak-point text do not shift the layout unexpectedly.
- Use line clamping for roster preview text where needed; full details wait for Phase 2.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 15px | 400 | 1.55 |
| Label | 12px | 600 | 1.3 |
| Heading | 22px | 650 | 1.2 |
| Display | 30px | 500 | 1.1 |

### Typography Rules

- Body and interface text use `IBM Plex Sans`.
- `Newsreader` is allowed only for the product title or one quiet section label; do not use it for dense row text.
- Letter spacing is `0`.
- Do not scale font sizes with viewport width.
- Headings inside panels must stay compact; no hero-scale typography inside dashboard panels.
- Use `text-wrap: pretty` for headings and empty-state text.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#F7F7F2` | Page background, quiet workspace base |
| Secondary (30%) | `#FFFFFF` | Student rows, panels, controls |
| Ink | `#242520` | Primary text |
| Muted Ink | `#6A6D63` | Supporting metadata |
| Border | `#DAD8CD` | Separators and panel borders |
| Accent (10%) | `#8E3B46` | Current focus markers, selected state, primary action |
| Support Accent | `#7A8B73` | Stable/complete statuses |
| Warm Marker | `#B78A35` | Needs-review/assignment attention badges |
| Destructive | `#B42318` | Destructive actions only |

Accent reserved for:

- Current focus marker
- Primary action button
- Selected navigation state
- Important attention badge

### Color Rules

- No purple or purple-blue gradients.
- No decorative gradient orbs.
- No one-note beige/brown theme. Warm background must be balanced by ink, sage, oxblood, and brass accents.
- Status colors must carry semantic meaning:
  - `#7A8B73` for steady/complete
  - `#B78A35` for needs review
  - `#8E3B46` for current focus or important attention
  - `#B42318` only for destructive or critical error states
- Do not use accent color on every interactive element.

---

## Interaction Contract

### Phase 1 Allowed Interactions

- Student preview rows may have hover/focus affordance, but do not need to navigate yet unless routing is already trivial.
- Primary setup action may link to developer setup guidance if Supabase env vars are missing.
- Loading state can use simple skeleton rows.
- Empty state should explain missing seed data and point to the seed command.

### Phase 1 Not Yet Required

- Full student detail navigation
- Editing student data
- Filtering/search
- Scheduling/billing actions
- Student portal actions

### States

Required states:

- seeded data loaded
- no students found
- Supabase/env not configured
- database query failed
- loading

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | `Review setup` |
| Empty state heading | `No students loaded yet` |
| Empty state body | `Run the seed step to preview the instructor dashboard with realistic lesson data.` |
| Error state | `Student data could not be loaded. Check Supabase environment variables and database access.` |
| Destructive confirmation | Not used in Phase 1 |

### Voice

- Plain working language.
- No marketing claims.
- No motivational filler.
- No AI-ish phrasing such as `unlock your teaching potential`, `supercharge lessons`, or `seamless experience`.
- Labels should sound like a teacher's working memory: `Current focus`, `Weak point`, `Assignment`, `Next lesson`.

---

## Anti-Slop Rules

These are blocking design rules for Phase 1:

- No oversized hero section.
- No generic purple/blue gradient dashboard.
- No emoji as icons.
- No decorative icon beside every label.
- No fake KPI cards unless the value directly comes from seed data and helps lesson prep.
- No cards nested inside cards.
- No SVG drum illustrations or decorative music-note backgrounds.
- No stock-photo teacher/student imagery.
- No text explaining how to use the UI inside the main app surface.
- No page section styled as a floating card; only individual repeated student items and status panels may be card-like.

---

## Accessibility And Responsive Contract

- All interactive controls must have visible focus states.
- Text contrast must meet WCAG AA.
- Assignment/status badges must not rely on color alone; include text labels.
- Student rows must not overflow or overlap at 320px mobile width.
- Long student names, weak points, and next actions must clamp or wrap safely.
- Touch targets on mobile must be at least 44px tall where interactive.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | button, badge, card, separator, table, tabs, skeleton | not required |
| third-party registry | none | not allowed in Phase 1 without review |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-05-22
