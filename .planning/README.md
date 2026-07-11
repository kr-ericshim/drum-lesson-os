# Planning Documentation

This directory contains the current product definition, implementation status, and completed phase history for Drum Lesson OS.

## Read In This Order

1. [STATE.md](STATE.md) — what is complete and what still needs direct UAT
2. [PROJECT.md](PROJECT.md) — current product boundary and decisions
3. [REQUIREMENTS.md](REQUIREMENTS.md) — requirement status and traceability
4. [ROADMAP.md](ROADMAP.md) — phase outcomes and architecture transitions
5. [research/STACK.md](research/STACK.md) and [research/ARCHITECTURE.md](research/ARCHITECTURE.md) — active technical model
6. [phases/README.md](phases/README.md) — completed implementation records

For setup and daily operation, use the root [README.md](../README.md). For agent workflow rules, use [AGENTS.md](../AGENTS.md).

## Current Versus Historical Content

The active implementation surfaces are:

- `project.yml`
- `DrumLessonOS/`
- `DrumLessonOSTests/`

SQLite is canonical and EventKit is the calendar boundary. Phase documents from earlier stages may mention Next.js, Supabase, RLS, hosted authentication, Keychain sessions, browser routes, or mobile layouts. Those references describe completed historical implementations and must not be used as current technical guidance.

## Document Responsibilities

| Document | Responsibility | Update When |
|----------|----------------|-------------|
| `STATE.md` | Current completion and release-confidence status | A phase or UAT result changes |
| `PROJECT.md` | Product boundary and durable decisions | Scope or product direction changes |
| `REQUIREMENTS.md` | Verifiable behavior and traceability | Behavior is added, removed, or deferred |
| `ROADMAP.md` | Phase outcomes and architecture transitions | A phase is planned or completed |
| `research/STACK.md` | Active technology choices | A runtime, persistence, or integration choice changes |
| `research/ARCHITECTURE.md` | Active component and data-flow model | Ownership or dependency flow changes |
| `phases/<phase>/` | Plan and completion evidence | Work is planned or verified |

## Maintenance Rules

- Code and tests win when an old phase document disagrees with the active documentation.
- Preserve completed phase records as history; correct their meaning through the indexes instead of rewriting old evidence.
- Keep new plans short and pair them with a checkpoint that records outcome and verification.
- Do not copy the same status narrative into several files. Link to the responsible document.
- Run the local-link check and `git diff --check` after documentation edits.
