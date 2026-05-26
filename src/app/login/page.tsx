import { redirect } from "next/navigation";

import { signInAction } from "@/app/login/actions";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getPostLoginRedirectPath } from "@/lib/auth/protected-routes";
import { loadCurrentInstructor } from "@/lib/auth/instructor";
import { getSupabaseSetupStatus } from "@/lib/env";

type LoginPageProps = {
  searchParams: Promise<{
    error?: string;
    next?: string;
  }>;
};

const errorMessageByCode: Record<string, string> = {
  invalid: "Email or password did not match an instructor account.",
  missing: "Enter both email and password.",
  setup: "Supabase environment variables are not configured.",
  unlinked: "This login is not linked to the instructor workspace.",
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const setupStatus = getSupabaseSetupStatus();
  const params = await searchParams;
  const nextPath = getPostLoginRedirectPath(params.next);

  if (setupStatus.state === "configured") {
    const instructorResult = await loadCurrentInstructor();

    if (instructorResult.ok) {
      redirect(nextPath);
    }
  }

  const errorMessage = params.error ? errorMessageByCode[params.error] : null;

  return (
    <main className="flex min-h-screen items-center bg-background px-4 py-8 text-foreground">
      <Card className="mx-auto w-full max-w-sm">
        <CardHeader className="space-y-2">
          <p className="quiet-label">Drum Lesson OS</p>
          <CardTitle>Instructor login</CardTitle>
          <p className="text-sm leading-6 text-muted-foreground">
            Sign in with the instructor account linked to this workspace.
          </p>
        </CardHeader>
        <CardContent>
          <form action={signInAction} className="space-y-4">
            <input type="hidden" name="next" value={nextPath} />
            <label className="block space-y-1.5">
              <span className="field-label">Email</span>
              <input
                className="min-h-11 w-full rounded-md border border-input bg-background px-3 py-2 text-sm outline-none ring-ring transition focus-visible:ring-2"
                name="email"
                type="email"
                autoComplete="email"
                required
              />
            </label>
            <label className="block space-y-1.5">
              <span className="field-label">Password</span>
              <input
                className="min-h-11 w-full rounded-md border border-input bg-background px-3 py-2 text-sm outline-none ring-ring transition focus-visible:ring-2"
                name="password"
                type="password"
                autoComplete="current-password"
                required
              />
            </label>
            {errorMessage ? (
              <p className="rounded-md border border-destructive/30 bg-destructive/10 p-3 text-sm leading-5 text-destructive">
                {errorMessage}
              </p>
            ) : null}
            {setupStatus.state === "missing" ? (
              <p className="rounded-md border border-border bg-secondary p-3 text-sm leading-5 text-muted-foreground">
                Missing: {setupStatus.missing.join(", ")}
              </p>
            ) : null}
            <Button className="w-full" type="submit">
              Sign in
            </Button>
          </form>
        </CardContent>
      </Card>
    </main>
  );
}
