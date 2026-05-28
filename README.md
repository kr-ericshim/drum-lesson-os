# Drum Lesson OS

Drum Lesson OS is a macOS SwiftUI workbench for drum instructors. It keeps the instructor-side lesson memory loop in one native app: calendar-first schedule, student roster, student detail, lesson notes, progress, traits, assignments, next lesson planning, in-lesson run notes, closeout, and Apple Calendar write-through.

Supabase remains the canonical data store. The native app reads instructor-owned data through authenticated Supabase access, writes through authenticated RPCs, and uses EventKit for Apple Calendar instead of storing Apple credentials.

The legacy Next.js web app was removed after Phase 7 implementation approval so this repo now presents as a macOS native project.

## Project Layout

```text
DrumLessonOS.xcodeproj      Generated Xcode project
project.yml                 XcodeGen source of truth
DrumLessonOS/               SwiftUI app source
DrumLessonOSTests/          Swift test suite
supabase/                   Schema, RLS, RPC migrations, seed data
tests/                      Node-based SQL/security guard tests
.planning/                  Roadmap, requirements, and phase evidence
```

## Requirements

- Xcode 26.2 with Swift 6.2 support
- XcodeGen
- Supabase CLI for migration dry-runs and database setup
- Node.js 22+ for the SQL guard test in `tests/`

## Native Development

Generate the project and run the native tests:

```bash
npm run generate
npm run test:native
```

Open the app in Xcode:

```bash
open DrumLessonOS.xcodeproj
```

For live Supabase data, provide these values through the app environment or bundle Info keys:

```text
DRUM_LESSON_OS_SUPABASE_URL=
DRUM_LESSON_OS_SUPABASE_PUBLISHABLE_KEY=
```

The app rejects service-role-like keys. Without live Supabase config, it opens with preview data for local UI smoke checks.

## Supabase Setup

Create `.env.local` from `.env.example` for CLI/database work:

```text
DRUM_LESSON_OS_SUPABASE_URL=
DRUM_LESSON_OS_SUPABASE_PUBLISHABLE_KEY=
SUPABASE_DB_URL=
```

Apply migrations and seed data with the Supabase CLI:

```bash
supabase db push
supabase db execute --file supabase/seed.sql
```

For a local Supabase stack:

```bash
supabase db reset
```

The seed data uses instructor id `11111111-1111-4111-8111-111111111111`. After creating the Supabase Auth user, bind it to the instructor row:

```sql
update public.instructors
set auth_user_id = '<your-supabase-auth-user-id>'
where id = '11111111-1111-4111-8111-111111111111';
```

Disable public signup in Supabase Auth settings before using real student data.

## Verification

Use the native-first gate:

```bash
npm run verify
```

That runs:

- `npm test` for native RPC security checks against SQL migrations
- `xcodegen generate`
- `xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test`
- `supabase db push --dry-run`

Live release cutover still needs real Supabase sign-in, real EventKit create/edit/cancel, iPhone iCloud propagation, and daily-use confidence recorded in `.planning/phases/07-swiftui-native-migration/07-UAT.md`.
