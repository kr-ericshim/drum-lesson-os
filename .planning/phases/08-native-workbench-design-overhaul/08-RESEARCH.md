# Phase 8 Native Workbench Design Overhaul Research

**Status:** Research and phase-shaping only.
**Date:** 2026-05-28.
**Scope:** macOS SwiftUI app visual hierarchy, layout grammar, component system, and task-flow ergonomics. No behavior or data-model changes are assumed.

## Inputs Reviewed

- Live `DrumLessonOS` app through Computer Use:
  - Dashboard / calendar workbench.
  - Student detail / lesson flow / teaching workbench.
  - Settings / calendar sync.
- Current SwiftUI implementation:
  - `DrumLessonOS/App/RootView.swift`
  - `DrumLessonOS/DesignSystem/Tokens/AppTheme.swift`
  - `DrumLessonOS/DesignSystem/Components/StatusBadge.swift`
  - `DrumLessonOS/Features/Dashboard/*`
  - `DrumLessonOS/Features/Students/*`
  - `DrumLessonOS/Features/LessonFlow/LessonFlowWorkspace.swift`
  - `DrumLessonOS/Features/Settings/SettingsView.swift`
  - `DrumLessonOS/Features/Scheduling/ScheduleLessonSheet.swift`
- Project direction:
  - `.planning/ROADMAP.md`
  - `.planning/STATE.md`
  - `.planning/phases/07-swiftui-native-migration/*`
- Reference guidance:
  - Apple HIG: [Split views](https://developer.apple.com/design/human-interface-guidelines/split-views)
  - Apple HIG: [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
  - Apple Developer: [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
  - Apple Developer: [SwiftUI](https://developer.apple.com/documentation/swiftui)
  - Apple WWDC23: [Inspectors in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10161/)
  - Build macOS Apps skill: SwiftUI split view, sidebar, toolbar, inspector, and system-adaptive surface guidance.
  - Huashu-design / product UI critique principles: avoid generic card grids, use real workflow hierarchy, keep product UI familiar and trustworthy.

## Current Design Diagnosis

The app is functionally coherent, but the visual system is still at implementation-candidate quality. The core issue is not a broken layout model. The issue is that every surface uses nearly the same panel, spacing, button weight, and typographic scale, so the instructor cannot immediately tell what deserves attention.

### Dashboard

Observed live screen:

- Large dark empty areas dominate the first impression.
- The week grid, selected lesson panel, and roster all use similar panel weight.
- The selected lesson is visually smaller than its product importance.
- Lesson cards carry useful content, but the time, student, first check, sync state, and assignment flag compete in a narrow vertical card.
- Week navigation and add lesson live inside the content header instead of the native toolbar area, making the screen feel more like a web dashboard embedded in a Mac window.
- The roster is useful but visually reads as a second panel, not as supporting context for the selected lesson.

Root cause:

- `DashboardView` uses one two-column `HStack` with fixed-ish proportions and a shared `WorkbenchPanel` for all major regions.
- `WeekCalendarView` draws seven equal columns even when only one day has meaningful data, which creates a lot of low-value space.
- `SelectedLessonPanel` is the workflow decision point, but it has the same container weight as the roster.

### Student Detail

Observed live screen:

- The student header is clean but isolated from the lesson workflow below it.
- `First Check`, `Run Notes`, and `Closeout` are correct product concepts, but they appear as three equal cards, even though the first action should lead.
- The editing workbench exposes six editors at once. It becomes a form wall: profile, trait, progress, assignment, note, and next plan compete at the same level.
- Text fields and buttons visually dominate the student context, so the page feels like a database admin form rather than a lesson assistant.
- The tabs underneath are likely useful, but they appear after the dense edit grid, so read-only memory gets pushed below the maintenance controls.

Root cause:

- `LessonFlowWorkspace` uses a simple `HStack` of equal cards.
- `StudentDetailEditorPanel` uses an adaptive grid that makes every editor equally visible.
- There is no editorial hierarchy between "what to do now", "what to record during the lesson", "what to save later", and "maintenance edits".

### Settings

Observed live screen:

- Settings is simple and not broken.
- It still uses the same `WorkbenchPanel` card style, which makes it feel like another dashboard page instead of a native settings/configuration surface.
- Calendar authorization, selected calendar, sync queue, and sign out need clearer state grouping.

Root cause:

- `SettingsView` is a plain scroll of panels.
- It does not use native `Form`, settings scene conventions, or a left/right preferences structure.

## Reference-Based Design Principles

### 1. Keep The Native Mac Shell

Apple's split view guidance supports a sidebar for top-level navigation and detail/content panes for the selected area. The app already has the correct shell direction with `NavigationSplitView`.

Phase 8 should improve the shell, not replace it with a custom full-screen web-style layout.

Implications:

- Keep native sidebar selection.
- Put global view actions in toolbars where possible: week navigation, today, add lesson, sync status, maybe search later.
- Use detail/inspector structure for selected lesson context instead of making every panel equal.
- Let the root split/sidebar use native material and system backgrounds.

### 2. Stop Treating Every Region As A Card

The current `WorkbenchPanel` is useful as a first shared component, but it is overused. Product UI can be restrained without being flat. The next system needs at least four surface roles:

- `Canvas`: main schedule or primary work area.
- `Inspector`: selected lesson/student action area.
- `Memory panel`: compact read-only context.
- `Editor section`: lower-priority maintenance controls, often collapsed.

### 3. Make The Teaching Moment The Hero

This product is not a generic CRM. The core value is: before or during a lesson, the instructor quickly understands what to check next.

The visual hierarchy should always answer:

1. Who is the lesson/student?
2. What is the first thing to check?
3. What should be recorded during the lesson?
4. What needs to sync or be fixed?

Current screens answer these, but not in order.

### 4. Use Warmth Carefully

The app should not become a decorative music poster. It is a daily workbench used by one instructor.

Recommended scene sentence:

> A drum instructor opens the MacBook near the kit, often in a dim studio or between lessons, needing one clear next action in under 30 seconds.

Design consequence:

- System-adaptive dark/light support should stay.
- Use one warm accent for teaching urgency and rhythm, such as amber/rust, while leaving destructive/error/success states semantic.
- Keep typography native and legible. Do not introduce decorative display fonts into product UI.

### 5. Prefer Disclosure Over Form Walls

Maintenance editing is necessary, but it should not own the page. The current detail view shows every edit surface at once.

Better patterns:

- Primary lesson flow visible.
- Recent memory visible.
- Editing grouped into `DisclosureGroup`, segmented editor, inspector, or focused sheet depending on action frequency.
- Common actions remain one click; rare edits can be one level deeper.

## Design Direction Options

### Direction A: Native Calendar Workbench

Most conservative and most Mac-native.

- Native sidebar, toolbar-first actions.
- Calendar board as primary canvas.
- Selected lesson inspector on the right.
- Roster becomes a supporting list, likely beneath or inside the inspector.
- Minimal custom styling, stronger hierarchy through spacing and surface roles.

Best for:

- Low-risk Phase 8.
- Keeping implementation tight.
- Avoiding an overdesigned product.

Risk:

- If too restrained, it may still feel plain.

### Direction B: Studio Operating Desk

More distinctive and better aligned with the drum lesson domain.

- Warm studio accent.
- Student/lesson "brief" feels like a cue card.
- Calendar board looks less like a generic grid and more like a day/week operating board.
- Lesson flow uses a visible 3-step rhythm: Check -> Capture -> Close.

Best for:

- Making the product feel made for teaching, not just scheduling.
- A prettier first impression.

Risk:

- Needs careful restraint. Too much warmth or texture will fight native macOS and daily-use density.

### Direction C: Dense Command Center

Most operational and high-density.

- Current week remains visible.
- Selected event gets an inspector with sync, homework, first check, and start/edit/cancel.
- Student detail uses compact rows, sections, and inspector-like edit controls.
- Better for many students and packed teaching days.

Best for:

- Real daily use at scale.
- Instructors who want everything visible.

Risk:

- Can feel stressful if every detail is visible at once.

## Recommended Direction

Use a hybrid of Direction A and Direction B:

**Native Studio Workbench**

- Native macOS shell.
- Toolbar-first controls.
- One main canvas per screen.
- Right-side selected-context inspector where width allows.
- Warm accent only for the next teaching action and assignment attention.
- Maintenance editors reduced into clearer, lower-priority sections.

This gives the app enough character without fighting macOS conventions.

## UX Priorities For Phase 8

1. **Dashboard first impression**
   - Make the current or selected lesson the clear decision point.
   - Reduce empty calendar-grid weight.
   - Move view actions to toolbar.
   - Make sync status visible without letting it dominate.

2. **Student detail hierarchy**
   - Keep the student brief visible.
   - Make the first check visually primary.
   - Turn run notes and closeout into one guided flow instead of equal cards.
   - Move broad maintenance editing below or behind disclosure.

3. **Component vocabulary**
   - Define surface roles in `AppTheme`.
   - Replace one-size `WorkbenchPanel` usage with purposeful variants.
   - Standardize action rows, status pills, empty states, and section headers.

4. **Settings polish**
   - Make settings feel like configuration, not another workbench.
   - Clarify calendar permission, selected writable calendar, sync queue, and sign out.

## Feasibility

High.

Reasons:

- App already uses SwiftUI and a small design system.
- The core surfaces are centralized.
- Most changes are layout/component changes, not repository or data changes.
- Current tests can protect model behavior while Computer Use verifies visual/flow behavior.

Expected implementation risk:

- Medium for student detail because form state is currently local to `StudentDetailEditorPanel`.
- Low to medium for dashboard because selected event behavior is already explicit.
- Low for settings.

## Non-Goals

Phase 8 should not:

- Add student portal behavior.
- Change Supabase schema or RPC contracts.
- Change EventKit sync semantics.
- Add AI summaries.
- Add animation-heavy showpiece work.
- Replace native SwiftUI controls with bespoke controls unless a standard control clearly fails the workflow.
- Rebuild the app as a web-like custom shell.

## Open Questions Before Implementation

1. Should Phase 8 optimize for the real instructor's preferred language first: English UI, Korean demo content, or mostly Korean product UI?
2. Should the dashboard default to week board, today-focused list, or split "today plus week" layout?
3. Are there usually 2-4 lessons per day or many more? This determines whether the calendar should be sparse and calm or denser.
4. Should maintenance editing be inline, inspector-based, or sheet-based for profile/traits/progress/assignment/note/plan?
5. Should Settings become a dedicated macOS `Settings` scene later, or remain a route inside the main app for MVP simplicity?

## Research Verdict

The design is very fixable. The app does not need a new architecture. It needs a stronger native product UI system:

- Clearer surface roles.
- Toolbar-first global actions.
- Selected-context inspector.
- A teaching-first student detail hierarchy.
- Less always-visible form density.
- Purposeful warm accent and semantic state colors.

This is appropriate as a dedicated Phase 8 because it affects multiple visible surfaces and the shared design system.
