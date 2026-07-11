# GPT Pro Document Review Materials

> **Historical material:** This folder supported an external review of the initial planning set. Its prompt predates the native local-first cutover and must not be used as a current architecture brief. Start with [../README.md](../README.md) for active documentation.

## Purpose

This folder prepares Drum Lesson OS planning documents for an external GPT Pro review after project initialization.

## Review Target

Review the planning documentation, not implementation code:

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/config.json`
- `.planning/research/*.md`
- `AGENTS.md`

## Prompt

Use:

- `.planning/reviews/GPT_PRO_DOC_REVIEW_PROMPT.md`

## Bundle Scope

The external review bundle should include only planning and guidance files. It should exclude:

- `.git/`
- `.idea/`
- `node_modules/`
- build artifacts
- secrets and environment files

## Expected Review

Ask GPT Pro to focus on:

- MVP scope fit
- requirement clarity
- roadmap ordering
- traceability coverage
- document consistency
- missing domain risks
- implementation-before-planning decisions that remain unclear
