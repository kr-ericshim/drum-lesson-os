import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const migration = readFileSync("supabase/migrations/0013_real_instructor_auth.sql", "utf8");

test("real auth migration binds instructors to Supabase Auth users", () => {
  assert.match(migration, /alter table public\.instructors\s+add column if not exists auth_user_id uuid/i);
  assert.match(migration, /create unique index if not exists instructors_auth_user_id_idx/i);
});

test("real auth migration removes temporary anonymous demo policies", () => {
  assert.doesNotMatch(migration, /create policy\s+"demo_/i);
  assert.doesNotMatch(migration, new RegExp("to " + "anon", "i"));
  assert.match(migration, /drop policy if exists "demo_students_select_seed"/i);
  assert.match(migration, /drop policy if exists "demo_progress_items_update_seed"/i);
  assert.match(migration, /drop policy if exists "demo_assignments_update_seed"/i);
});

test("real auth migration scopes child records through instructor auth ownership", () => {
  assert.match(migration, /auth_user_id = \(select auth\.uid\(\)\)/i);
  assert.match(migration, /student_owner_can_access\(instructor_id\)/i);
  assert.match(migration, /progress_items_select_owner/i);
  assert.match(migration, /next_lesson_plans_update_owner/i);
});
