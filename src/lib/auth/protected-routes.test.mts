import assert from "node:assert/strict";
import test from "node:test";

import {
  getLoginRedirectUrl,
  getUnlinkedLoginRedirectUrl,
  getPostLoginRedirectPath,
  isProtectedAppPath,
} from "./protected-routes.ts";

test("isProtectedAppPath protects the instructor workbench and student routes", () => {
  assert.equal(isProtectedAppPath("/"), true);
  assert.equal(isProtectedAppPath("/students/new"), true);
  assert.equal(isProtectedAppPath("/students/kim-daniel"), true);
});

test("isProtectedAppPath leaves login and framework assets public", () => {
  assert.equal(isProtectedAppPath("/login"), false);
  assert.equal(isProtectedAppPath("/_next/static/chunk.js"), false);
  assert.equal(isProtectedAppPath("/favicon.ico"), false);
});

test("getLoginRedirectUrl preserves protected destinations as relative next paths", () => {
  assert.equal(
    getLoginRedirectUrl(new URL("https://drum.example/students/kim-daniel?tab=notes")),
    "https://drum.example/login?next=%2Fstudents%2Fkim-daniel%3Ftab%3Dnotes",
  );
});

test("getPostLoginRedirectPath only accepts protected relative next paths", () => {
  assert.equal(getPostLoginRedirectPath("/students/kim-daniel"), "/students/kim-daniel");
  assert.equal(getPostLoginRedirectPath("https://evil.example/phish"), "/");
  assert.equal(getPostLoginRedirectPath("/login"), "/");
});

test("getUnlinkedLoginRedirectUrl preserves destination and explains blocked account", () => {
  assert.equal(
    getUnlinkedLoginRedirectUrl(new URL("https://drum.example/students/kim-daniel")),
    "https://drum.example/login?next=%2Fstudents%2Fkim-daniel&error=unlinked",
  );
});
