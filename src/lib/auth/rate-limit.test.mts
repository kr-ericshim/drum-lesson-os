import assert from "node:assert/strict";
import test, { afterEach } from "node:test";

import {
  clearRateLimit,
  consumeRateLimit,
  getAuthRateLimitKeys,
  resetRateLimitsForTest,
} from "./rate-limit.ts";

afterEach(() => {
  resetRateLimitsForTest();
});

test("consumeRateLimit allows configured attempts and blocks the next one", () => {
  const options = { maxAttempts: 2, windowMs: 60_000 };

  assert.equal(consumeRateLimit("login:id:test@example.com", options, 1_000).allowed, true);
  assert.equal(consumeRateLimit("login:id:test@example.com", options, 2_000).allowed, true);

  const blocked = consumeRateLimit("login:id:test@example.com", options, 3_000);

  assert.equal(blocked.allowed, false);

  if (!blocked.allowed) {
    assert.equal(blocked.retryAfterSeconds, 58);
  }
});

test("consumeRateLimit starts a new bucket after the window resets", () => {
  const options = { maxAttempts: 1, windowMs: 60_000 };

  assert.equal(consumeRateLimit("login:ip:127.0.0.1", options, 1_000).allowed, true);
  assert.equal(consumeRateLimit("login:ip:127.0.0.1", options, 2_000).allowed, false);
  assert.equal(consumeRateLimit("login:ip:127.0.0.1", options, 62_000).allowed, true);
});

test("clearRateLimit removes a successful login bucket", () => {
  const options = { maxAttempts: 1, windowMs: 60_000 };

  assert.equal(consumeRateLimit("login:id:test@example.com", options, 1_000).allowed, true);
  clearRateLimit("login:id:test@example.com");
  assert.equal(consumeRateLimit("login:id:test@example.com", options, 2_000).allowed, true);
});

test("getAuthRateLimitKeys normalizes email and forwarded IP", () => {
  const headers = new Headers({
    "x-forwarded-for": "203.0.113.10, 10.0.0.1",
  });

  assert.deepEqual(getAuthRateLimitKeys("login", " Instructor@Example.COM ", headers), [
    "login:ip:203.0.113.10",
    "login:id:instructor@example.com",
  ]);
});
