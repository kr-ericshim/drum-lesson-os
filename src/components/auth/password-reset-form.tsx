"use client";

import { type FormEvent, useEffect, useState } from "react";
import Link from "next/link";

import { Button } from "@/components/ui/button";
import { passwordResetInputSchema } from "@/lib/auth/password-reset";
import { createBrowserSupabaseClient } from "@/lib/supabase/client";

type FormStatus =
  | { state: "checking"; message: string; canSubmit: false }
  | { state: "ready"; message: string; canSubmit: true }
  | { state: "submitting"; message: string; canSubmit: false }
  | { state: "success"; message: string; canSubmit: false }
  | { state: "error"; message: string; canSubmit: boolean };

function getRecoveryHashError() {
  if (typeof window === "undefined" || !window.location.hash) {
    return null;
  }

  const params = new URLSearchParams(window.location.hash.slice(1));
  const errorCode = params.get("error_code");

  if (errorCode === "otp_expired") {
    return "This recovery link expired. Send a new password recovery email and open the newest link.";
  }

  if (params.get("error")) {
    return params.get("error_description") ?? "This recovery link could not be used.";
  }

  return null;
}

export function PasswordResetForm() {
  const [status, setStatus] = useState<FormStatus>({
    state: "checking",
    message: "Checking the recovery link.",
    canSubmit: false,
  });

  useEffect(() => {
    let isCurrent = true;

    async function checkRecoverySession() {
      const hashError = getRecoveryHashError();

      if (hashError) {
        setStatus({ state: "error", message: hashError, canSubmit: false });
        return;
      }

      const supabase = createBrowserSupabaseClient();

      if (!supabase) {
        setStatus({
          state: "error",
          message: "Supabase environment variables are not configured.",
          canSubmit: false,
        });
        return;
      }

      const { data, error } = await supabase.auth.getSession();

      if (!isCurrent) {
        return;
      }

      if (error) {
        setStatus({ state: "error", message: error.message, canSubmit: false });
        return;
      }

      if (!data.session) {
        setStatus({
          state: "error",
          message: "Open the newest password recovery email before setting a new password.",
          canSubmit: false,
        });
        return;
      }

      setStatus({
        state: "ready",
        message: "Enter a new password for this instructor account.",
        canSubmit: true,
      });
    }

    void checkRecoverySession();

    return () => {
      isCurrent = false;
    };
  }, []);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const parsed = passwordResetInputSchema.safeParse({
      password: event.currentTarget.password.value,
      confirmPassword: event.currentTarget.confirmPassword.value,
    });

    if (!parsed.success) {
      setStatus({
        state: "error",
        message: "Use a matching password between 8 and 72 characters.",
        canSubmit: true,
      });
      return;
    }

    const supabase = createBrowserSupabaseClient();

    if (!supabase) {
      setStatus({
        state: "error",
        message: "Supabase environment variables are not configured.",
        canSubmit: false,
      });
      return;
    }

    setStatus({ state: "submitting", message: "Saving the new password.", canSubmit: false });

    const { error } = await supabase.auth.updateUser({ password: parsed.data.password });

    if (error) {
      setStatus({ state: "error", message: error.message, canSubmit: true });
      return;
    }

    await supabase.auth.signOut();
    setStatus({
      state: "success",
      message: "Password updated. Sign in again with the new password.",
      canSubmit: false,
    });
    event.currentTarget.reset();
  }

  const isDisabled = !status.canSubmit;

  return (
    <form className="space-y-4" onSubmit={handleSubmit}>
      <label className="block space-y-1.5">
        <span className="field-label">New password</span>
        <input
          className="min-h-11 w-full rounded-md border border-input bg-background px-3 py-2 text-sm outline-none ring-ring transition focus-visible:ring-2"
          name="password"
          type="password"
          autoComplete="new-password"
          minLength={8}
          maxLength={72}
          disabled={isDisabled}
          required
        />
      </label>
      <label className="block space-y-1.5">
        <span className="field-label">Confirm password</span>
        <input
          className="min-h-11 w-full rounded-md border border-input bg-background px-3 py-2 text-sm outline-none ring-ring transition focus-visible:ring-2"
          name="confirmPassword"
          type="password"
          autoComplete="new-password"
          minLength={8}
          maxLength={72}
          disabled={isDisabled}
          required
        />
      </label>
      <p
        className={
          status.state === "error"
            ? "rounded-md border border-destructive/30 bg-destructive/10 p-3 text-sm leading-5 text-destructive"
            : "rounded-md border border-border bg-secondary p-3 text-sm leading-5 text-muted-foreground"
        }
      >
        {status.message}
      </p>
      {status.state === "success" ? (
        <Button asChild className="w-full">
          <Link href="/login">Back to sign in</Link>
        </Button>
      ) : (
        <Button className="w-full" disabled={isDisabled} type="submit">
          Save new password
        </Button>
      )}
    </form>
  );
}
