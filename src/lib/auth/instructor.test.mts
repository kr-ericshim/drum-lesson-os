import assert from "node:assert/strict";
import test from "node:test";

import { getCurrentInstructor } from "./instructor.ts";

function createClient({
  userId,
  instructor,
  authError = null,
  instructorError = null,
}: {
  userId?: string;
  instructor?: { id: string; display_name: string; studio_name: string | null };
  authError?: Error | null;
  instructorError?: Error | null;
}) {
  return {
    auth: {
      async getUser() {
        return {
          data: { user: userId ? { id: userId } : null },
          error: authError,
        };
      },
    },
    from(table: string) {
      assert.equal(table, "instructors");

      return {
        select(columns: string) {
          assert.equal(columns, "id, display_name, studio_name");

          return {
            eq(column: string, value: string) {
              assert.equal(column, "auth_user_id");
              assert.equal(value, userId);

              return {
                async maybeSingle() {
                  return {
                    data: instructor ?? null,
                    error: instructorError,
                  };
                },
              };
            },
          };
        },
      };
    },
  };
}

test("getCurrentInstructor returns the instructor owned by the authenticated Supabase user", async () => {
  const result = await getCurrentInstructor(createClient({
    userId: "auth-user-1",
    instructor: {
      id: "11111111-1111-4111-8111-111111111111",
      display_name: "Eric",
      studio_name: "Drum Lab",
    },
  }));

  assert.deepEqual(result, {
    ok: true,
    instructor: {
      id: "11111111-1111-4111-8111-111111111111",
      displayName: "Eric",
      studioName: "Drum Lab",
    },
  });
});

test("getCurrentInstructor rejects missing or unbound auth users", async () => {
  assert.deepEqual(await getCurrentInstructor(createClient({})), {
    ok: false,
    reason: "signed_out",
    message: "Sign in to access Drum Lesson OS.",
  });

  assert.deepEqual(await getCurrentInstructor(createClient({ userId: "auth-user-2" })), {
    ok: false,
    reason: "instructor_not_found",
    message: "No instructor profile is linked to this login.",
  });
});
