# Drum Lesson OS

Drum Lesson OS is a local macOS SwiftUI workbench for drum instructors. It keeps the instructor-side lesson memory loop in one native app: calendar-first schedule, student roster, student detail, lesson notes, progress history, traits, assignments, next lesson planning, in-lesson run notes, closeout, four-lesson prepaid tuition tracking, local backup/restore, and Apple Calendar write-through.

SQLite is the canonical data store. The app runs without login, stores lesson data on this Mac, and uses EventKit for Apple Calendar instead of storing Apple credentials. SQLite updates are transactional, recurring lesson templates are persisted, and pending EventKit work is kept in an atomic local outbox so retries survive app restarts.

The legacy Next.js web app was removed after Phase 7 implementation approval so this repo now presents as a macOS native project.

## Project Layout

```text
DrumLessonOS.xcodeproj      Generated, tracked Xcode entry point
project.yml                 XcodeGen source of truth
DrumLessonOS/
├── App/                    App entry, environment, routing, root scene
├── Data/                   Calendar, SQLite, persistence, preview, and sync adapters
├── Domain/                 Models, read models, repository contracts, validation
├── Features/               Dashboard, lesson flow, scheduling, settings, students, tuition
├── DesignSystem/           Shared components, formatters, and tokens
└── Resources/              Asset catalogs and non-code bundle resources
DrumLessonOSTests/          Tests mirroring the app's top-level layers
script/                     Build, run, logging, and verification entry point
.planning/                  Product state, roadmap, research, and phase evidence
```

Swift files should stay out of `Resources/`. Tests belong under the layer or feature they verify. XcodeGen discovers both trees recursively, and `./script/build_and_run.sh` regenerates the project before building so file moves cannot leave the Xcode project stale.

## Documentation

- [Current state](.planning/STATE.md)
- [Product definition](.planning/PROJECT.md)
- [Requirements and traceability](.planning/REQUIREMENTS.md)
- [Roadmap and architecture transitions](.planning/ROADMAP.md)
- [Planning documentation map](.planning/README.md)

Completed phase records preserve implementation history. Older Next.js, Supabase, and hosted-auth references inside those records describe superseded stages; the active app is the native, local-first implementation documented above.

## Requirements

- Xcode 26.2 with Swift 6.2 support
- XcodeGen
- Node.js 22+ only if you want to use the npm script wrappers

## Native Development

Generate the project and run the native tests:

```bash
npm run generate
npm test
```

Open the app in Xcode:

```bash
open DrumLessonOS.xcodeproj
```

Run the local app from the command line:

```bash
./script/build_and_run.sh
```

The default SQLite file and EventKit retry outbox are created under the user's Application Support directory at launch. EventKit permissions and the selected Apple Calendar stay in the native macOS system flow.

Settings can export a versioned `.drumlessonbackup` file and restore it after validation. Restore creates an automatic pre-restore safety backup. Portable backups contain the canonical teaching snapshot and exclude the EventKit execution queue; pending restored calendar work requires explicit manual retry.

The active lesson workspace can append dated BPM and observation checkpoints to the current progress item. Checkpoints remain separate from the editable progress summary so earlier observations are not overwritten.

The `수강비` workspace tracks each active student's four-lesson cycle. Scheduled-lesson closeout advances the configured cycle, while payment confirmation and the confirmation date remain manual. Existing students require one initial current-cycle setup; newly added students start at `0/4` with payment unconfirmed. Tuition history is included in version-2 backups, and version-1 backups remain restorable.

Snapshots created by experimental local builds before recurring templates were persisted still open, but their lost repeat rule and end date cannot be reconstructed safely. If such a snapshot contains an old eight-week recurring series, recreate that recurring schedule once in the current build; current schedules persist the template and continue expanding on demand.

## Verification

Use the native-first gate:

```bash
npm run verify
```

That runs:

- `xcodegen generate`
- `xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' test`

Before relying on it for live teaching, verify real EventKit create/edit/cancel and iPhone iCloud propagation with your Apple Calendar account.
