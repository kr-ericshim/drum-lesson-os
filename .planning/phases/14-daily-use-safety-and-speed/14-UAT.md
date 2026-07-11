# Phase 14 UAT Record

## Automated Native Evidence

Verified on 2026-07-11 with a disposable SQLite path and Preview Calendar adapter:

- Debug app built with XcodeGen and launched as a signed `.app` process.
- The running app created `Backups/Automatic/Automatic-*.drumlessonbackup` on first launch.
- The generated backup parsed as format version 3 and contained the seeded teaching snapshot.
- Relaunching with the same database on the same day kept exactly one automatic backup.
- The built bundle used an Apple Development identity with TeamIdentifier `95P2P242SQ`.

## Direct UI Automation Status

Computer Use failed before app interaction with `Sky Computer Use native pipe startup failed`. The Drum Lesson OS process remained running, and the failure occurred in the separate Sky helper startup path. No app crash was observed.

On 2026-07-11, the operator explicitly deferred direct validation until Computer Use is working again. These checks are excluded from the current Phase 14 completion decision.

## Deferred Device Checks

- Export and restore a disposable backup through the native save/open panels.
- Traverse dashboard, calendar, lesson flow, roster, tuition, and settings with keyboard focus and VoiceOver in light mode.
- With a disposable calendar, verify real EventKit permission, create, edit, cancel/delete, failure visibility, and retry.
- Confirm the disposable EventKit change reaches an iPhone on the same iCloud account.

Resume these checks when a compatible Computer Use helper is available. Until then, do not claim direct file-panel, VoiceOver, live EventKit, or iPhone propagation evidence.
