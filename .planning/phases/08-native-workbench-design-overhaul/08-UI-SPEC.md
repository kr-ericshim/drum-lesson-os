# Phase 8 Native Workbench UI Spec

**Status:** Draft design spec for a future implementation phase.
**Date:** 2026-05-28.

## Product Design Goal

Drum Lesson OS should feel like a native macOS workbench for a drum instructor:

- fast to scan before a lesson,
- calm enough for repeated daily use,
- warm enough to feel teaching-specific,
- structured enough that the next action is obvious.

The target quality is not a marketing redesign. It is a trustworthy product UI where the instructor can open the app and know what to do next in under 30 seconds.

## Design Assumptions

- Primary platform is macOS SwiftUI.
- The instructor often uses the app near lessons, sometimes in a dim studio.
- The app has a small amount of high-value data, not a huge enterprise dataset.
- Native controls are preferred unless a custom component materially improves scan speed.
- Light and dark appearance both need to work. The current screenshots were dark mode, but Phase 8 should not hardcode a dark-only theme.
- Demo content can stay Korean, but product labels should be reviewed before implementation.

## Visual System

### Theme

Use system-adaptive neutrals and materials as the base.

Recommended role names:

- `AppTheme.Surface.window`
- `AppTheme.Surface.canvas`
- `AppTheme.Surface.panel`
- `AppTheme.Surface.inspector`
- `AppTheme.Surface.fieldGroup`
- `AppTheme.Border.subtle`
- `AppTheme.Border.selected`
- `AppTheme.Semantic.success`
- `AppTheme.Semantic.warning`
- `AppTheme.Semantic.error`
- `AppTheme.Semantic.pending`
- `AppTheme.Accent.teaching`

Use one teaching accent, preferably warm amber/rust. It should mark "the thing to check next" and assignment attention, not every decorative element.

### Typography

Keep system typography.

Recommended scale:

- Window/page title: `.title2.weight(.semibold)` or native navigation title.
- Primary action/brief: `.title3.weight(.semibold)` or `.title2.weight(.semibold)` depending on available width.
- Section title: `.headline`.
- Card/list title: `.subheadline.weight(.semibold)`.
- Metadata: `.caption` or `.caption2`, often monospaced for times/dates.
- Long context: `.subheadline` with `.secondary`.

Avoid using `.largeTitle` inside repeated workbench panels. Reserve it for top-level identity moments like student header if it does not crowd the workflow.

### Spacing

Current spacing is too even. Phase 8 should create rhythm.

Recommended values:

- Screen outer padding: 20-24.
- Canvas internal padding: 16-20.
- Inspector internal padding: 16.
- Tight metadata stacks: 3-6.
- Related controls: 8-10.
- Section groups: 16-20.
- Major screen bands: 24.

## Component Vocabulary

### `WorkbenchSurface`

Replacement or expansion of the current `WorkbenchPanel`.

Variants:

- `canvas`: main schedule or main student memory region.
- `panel`: ordinary grouped content.
- `inspector`: selected item/action area.
- `quiet`: low-emphasis supporting content.
- `editor`: form/editing surface.

Acceptance:

- A screen should not look like a grid of identical cards.
- At least one primary surface should be visually dominant on dashboard and student detail.

### `WorkbenchHeader`

A section header with optional metadata and toolbar slot.

Should support:

- title,
- subtitle,
- optional status badge,
- optional trailing actions.

### `StatusPill`

Replacement or refinement of `StatusBadge`.

States:

- synced,
- pending,
- failed,
- not connected,
- needs review,
- in progress,
- complete,
- inactive.

Rules:

- Use semantic color only when state matters.
- Avoid making every state saturated.
- Long labels must truncate cleanly.

### `ActionBar`

Used in selected lesson and forms.

Rules:

- One primary action.
- Secondary actions grouped after primary.
- Destructive action visually separated.
- Loading state visible and disabled state consistent.

### `LessonBriefCard`

The first-check component should become the strongest reusable domain component.

Content:

- student name or lesson context,
- first check,
- weak point,
- assignment cue if present,
- recent observation if useful.

Rules:

- First check should be visually dominant.
- Assignment cue can use teaching accent.
- Avoid overloading with all student data.

### `EditorGroup`

A collapsed or segmented editing unit for lower-priority maintenance.

Recommended behavior:

- Student detail shows one or two high-frequency editors by default.
- Other editors sit behind disclosure or a segmented picker.
- Save buttons remain near the fields they save.
- Editing should not hide the lesson brief or memory view.

## Dashboard Target Layout

### Wide Window

Use a main canvas plus right inspector.

Structure:

1. Native toolbar:
   - Previous week.
   - Today.
   - Next week.
   - Add lesson.
   - Optional sync status.
2. Content:
   - Left: week/today schedule canvas.
   - Right: selected lesson inspector.
3. Supporting roster:
   - Inside right column below selected lesson, or below the schedule canvas if it needs more width.

Recommended proportions:

- Schedule canvas: flexible, minimum around 620.
- Inspector: 320-400.

Selected lesson inspector should include:

- student,
- date/time/duration,
- first check,
- assignment cue,
- sync status/error/retry,
- Start Lesson primary action,
- Edit secondary action,
- Cancel separated/destructive.

### Medium Window

Use vertical stacking:

1. Today list or compact week strip.
2. Selected lesson action panel.
3. Roster.

### Compact Window

Prioritize today's lessons.

Order:

1. Today header/actions.
2. Today lesson list.
3. Selected lesson actions.
4. Roster.

The seven-column week grid should not be forced into compact width.

## Student Detail Target Layout

### Top Band

Student identity and teaching cue.

Content:

- name,
- current focus/status,
- profile cue,
- watch point.

This should feel like a compact lesson cue card, not a giant profile page.

### Lesson Flow Band

Replace equal cards with a guided sequence.

Recommended structure:

- Left or top: `First Check`, visually primary.
- Middle: `Run Notes`, active capture area.
- Right or lower: `Closeout`, disabled/quiet until a draft exists.

If width is limited, stack:

1. First Check.
2. Run Notes.
3. Closeout.

The sequence labels can be:

- Check.
- Capture.
- Close.

Use numbered or subtle step treatment only if it improves clarity.

### Teaching Memory

Read-only context should appear before broad maintenance editors.

Content:

- current progress,
- assignment,
- next action,
- traits,
- recent notes.

This can remain tabbed, but the tab area should feel connected to the student, not like a leftover panel at the bottom.

### Maintenance Editing

Current `Teaching Workbench` should become lower emphasis.

Recommended options:

1. `DisclosureGroup` list:
   - Profile.
   - Trait.
   - Progress.
   - Assignment.
   - Lesson Note.
   - Next Plan.
2. Segmented editor:
   - Profile
   - Progress
   - Lesson
   - Admin
3. Inspector-style editor:
   - selected edit mode appears in a right inspector.

Recommended for Phase 8:

- Start with disclosure groups or segmented editor.
- Avoid a six-column adaptive grid as the default visible state.

## Settings Target Layout

Settings should feel like configuration.

Recommended structure:

- Use native `Form` where possible.
- Group sections:
  - Apple Calendar permission.
  - Writable calendar selection.
  - Sync queue and retry.
  - Account.
- Make sign out clearly separated at the bottom.

Potential later improvement:

- Move settings to a dedicated SwiftUI `Settings` scene if the app grows beyond MVP.

## Copy Direction

Use plain task-oriented labels.

Potential label changes:

- `Calendar Workbench` -> `Schedule`
- `Add Lesson` -> keep, clear.
- `First Check` -> `First thing to check` or keep if the product tone prefers compact English.
- `Run Notes` -> `Lesson notes draft` or `During lesson`.
- `Use in Closeout` -> `Prepare closeout`.
- `Teaching Workbench` -> `Edit teaching record`.
- `Calendar pending` -> `Pending sync`.
- `Calendar not connected` -> `Calendar off`.

Avoid internal implementation phrasing in the main UI:

- "Supabase schedule data"
- "Occurrence"
- raw UUID fragments except in debug or support surfaces.

## Accessibility And Resizing

Acceptance:

- Window minimum remains usable at current app minimum width.
- No text overlap in dark or light appearance.
- Buttons have accessible labels.
- Icon-only toolbar buttons have `.help` and `.accessibilityLabel`.
- Status colors are supported by text labels.
- Long Korean demo content truncates intentionally with line limits or wraps inside stable areas.

## Implementation Notes

Candidate file targets:

- `DrumLessonOS/DesignSystem/Tokens/AppTheme.swift`
- `DrumLessonOS/DesignSystem/Components/StatusBadge.swift`
- New design-system components under `DrumLessonOS/DesignSystem/Components/`
- `DrumLessonOS/Features/Dashboard/DashboardView.swift`
- `DrumLessonOS/Features/Dashboard/WeekCalendarView.swift`
- `DrumLessonOS/Features/Dashboard/LessonEventCard.swift`
- `DrumLessonOS/Features/Dashboard/SelectedLessonPanel.swift`
- `DrumLessonOS/Features/Students/StudentHeaderView.swift`
- `DrumLessonOS/Features/LessonFlow/LessonFlowWorkspace.swift`
- `DrumLessonOS/Features/Students/StudentDetailView.swift`
- `DrumLessonOS/Features/Students/StudentDetailTabs.swift`
- `DrumLessonOS/Features/Settings/SettingsView.swift`

Avoid changing repositories, RPC clients, migrations, or persistence models unless a UI compile issue exposes a necessary type refinement.

## Visual Acceptance Criteria

Phase 8 is ready when:

1. Dashboard has one clear primary work area and one clear selected lesson action area.
2. Student detail shows the next teaching action before broad editing controls.
3. The six-editor form wall is removed or demoted.
4. Settings reads as configuration.
5. Shared component vocabulary is documented in code through named variants or reusable components.
6. Dark and light appearance both remain legible.
7. Computer Use smoke confirms dashboard, student detail, settings, add lesson, edit occurrence, and add student remain reachable.
