"use server";

import { redirect } from "next/navigation";

import { getPostLoginRedirectPath } from "@/lib/auth/protected-routes";
import { createServerSupabaseClient } from "@/lib/supabase/server";

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

  redirect(nextPath);
}

export async function signOutAction(): Promise<void> {
  const supabase = await createServerSupabaseClient();

  if (supabase) {
    await supabase.auth.signOut();
  }

  redirect("/login");
}
