# Active Product And Engineering Risks

## Losing The Fast-Scan Workflow

Dense maintenance controls can bury the next teaching action.

**Guardrail:** Keep current focus, first check, caution, assignment cue, and next action visually dominant. Move configuration and history behind secondary surfaces.

## Over-Structuring Music Progress

Students move between songs, rudiments, technique, grooves, and genres in nonlinear ways.

**Guardrail:** Preserve flexible progress categories, notes, and traits. Add structure only when repeated real use supports it.

## Splitting Canonical State

Treating Apple Calendar as a second source of truth can create conflicts and duplicate events.

**Guardrail:** Keep local SQLite canonical, restrict EventKit to app-owned writes, and persist stable sync identity plus retry state.

## Replaying Unsafe Calendar Work

Restoring a data backup together with an old execution queue could recreate or delete the wrong Apple events.

**Guardrail:** Exclude the EventKit queue from portable backups and require explicit retry for restored pending states.

## Double-Applying Lesson Completion

Repeated closeout can duplicate notes or incorrectly advance prepaid tuition progress.

**Guardrail:** Keep closeout atomic, occurrence-backed, and covered by duplicate-save regression tests.

## Mistaking Test Completion For Release Confidence

Unit and integration tests cannot prove native file panels, TCC permissions, VoiceOver behavior, or iCloud propagation.

**Guardrail:** Keep direct UAT visible in `STATE.md` and do not mark release confidence complete until those checks are recorded.

## Expanding Into Generic Studio Management

Billing, portals, messaging, attendance, and automation can obscure the instructor memory loop.

**Guardrail:** Require an explicit product-scope decision before adding hosted accounts, payment processing, or broader studio operations.
