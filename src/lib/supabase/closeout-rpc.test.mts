import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import test from "node:test";

const migrationPath = "supabase/migrations/0014_closeout_lesson_rpc.sql";
const actionPath = "src/app/students/[studentId]/actions.ts";

test("closeout release migration defines one authenticated RPC", () => {
  assert.equal(existsSync(migrationPath), true);

  const migration = readFileSync(migrationPath, "utf8");

  assert.match(migration, /create or replace function public\.closeout_lesson/i);
  assert.match(migration, /language plpgsql/i);
  assert.match(migration, /revoke execute on function public\.closeout_lesson/i);
  assert.match(migration, /grant execute on function public\.closeout_lesson/i);
  assert.match(migration, /to authenticated/i);
});

test("closeout RPC owns the multi-table write sequence", () => {
  const migration = readFileSync(migrationPath, "utf8");

  assert.match(migration, /insert into public\.lesson_notes/i);
  assert.match(migration, /insert into public\.next_lesson_plans/i);
  assert.match(migration, /update public\.next_lesson_plans/i);
  assert.match(migration, /insert into public\.assignments/i);
  assert.match(migration, /update public\.assignments/i);
  assert.match(migration, /update public\.progress_items/i);
  assert.match(migration, /raise exception 'Student was not found\.'/i);
});

test("closeout server action delegates to the RPC instead of sequential table writes", () => {
  const actionSource = readFileSync(actionPath, "utf8");
  const closeoutSource = actionSource.slice(actionSource.indexOf("export async function closeoutLessonAction"));

  assert.match(closeoutSource, /supabase\.rpc\("closeout_lesson"/);
  assert.doesNotMatch(closeoutSource, /\.from\("lesson_notes"\)\.insert/);
  assert.doesNotMatch(closeoutSource, /\.from\("next_lesson_plans"\)/);
  assert.doesNotMatch(closeoutSource, /\.from\("assignments"\)/);
  assert.doesNotMatch(closeoutSource, /\.from\("progress_items"\)/);
});
