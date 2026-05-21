# Research Summary: Drum Lesson OS

## Key Findings

Music lesson management products consistently expose student profiles, progress, lesson notes, assignments, schedules, billing, reminders, and portals. For Drum Lesson OS, the clearest MVP is a narrower instructor working-memory tool: student roster, current progress, traits/weaknesses, recent notes, assignments, and next lesson preparation.

## Stack

Recommended MVP stack:

- Next.js App Router + TypeScript
- Tailwind CSS v4
- shadcn/ui
- Prisma ORM
- SQLite for local MVP, with a later Postgres/Supabase path if hosted sync or accounts become necessary

## Table Stakes To Include

- Student roster
- Student profile/detail
- Current progress by flexible lesson categories
- Student traits, strengths, weak points, learning style, and musical preferences
- Lesson notes/history
- Assignment/practice task status
- Next lesson plan or next action

## Defer

- Scheduling automation
- Billing and invoices
- Student/parent portal
- Messaging/reminders
- Practice streak gamification
- AI import or audio/video analysis
- Multi-instructor studio management

## Roadmap Implication

The roadmap should be vertical MVP style:

1. Set up the app/data foundation.
2. Make the roster and student detail readable with realistic seed data.
3. Add editing flows for progress, traits, notes, assignments, and next plans.
4. Polish the instructor dashboard so it works as a pre-lesson briefing screen.
