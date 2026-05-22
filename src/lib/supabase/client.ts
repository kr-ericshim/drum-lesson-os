import { createClient } from "@supabase/supabase-js";

import { getSupabaseSetupStatus } from "@/lib/env";

export function createBrowserSupabaseClient() {
  const status = getSupabaseSetupStatus();

  if (status.state !== "configured") {
    return null;
  }

  return createClient(
    status.env.NEXT_PUBLIC_SUPABASE_URL,
    status.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  );
}
