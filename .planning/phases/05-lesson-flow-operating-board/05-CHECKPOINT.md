# 05 Checkpoint: Lesson Flow Operating Board

**Date:** 2026-05-28
**Status:** Complete

## Implemented

- Dashboard queue is now a lesson operating board grouped by overdue, today, and upcoming work.
- Queue items now expose `firstCheck` and `attentionFlags` for assignment review, missing current focus, missing recent note, overdue plan, and stale current focus.
- Student detail now uses one `LessonFlowWorkspace` for Lesson Brief, in-lesson run panel, and Closeout.
- `LessonRunPanel` keeps working notes session-local and does not write partial lesson data.
- Run-panel working notes can prefill Closeout as a draft.
- Closeout draft handoff initializes note hint and next action from the same next-hint value unless the instructor edits them before saving.
- Existing closeout RPC/server action remains the only durable post-lesson save path.
- Client option constants were split into `status-options.ts` so the client Closeout form does not import the Zod schema module.

## Verification

- `npm test` -> 79 passing, 0 failing.
- `npm run build` -> passed.
- `npm run lint` -> passed.
- `git diff --check` -> passed.
- `git diff -U0 -- src README.md | rg "^\+.*(portal|payment|invoice|attendance|calendar sync|AI summary|audio|video)"` -> no matches.
- `git diff --name-only -- supabase/migrations` -> no output.
- Chrome extension verification:
  - Dashboard desktop viewport 1512x680 rendered `LESSON OPERATING BOARD`, overdue/today/upcoming groups, first checks, attention flags, and `Start lesson` links.
  - Student detail desktop rendered Lesson Brief, `Run the lesson`, and Closeout.
  - Run-panel draft filled closeout `coveredMaterial`, `observations`, `practiceAssigned`, `nextStepHint`, and `nextAction`.
  - The same draft next hint filled both `nextStepHint` and `nextAction`.
  - Saving closeout persisted the Chrome smoke note; after refresh, detail header, Lesson Brief, run-panel first check, and next lesson showed `Chrome smoke next hint: start with two bars at 92bpm`.
  - Dashboard after save showed the same first check for the today queue item.
  - Progress tab showed the current focus `펑크 고스트노트 컴핑` and the saved next hint.
  - Notes tab showed the newest Chrome smoke note with covered material, observation, practice, and next hint.
  - Chrome desktop viewport 1512x680 had no horizontal overflow on dashboard or student detail.
  - Chrome verification window with `innerWidth === 320` had no horizontal overflow on dashboard or student detail (`scrollWidth === clientWidth`).
  - Screenshot evidence:
    - `/tmp/phase5-dashboard-desktop.png`
    - `/tmp/phase5-student-detail-desktop.png`
    - `/tmp/phase5-dashboard-mobile-chrome.png`
    - `/tmp/phase5-student-detail-mobile-chrome.png`
    - `/tmp/phase5-dashboard-320-chrome.png`
    - `/tmp/phase5-student-detail-320-chrome.png`
- Agent review:
  - Aquinas: APPROVED.
  - Faraday: APPROVED.
  - Popper: APPROVED after the README migration note, 320px Chrome evidence, Notes/Progress persistence evidence, and final state/checkpoint consistency fixes.

## Remaining Follow-Up

None.
