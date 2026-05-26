"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";

import {
  getPasswordRecoveryRedirectTo,
  passwordRecoveryRequestSchema,
} from "@/lib/auth/password-reset";
import { consumeRateLimit, getAuthRateLimitKeys } from "@/lib/auth/rate-limit";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const passwordRecoveryIpRateLimit = {
  maxAttempts: 5,
  windowMs: 60 * 60 * 1000,
};

const passwordRecoveryEmailRateLimit = {
  maxAttempts: 3,
  windowMs: 60 * 60 * 1000,
};

function forgotPasswordPathWithStatus(status: "invalid" | "sent" | "setup") {
  return `/forgot-password?status=${status}`;
}

export async function requestPasswordRecoveryAction(formData: FormData): Promise<void> {
  const parsed = passwordRecoveryRequestSchema.safeParse({
    email: formData.get("email"),
  });

  if (!parsed.success) {
    redirect(forgotPasswordPathWithStatus("invalid"));
  }

  const requestHeaders = await headers();
  const [ipRateLimitKey, emailRateLimitKey] = getAuthRateLimitKeys(
    "password-recovery",
    parsed.data.email,
    requestHeaders,
  );
  const ipLimit = consumeRateLimit(ipRateLimitKey, passwordRecoveryIpRateLimit);
  const emailLimit = consumeRateLimit(emailRateLimitKey, passwordRecoveryEmailRateLimit);

  if (!ipLimit.allowed || !emailLimit.allowed) {
    redirect(forgotPasswordPathWithStatus("sent"));
  }

  const supabase = await createServerSupabaseClient();

  if (!supabase) {
    redirect(forgotPasswordPathWithStatus("setup"));
  }

  await supabase.auth.resetPasswordForEmail(parsed.data.email, {
    redirectTo: getPasswordRecoveryRedirectTo(requestHeaders),
  });

  redirect(forgotPasswordPathWithStatus("sent"));
}
