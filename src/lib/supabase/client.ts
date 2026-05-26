import { createBrowserClient } from "@supabase/ssr";

import { getSupabaseSetupStatus } from "@/lib/env";
import type { Database } from "@/types/database";

export function createBrowserSupabaseClient() {
  const status = getSupabaseSetupStatus();

  if (status.state !== "configured") {
    return null;
  }

  return createBrowserClient<Database>(
    status.env.NEXT_PUBLIC_SUPABASE_URL,
    status.env.NEXT_PUBLIC_SUPABASE_KEY,
  );
}
