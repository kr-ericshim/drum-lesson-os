# Phase 12 Checkpoint: Prepaid Tuition Management

## Outcome

Phase 12 is implemented and verified. Drum Lesson OS now has a dedicated `수강비` sidebar workspace for four-lesson prepaid cycles, manual payment confirmation, and closeout-linked session progress.

## Implemented Behavior

- Active students appear in one wide table or compact card list with current `X/4`, next lesson number, current prepaid status, and the oldest unconfirmed cycle.
- Existing students remain `설정 필요` until the instructor sets their real current position once; unlinked lesson notes are never guessed as completed lessons.
- Newly created students receive a `0/4` unconfirmed first cycle automatically.
- A successful occurrence-backed closeout advances a configured cycle in the same SQLite snapshot transaction.
- Duplicate or failed closeout cannot advance tuition progress.
- A completed `4/4` cycle remains visible until `다음 4회 시작` is chosen.
- If another lesson is completed first, the app preserves the completed cycle and creates the next cycle at `1/4` with payment unconfirmed.
- Every saved cycle remains selectable for payment confirmation, date correction, or confirmation removal, including earlier unpaid cycles.
- Tuition state reloads whenever the workspace is entered, so closeout changes are visible without manual refresh.

## Persistence And Compatibility

- Tuition cycles are stored in the canonical `LocalAppSnapshot` and included in portable backups.
- New backups use format version 2.
- Version-1 backups and snapshots without tuition collections still restore with empty tuition tracking.
- Backup validation rejects duplicate cycle identities/sequences, invalid student links, non-four-session targets, invalid progress ranges, and malformed payment dates.
- A version-2 backup is rejected by older version-1 code instead of silently discarding tuition history.

## Verification

- `npm run verify` passed.
- Native Swift Testing: 113 passed, 0 failed, 0 skipped.
- `xcodebuild ... analyze` passed.
- `CONFIGURATION=Release ./script/build_and_run.sh --verify` passed and launched the app.
- Wide and compact running-app checks showed the tuition destination, setup states, adaptive summary, table/card layouts, and no clipping or text overlap.
- Two independent read-only audits found stale reload and payment-history action gaps; both were fixed before the final verification run.
- `git diff --check` passed.

## Remaining Release UAT

Direct backup file-panel proof, broader compact/light/keyboard/VoiceOver checks, and real EventKit/iCloud propagation checks remain release-confidence work outside Phase 12.
