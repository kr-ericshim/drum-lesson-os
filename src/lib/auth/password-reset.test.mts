import assert from "node:assert/strict";
import test from "node:test";

import {
  getPasswordRecoveryRedirectTo,
  passwordRecoveryRequestSchema,
  passwordResetInputSchema,
} from "./password-reset.ts";

test("passwordResetInputSchema trims and accepts matching password fields", () => {
  const parsed = passwordResetInputSchema.parse({
    password: "  new-secure-password  ",
    confirmPassword: "new-secure-password",
  });

  assert.deepEqual(parsed, {
    password: "new-secure-password",
    confirmPassword: "new-secure-password",
  });
});

test("passwordResetInputSchema rejects short or mismatched password fields", () => {
  assert.equal(
    passwordResetInputSchema.safeParse({
      password: "short",
      confirmPassword: "short",
    }).success,
    false,
  );

  assert.equal(
    passwordResetInputSchema.safeParse({
      password: "new-secure-password",
      confirmPassword: "different-secure-password",
    }).success,
    false,
  );
});

test("passwordRecoveryRequestSchema trims and accepts a valid email", () => {
  assert.deepEqual(
    passwordRecoveryRequestSchema.parse({
      email: "  instructor@example.com  ",
    }),
    {
      email: "instructor@example.com",
    },
  );
});

test("passwordRecoveryRequestSchema rejects invalid email", () => {
  assert.equal(
    passwordRecoveryRequestSchema.safeParse({
      email: "not-an-email",
    }).success,
    false,
  );
});

test("getPasswordRecoveryRedirectTo prefers a configured app origin", () => {
  assert.equal(
    getPasswordRecoveryRedirectTo(new Headers({ host: "evil.example" }), "https://drum.example"),
    "https://drum.example/reset-password",
  );
});

test("getPasswordRecoveryRedirectTo builds from trusted forwarding headers", () => {
  assert.equal(
    getPasswordRecoveryRedirectTo(
      new Headers({
        "x-forwarded-host": "drum.example",
        "x-forwarded-proto": "https",
      }),
      "",
    ),
    "https://drum.example/reset-password",
  );
});

test("getPasswordRecoveryRedirectTo ignores malformed hosts", () => {
  assert.equal(
    getPasswordRecoveryRedirectTo(new Headers({ host: "evil.example/@drum.example" }), "", "test"),
    "http://localhost:3000/reset-password",
  );
});

test("getPasswordRecoveryRedirectTo requires configured origin in production", () => {
  assert.throws(
    () => getPasswordRecoveryRedirectTo(new Headers({ host: "drum.example" }), "", "production"),
    /NEXT_PUBLIC_APP_ORIGIN/,
  );
});
