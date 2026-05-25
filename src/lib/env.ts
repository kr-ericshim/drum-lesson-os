import { z } from "zod";

const publicSupabaseEnvSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1).optional(),
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: z.string().min(1).optional(),
  NEXT_PUBLIC_DEMO_INSTRUCTOR_ID: z.string().uuid().optional(),
}).refine(
  (env) => env.NEXT_PUBLIC_SUPABASE_ANON_KEY || env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  {
    message: "Supabase public key is required.",
    path: ["NEXT_PUBLIC_SUPABASE_ANON_KEY"],
  },
);

type PublicSupabaseEnv = z.infer<typeof publicSupabaseEnvSchema> & {
  NEXT_PUBLIC_SUPABASE_KEY: string;
};

export type SupabaseSetupStatus =
  | {
      state: "missing";
      label: "Review setup";
      missing: string[];
    }
  | {
      state: "configured";
      label: "Supabase connected";
      env: PublicSupabaseEnv;
    };

export function getSupabaseSetupStatus(): SupabaseSetupStatus {
  const parsed = publicSupabaseEnvSchema.safeParse({
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    NEXT_PUBLIC_DEMO_INSTRUCTOR_ID: process.env.NEXT_PUBLIC_DEMO_INSTRUCTOR_ID || undefined,
  });

  if (parsed.success) {
    return {
      state: "configured",
      label: "Supabase connected",
      env: {
        ...parsed.data,
        NEXT_PUBLIC_SUPABASE_KEY:
          parsed.data.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
          parsed.data.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
      },
    };
  }

  const missing = ["NEXT_PUBLIC_SUPABASE_URL"].filter((key) => !process.env[key]);

  if (
    !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY &&
    !process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
  ) {
    missing.push("NEXT_PUBLIC_SUPABASE_ANON_KEY or NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY");
  }

  return {
    state: "missing",
    label: "Review setup",
    missing,
  };
}
