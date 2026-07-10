# Phase 9 Native UI/UX Audit

**Date:** 2026-07-10
**Platform:** macOS SwiftUI
**Baseline:** app build passed, 69/69 tests passed, `git diff --check` clean before Phase 9 edits

## Platform Verdict

The app has a credible native foundation: SwiftUI navigation, system controls, SF Symbols, semantic typography, and adaptive color are already in place. It still falls short of a trustworthy daily Mac workbench because task context, modal form density, navigation state, calendar selection feedback, keyboard flow, and VoiceOver meaning are inconsistent.

## Audit Health Score

| Dimension | Score | Key finding |
|---|---:|---|
| Accessibility | 2/4 | Custom labels omit first-check and attention context; dynamic status feedback is not announced |
| Performance | 2/4 | Initial dashboard loading is duplicated; long-term storage and lists remain eager |
| Appearance and theming | 3/4 | System colors and type are sound, but surface roles and small semantic text need stronger contrast |
| Platform conformance | 2/4 | Native controls are present, but sheets, navigation state, settings, and commands do not yet behave like a finished Mac app |
| Adaptivity | 3/4 | Responsive foundations exist; fixed minimums and compact information order still work against smaller windows |
| **Total** | **12/20** | **Acceptable — significant work remains** |

## Highest-Priority Findings

### P1 — Lesson recording is available without a lesson context

- **Location:** `StudentDetailView.swift`, `LessonFlowWorkspace.swift`, `StudentDetailViewModel.swift`
- **Impact:** Opening a student from the roster exposes capture and closeout controls. Saving without a scheduled occurrence creates a record dated today, which can attach teaching data to the wrong context.
- **Recommendation:** Keep the brief visible for preparation, but require a selected occurrence before exposing capture/closeout. Add a write-path guard as a second safety boundary.

### P1 — Scheduling sheets are oversized and visually ambiguous

- **Location:** `ScheduleLessonSheet.swift`, `AddStudentSheet.swift`, `DashboardView.swift`
- **Impact:** A width-unbounded grouped `Form`, outer `Spacer`, and minimum-only frames expand a small task into a large sparse sheet. Values resemble read-only text, the date control mixes English formatting into Korean UI, duration controls separate the value from its steppers, and raw time-zone identifiers expose implementation detail.
- **Recommendation:** Use compact labeled sections, persistent labels, Korean locale, a human-readable time-zone summary, adjacent actions, and content-driven sizing. Add Return/Escape behavior and initial focus.

### P1 — Detail navigation loses top-level context

- **Location:** `RootView.swift`, `StudentRosterView.swift`, `SelectedLessonPanel.swift`
- **Impact:** The sidebar only tags dashboard and settings. Student and lesson routes leave no selected sidebar row and provide no clear standard return path.
- **Recommendation:** Separate top-level sidebar selection from detail routes, keep the originating section selected, and provide a visible return action.

### P1 — Calendar selection is neither observable nor recoverable

- **Location:** `SettingsView.swift`
- **Impact:** The selected writable calendar has no checkmark or VoiceOver state, and selection errors are discarded with `try?`.
- **Recommendation:** Load and display the current selection, expose loading/empty/error/success states, mark the selected row, and disable irrelevant actions by permission state.

### P1 — Compact dashboard demotes today’s work

- **Location:** `DashboardView.swift`
- **Impact:** Narrow windows start with a whole-week agenda and omit the today counters/list, weakening the 30-second pre-lesson scan on the layout where prioritization matters most.
- **Recommendation:** Put today’s lessons and the selected lesson first, with the rest of the week as supporting context.

### P1 — Student header and lesson brief disagree about the first check

- **Location:** `StudentHeaderView.swift`, `ReadModelMappers.swift`
- **Impact:** “오늘 볼 것” shows the primary weak point while the lesson brief resolves next plan, current focus, then weakness. One screen can issue two different teaching cues.
- **Recommendation:** Use the mapped lesson brief as the shared source of truth.

## Repeated P2 Patterns

- Error, success, and saving states lack a consistent accessible announcement pattern.
- `SectionHeader` does not expose heading semantics on long screens.
- Explicit accessibility labels remove first-check, warning, sync, and last-lesson context that is visible on screen.
- Several date fields use raw `YYYY-MM-DD` strings instead of native date controls.
- Student memory tabs use a fixed minimum height and eager stacks, causing either blank space or poor long-list behavior.
- Similar bordered surfaces wrap nearly every region, so primary, supporting, and editing areas remain too close in visual weight.
- The dashboard loads from both `RootView` and `DashboardView`.
- Calendar commands and keyboard shortcuts are distributed across the App scene and screen toolbar.
- Empty states often describe where to scroll instead of offering a nearby action.

## Positive Findings To Preserve

- Semantic SwiftUI font styles and system-adaptive colors are used consistently.
- SF Symbols and standard controls provide a strong native base.
- `GeometryReader` and `ViewThatFits` already support structural adaptation.
- Lesson selection exposes the selected trait to accessibility.
- Scheduling prevents duplicate submission and distinguishes local-save success from calendar-sync failure.
- The visible-week selection regression now has a passing test and no longer retains an event outside the displayed week.
- Custom decorative motion is absent, so Reduce Motion is not currently a risk.

## Phase 9 Fix Order

1. Protect lesson context and unify the first-check source.
2. Rebuild schedule/edit/student sheets around compact native form rows and keyboard flow.
3. Preserve navigation context and restore today-first compact layout.
4. Make calendar permission and calendar selection state explicit.
5. Improve VoiceOver meaning, headings, messages, dates, and long-list behavior.
6. Re-run the audit after build, tests, light/dark checks, and compact/wide checks.

## Post-Implementation Re-Audit

Phase 9 raised the implementation score from **12/20** to **17/20**. Lesson closeout now requires an occurrence, sheets use compact labeled controls, sidebar context and return navigation remain visible, compact layouts put today's work first, Calendar settings expose recoverable state, and status meaning is available without relying on color alone.

The remaining three points are release-confidence work rather than a newly discovered P1 defect: large real-world datasets still need performance observation, direct automated light/compact/sheet capture was unavailable in this environment, and EventKit/iCloud behavior still needs live permission and propagation UAT. Full evidence and the dimension-by-dimension score are in `09-CHECKPOINT.md`.
