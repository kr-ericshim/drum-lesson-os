import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";
import { createClient } from "@supabase/supabase-js";

import { getSupabaseSetupStatus } from "@/lib/env";
import type { Database } from "@/types/database";

export async function createServerSupabaseClient() {
  const status = getSupabaseSetupStatus();

  if (status.state !== "configured") {
    return null;
  }

  const cookieStore = await cookies();

  return createServerClient<Database>(
    status.env.NEXT_PUBLIC_SUPABASE_URL,
    status.env.NEXT_PUBLIC_SUPABASE_KEY,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) => {
              cookieStore.set(name, value, options);
            });
          } catch {
            // Server components cannot always set cookies; middleware can refresh them later.
          }
        },
      },
    },
  );
}

export function createServerSupabaseAnonClient() {
  const status = getSupabaseSetupStatus();

  if (status.state !== "configured") {
    return null;
  }

  return createClient<Database>(
    status.env.NEXT_PUBLIC_SUPABASE_URL,
    status.env.NEXT_PUBLIC_SUPABASE_KEY,
  );
}
