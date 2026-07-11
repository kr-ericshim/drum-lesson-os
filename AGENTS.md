# Drum Lesson OS Agent Guide

Drum Lesson OS is a local-first macOS SwiftUI CRM for one drum instructor. SQLite is canonical, EventKit is the Apple Calendar boundary, and the app runs without hosted authentication.

## Sources Of Truth

- Active implementation: `project.yml`, `DrumLessonOS/`, and `DrumLessonOSTests/`
- Setup and operator behavior: [README.md](README.md)
- Current project status: [.planning/STATE.md](.planning/STATE.md)
- Product requirements: [.planning/REQUIREMENTS.md](.planning/REQUIREMENTS.md)
- Architecture and stack: [.planning/research/ARCHITECTURE.md](.planning/research/ARCHITECTURE.md) and [.planning/research/STACK.md](.planning/research/STACK.md)
- Documentation map and history rules: [.planning/README.md](.planning/README.md)

Completed phase documents preserve decision history. Older Next.js, Supabase, hosted-auth, and Keychain references are not active architecture.

## Product Boundaries

- Keep work centered on instructor-side student memory, lesson flow, scheduling, progress, local backup, and manual four-lesson tuition cycles.
- Preserve flexible lesson notes and traits.
- Do not add student accounts, hosted services, payment processing, non-Apple calendars, or audio/video analysis without an explicit scope change.

## Working Rules

- Before editing, state the goal, files in scope, and verification command.
- For bug fixes, record the symptom, root cause, fix, and regression verification.
- Match existing code patterns and keep changes surgical.
- Treat generated `DrumLessonOS.xcodeproj` output as derived from `project.yml`.
- For planned phase work, read `STATE.md`, `ROADMAP.md`, and the target phase folder first.

## Verification

- Main gate: `npm run verify`
- Static analysis when logic or architecture changes: `xcodebuild -quiet -project DrumLessonOS.xcodeproj -scheme DrumLessonOS -destination 'platform=macOS' analyze`
- Final hygiene: `git diff --check`
- EventKit, file-panel, accessibility, and iCloud behavior still require direct macOS UAT where noted in `STATE.md`.
