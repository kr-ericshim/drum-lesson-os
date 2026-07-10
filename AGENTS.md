<!-- GSD:project-start source:PROJECT.md -->
## Project

**Drum Lesson OS**

Drum Lesson OS is a mini CRM for drum instructors who teach multiple students and need one place to remember each student's progress, habits, and lesson context. It helps an instructor see where every student is, what each person struggles with, and what should happen next in the lesson.

The MVP focuses on instructor-side student management: a clear student list, per-student progress tracking, lesson notes, student traits, weaknesses, practice patterns, and next-lesson preparation.

**Core Value:** An instructor can quickly understand a student's current progress and personal characteristics before or during a lesson.

### Constraints

- **Scope**: Keep MVP focused on instructor-side student CRM - this validates the core workflow before expanding to student accounts or payments.
- **UX**: Optimize for fast scanning before a lesson - instructors should not need to dig through many screens to remember what matters.
- **Data model**: Preserve flexible lesson notes and trait fields - early usage may reveal which categories deserve structured fields later.
- **Safety**: Avoid overbuilding music-analysis features before the basic management loop works.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommendation
- **App framework**: macOS SwiftUI with Swift 6.2
- **Project generation**: XcodeGen (`project.yml`)
- **Native integrations**: EventKit for Apple Calendar writes and local Application Support storage
- **Data access**: Repository protocols backed by `LocalSQLiteRepository` and `CalendarBackedScheduleRepository`
- **Database**: Local SQLite with transactional snapshot updates and persisted recurring templates
- **Sync durability**: Atomic local JSON outbox for EventKit create, update, delete, and metadata completion
- **Verification**: Swift Testing under `DrumLessonOSTests/`
## Rationale
The active product is a single-instructor, login-free macOS app. SQLite is canonical, EventKit is the connected calendar target, and the durable local outbox preserves retryable calendar work across launches. Older Supabase and Keychain references under `.planning/` are historical unless a later current-state note explicitly reactivates them.
## What Not To Use Yet
- **Student portal stack**: Defer until student-facing accounts are in scope.
- **Realtime sync**: Defer until there is a real multi-device or collaborative need.
- **Audio/video analysis**: Defer; it distracts from the CRM memory/progress workflow.
- **Hosted auth/API service**: Defer until local single-instructor use proves a multi-device or account requirement.
## Sources
- SwiftUI docs: https://developer.apple.com/documentation/swiftui
- EventKit docs: https://developer.apple.com/documentation/eventkit
- XcodeGen docs: https://github.com/yonaskolb/XcodeGen
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## Standalone Workflow Enforcement

GSD has been removed from this project. Keep planning artifacts and execution context in sync manually before file-changing work.

Use these standalone entry points:
- For small fixes, state the goal, touched files, and verification command.
- For investigation and bug fixing, write down the observed symptom, root cause, fix, and verification.
- For planned phase work, read `.planning/ROADMAP.md`, `.planning/STATE.md`, and the target phase folder before editing.
- For native app work, treat `project.yml`, `DrumLessonOS/`, and `DrumLessonOSTests/` as the active surfaces.

Do not make broad direct repo edits without a concrete phase/task goal and verification loop.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
