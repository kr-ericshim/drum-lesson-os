# Phase 4C Brief And Closeout Tightening Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:test-driven-development` for behavior changes and `superpowers:verification-before-completion` before closeout.

**Goal:** Make Lesson Brief action-first and make Closeout faster to complete without adding new product surfaces.

**Architecture:** Keep the existing Supabase tables and read-model layer. Tighten read-model derivation, closeout validation/action behavior, and the existing student detail UI only.

**Tech Stack:** Next.js App Router, TypeScript, Supabase/Postgres, Tailwind CSS, Node test runner.

---

## Scope

- [x] Reorder Lesson Brief around `Start here` and `Remember`.
- [x] Prefer latest lesson-note `nextStepHint` for `firstCheck`.
- [x] Include assignment detail in `needs_review` cues.
- [x] Allow closeout current-focus updates without requiring a status change.
- [x] Make closeout `nextPlanDetail` optional at the form/schema layer while preserving the database non-empty constraint.
- [x] Choose the current next plan by latest `updated_at`/`created_at`, not by priority.

## Out Of Scope

- [x] No auth/RLS hardening.
- [x] No closeout transaction RPC.
- [x] No student portal, payment, attendance, calendar, AI, audio/video, or curriculum features.

## Verification Targets

- [x] Unit coverage for brief priority, assignment cue detail, closeout progress combinations, blank next detail, and latest next-plan selection.
- [x] Browser smoke for desktop and 320px student detail readability.
- [x] Browser smoke that focus-only closeout keeps dashboard, header, Lesson Brief, Summary, and Progress tab aligned.
