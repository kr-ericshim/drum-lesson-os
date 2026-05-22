import { z } from "zod";

const publicSupabaseEnvSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  NEXT_PUBLIC_DEMO_INSTRUCTOR_ID: z.string().uuid().optional(),
});

export type SupabaseSetupStatus =
  | {
      state: "missing";
      label: "Review setup";
      missing: string[];
    }
  | {
      state: "configured";
      label: "Supabase connected";
      env: z.infer<typeof publicSupabaseEnvSchema>;
    };

export function getSupabaseSetupStatus(): SupabaseSetupStatus {
  const parsed = publicSupabaseEnvSchema.safeParse({
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    NEXT_PUBLIC_DEMO_INSTRUCTOR_ID: process.env.NEXT_PUBLIC_DEMO_INSTRUCTOR_ID || undefined,
  });

  if (parsed.success) {
    return {
      state: "configured",
      label: "Supabase connected",
      env: parsed.data,
    };
  }

  const missing = ["NEXT_PUBLIC_SUPABASE_URL", "NEXT_PUBLIC_SUPABASE_ANON_KEY"].filter(
    (key) => !process.env[key],
  );

  return {
    state: "missing",
    label: "Review setup",
    missing,
  };
}
