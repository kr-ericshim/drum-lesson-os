# Drum Lesson OS

Drum Lesson OS is a local macOS SwiftUI workbench for drum instructors. It keeps the instructor-side lesson memory loop in one native app: calendar-first schedule, student roster, student detail, lesson notes, progress, traits, assignments, next lesson planning, in-lesson run notes, closeout, and Apple Calendar write-through.

SQLite is the canonical data store. The app runs without login, stores lesson data on this Mac, and uses EventKit for Apple Calendar instead of storing Apple credentials. SQLite updates are transactional, recurring lesson templates are persisted, and pending EventKit work is kept in an atomic local outbox so retries survive app restarts.

The legacy Next.js web app was removed after Phase 7 implementation approval so this repo now presents as a macOS native project.

## Project Layout

```text
DrumLessonOS.xcodeproj      Generated Xcode project
project.yml                 XcodeGen source of truth
DrumLessonOS/               SwiftUI app source
DrumLessonOSTests/          Swift test suite
.planning/                  Roadmap, requirements, and phase evidence
```

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
