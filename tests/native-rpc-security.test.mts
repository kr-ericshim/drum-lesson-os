import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import test from "node:test";

const nativeRpcMigrationPath = "supabase/migrations/0018_native_write_rpcs.sql";
const eventKitMigrationPath = "supabase/migrations/0019_native_eventkit_sync.sql";

const nativeFunctions = [
  "native_current_instructor_id",
  "native_create_student",
  "native_update_student_profile",
  "native_upsert_student_trait",
  "native_upsert_progress_item",
  "native_update_progress_status",
  "native_upsert_assignment",
  "native_create_lesson_note",
  "native_upsert_next_lesson_plan",
  "native_create_one_off_occurrence",
  "native_create_weekly_schedule_template",
  "native_insert_expanded_occurrences",
  "native_edit_occurrence_time",
  "native_cancel_occurrence",
  "native_update_occurrence_calendar_sync",
] as const;

const eventKitColumns = [
  "native_calendar_event_identifier",
  "native_calendar_identifier",
  "native_calendar_external_identifier",
  "native_calendar_sync_status",
  "native_calendar_sync_error",
  "native_calendar_synced_at",
] as const;

function readMigration(path: string) {
  assert.equal(existsSync(path), true, `${path} should exist`);
  return readFileSync(path, "utf8");
}

function functionSql(migration: string, functionName: string) {
  const nextFunctionPattern = String.raw`(?=\ncreate\s+or\s+replace\s+function\s+public\.native_|\nrevoke\s+execute|\ngrant\s+execute|$)`;
  const match = migration.match(
    new RegExp(
      String.raw`create\s+or\s+replace\s+function\s+public\.${functionName}\b[\s\S]*?${nextFunctionPattern}`,
      "i",
    ),
  );
  assert.ok(match, `public.${functionName} should be defined`);
  return match[0];
}

test("native write migration does not depend on service-role access", () => {
  const migration = readMigration(nativeRpcMigrationPath);

  assert.doesNotMatch(migration, /service[_ -]?role/i);
  assert.doesNotMatch(migration, /supabase_service_role/i);
});

test("native write migration creates EventKit columns before RPCs reference them", () => {
  const migration = readMigration(nativeRpcMigrationPath);
  const firstFunctionIndex = migration.search(/create\s+or\s+replace\s+function\s+public\.native_/i);
  assert.notEqual(firstFunctionIndex, -1, "native RPC migration should define native functions");

  for (const column of eventKitColumns) {
    const columnIndex = migration.search(new RegExp(String.raw`add\s+column\s+if\s+not\s+exists\s+${column}\b`, "i"));
    assert.notEqual(columnIndex, -1, `${column} should be created in 0018 before native RPCs compile`);
    assert.ok(columnIndex < firstFunctionIndex, `${column} should be declared before native RPC definitions`);
  }
});

test("native write migration defines every required RPC with security definer search path", () => {
  const migration = readMigration(nativeRpcMigrationPath);

  for (const functionName of nativeFunctions) {
    const sql = functionSql(migration, functionName);
    assert.match(sql, /security\s+definer/i, `${functionName} should be security definer`);
    assert.match(sql, /set\s+search_path\s*=\s*public/i, `${functionName} should pin search_path`);
  }
});

test("native write RPCs derive ownership through native_current_instructor_id", () => {
  const migration = readMigration(nativeRpcMigrationPath);

  const helperSql = functionSql(migration, "native_current_instructor_id");
  assert.match(helperSql, /auth\.uid\s*\(\s*\)/i);
  assert.match(helperSql, /from\s+public\.instructors/i);
  assert.match(helperSql, /auth_user_id\s*=\s*\(?\s*select\s+auth\.uid\s*\(\s*\)\s*\)?/i);

  for (const functionName of nativeFunctions.filter(
    (name) => name !== "native_current_instructor_id",
  )) {
    assert.match(
      functionSql(migration, functionName),
      /public\.native_current_instructor_id\s*\(\s*\)/i,
      `${functionName} should call native_current_instructor_id()`,
    );
  }
});

test("native write RPC grants are limited to authenticated users", () => {
  const migration = readMigration(nativeRpcMigrationPath);

  for (const functionName of nativeFunctions) {
    assert.match(
      migration,
      new RegExp(String.raw`revoke\s+execute\s+on\s+function\s+public\.${functionName}\b[\s\S]*?\s+from\s+public`, "i"),
      `${functionName} should revoke public execute`,
    );
    assert.match(
      migration,
      new RegExp(String.raw`revoke\s+execute\s+on\s+function\s+public\.${functionName}\b[\s\S]*?\s+from\s+anon`, "i"),
      `${functionName} should revoke anon execute`,
    );
    assert.match(
      migration,
      new RegExp(String.raw`grant\s+execute\s+on\s+function\s+public\.${functionName}\b[\s\S]*?\s+to\s+authenticated`, "i"),
      `${functionName} should grant authenticated execute`,
    );
  }
});

test("EventKit sync migration adds native calendar sync fields and read access", () => {
  const migration = readMigration(eventKitMigrationPath);

  for (const column of eventKitColumns) {
    assert.match(migration, new RegExp(String.raw`add\s+column\s+if\s+not\s+exists\s+${column}\b`, "i"));
    assert.match(migration, new RegExp(String.raw`grant\s+select\s*\([\s\S]*\b${column}\b[\s\S]*\)\s+on\s+public\.lesson_occurrences\s+to\s+authenticated`, "i"));
  }

  assert.match(migration, /lesson_occurrences_native_calendar_sync_idx/i);
  assert.match(migration, /native_calendar_sync_status\s+in\s+\('not_connected',\s*'pending',\s*'synced',\s*'failed',\s*'disabled'\)/i);
});
