import { createClient } from "@supabase/supabase-js";

import { getSupabaseSetupStatus } from "@/lib/env";
import type { Database } from "@/types/database";

export function createBrowserSupabaseClient() {
  const status = getSupabaseSetupStatus();

  if (status.state !== "configured") {
    return null;
  }

  return createClient<Database>(
    status.env.NEXT_PUBLIC_SUPABASE_URL,
    status.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  );
}
