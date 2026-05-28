# Phase 7 Native-Primary Reorganization

**Status:** Completed and verified.
**Date:** 2026-05-28.
**Decision:** Phase 7 was approved as the implementation candidate. The repo should now look like a macOS native app first.

## Goal

Remove the legacy web runtime from the active project and move the SwiftUI app to the repo root so future agents start from the real product surface.

## Assumptions

- `DrumLessonOS/`, `DrumLessonOSTests/`, `project.yml`, and `DrumLessonOS.xcodeproj` are the active app surfaces.
- `supabase/` remains because Supabase is still canonical for data, RLS, RPCs, migrations, and seed content.
- `tests/native-rpc-security.test.mts` remains as the lightweight SQL security guard.
- Historical web notes can remain in planning docs as migration evidence, but `src/`, Next.js config, and web dependencies should not remain in the working project.

## Applied Structure

```text
DrumLessonOS.xcodeproj
project.yml
DrumLessonOS/
DrumLessonOSTests/
supabase/
tests/native-rpc-security.test.mts
```

Removed active web surfaces:

- `src/`
- `next.config.ts`
- `next-env.d.ts`
- `eslint.config.mjs`
- `postcss.config.mjs`
- `components.json`
- `tsconfig.json`
- `package-lock.json`
- generated `.next/` and `node_modules/`

Native config was also tightened to remove old web environment aliases. The native app now accepts `DRUM_LESSON_OS_SUPABASE_*` or plain `SUPABASE_*` publishable-key configuration.

## Verification Target

```bash
npm test
xcodegen generate
xcodebuild -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test
supabase db push --dry-run
```

## Verification Result

Passed on 2026-05-28 17:17 KST:

- `npm test` passed 6 SQL guard tests.
- `xcodegen generate` recreated `DrumLessonOS.xcodeproj` at repo root.
- `xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test` exited 0 after the native config cleanup.
- `supabase db push --dry-run` completed and would push only `0018_native_write_rpcs.sql` and `0019_native_eventkit_sync.sql`.
- `git diff --check` passed.

## Remaining Live Gates

- Live Supabase sign-in with the instructor account.
- Real EventKit permission, create/edit/cancel proof, and failure recovery.
- iPhone iCloud propagation proof.
- Daily-use confidence on the native app.
