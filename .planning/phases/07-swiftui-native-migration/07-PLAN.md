# Phase 7 SwiftUI Native Migration Current Plan

**Status:** Implementation approved and reorganized as native-primary.
**Date:** 2026-05-28.

## Current Goal

Keep Drum Lesson OS centered on the root macOS SwiftUI app.

Active surfaces:

- `project.yml`
- `DrumLessonOS.xcodeproj`
- `DrumLessonOS/`
- `DrumLessonOSTests/`
- `supabase/`
- `tests/native-rpc-security.test.mts`

## What Happened

Phase 7 ported the instructor-side MVP to SwiftUI and passed independent implementation review. After approval, the SwiftUI app was moved from the temporary migration folder to the repo root, and the legacy Next.js runtime was removed from active development.

Historical migration details are preserved in:

- `07-IMPLEMENTATION-PLAN-HISTORICAL.md`
- `07-LEGACY-WEB-REFERENCE.md`
- `07-CHECKPOINT.md`
- `07-PARITY-CHECKLIST.md`
- `07-UAT.md`
- `07-RELEASE-GATE.md`
- `07-NATIVE-PRIMARY-REORG.md`

## Current Verification

```bash
npm test
xcodegen generate
xcodebuild -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
supabase db push --dry-run
```

`npm run verify` runs the same native-first gate.

## Remaining Gates

- Live Supabase sign-in with the instructor account.
- Real EventKit permission, calendar selection, create/edit/cancel proof, and failure recovery.
- iPhone iCloud propagation proof.
- Daily-use confidence on the native app.
