"use server";

import { redirect } from "next/navigation";
import { headers } from "next/headers";

import { getPostLoginRedirectPath } from "@/lib/auth/protected-routes";
import { clearRateLimit, consumeRateLimit, getAuthRateLimitKeys } from "@/lib/auth/rate-limit";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const loginIpRateLimit = {
  maxAttempts: 30,
  windowMs: 15 * 60 * 1000,
};

const loginEmailRateLimit = {
  maxAttempts: 5,
  windowMs: 15 * 60 * 1000,
};

function loginPathWithError(error: string, nextPath: string) {
  const params = new URLSearchParams({ error });

  if (nextPath !== "/") {
    params.set("next", nextPath);
  }

  return `/login?${params.toString()}`;
}

export async function signInAction(formData: FormData): Promise<void> {
  const email = formData.get("email");
  const password = formData.get("password");
  const nextPath = getPostLoginRedirectPath(formData.get("next"));

  if (typeof email !== "string" || typeof password !== "string" || !email || !password) {
    redirect(loginPathWithError("missing", nextPath));
  }

  const requestHeaders = await headers();
  const [ipRateLimitKey, emailRateLimitKey] = getAuthRateLimitKeys(
    "login",
    email,
    requestHeaders,
  );
  const ipLimit = consumeRateLimit(ipRateLimitKey, loginIpRateLimit);
  const emailLimit = consumeRateLimit(emailRateLimitKey, loginEmailRateLimit);

  if (!ipLimit.allowed || !emailLimit.allowed) {
    redirect(loginPathWithError("rate_limited", nextPath));
  }

  const supabase = await createServerSupabaseClient();

  if (!supabase) {
    redirect(loginPathWithError("setup", nextPath));
  }

  const { error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    redirect(loginPathWithError("invalid", nextPath));
  }

  clearRateLimit(emailRateLimitKey);
  redirect(nextPath);
}

export async function signOutAction(): Promise<void> {
  const supabase = await createServerSupabaseClient();

  if (supabase) {
    await supabase.auth.signOut();
  }

  redirect("/login");
}
