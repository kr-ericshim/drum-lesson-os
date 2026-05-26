import Link from "next/link";

import { requestPasswordRecoveryAction } from "@/app/forgot-password/actions";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

type ForgotPasswordPageProps = {
  searchParams: Promise<{
    status?: string;
  }>;
};

const statusMessageByCode: Record<string, string> = {
  invalid: "Enter a valid email address.",
  sent: "If this email is linked to an instructor account, a recovery email has been sent.",
  setup: "Supabase environment variables are not configured.",
};

export default async function ForgotPasswordPage({ searchParams }: ForgotPasswordPageProps) {
  const params = await searchParams;
  const statusMessage = params.status ? statusMessageByCode[params.status] : null;
  const isError = params.status === "invalid" || params.status === "setup";

  return (
    <main className="flex min-h-screen items-center bg-background px-4 py-8 text-foreground">
      <Card className="mx-auto w-full max-w-sm">
        <CardHeader className="space-y-2">
          <p className="quiet-label">Drum Lesson OS</p>
          <CardTitle>Reset password</CardTitle>
          <p className="text-sm leading-6 text-muted-foreground">
            Send a password recovery email for the instructor account.
          </p>
        </CardHeader>
        <CardContent>
          <form action={requestPasswordRecoveryAction} className="space-y-4">
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
            {statusMessage ? (
              <p
                className={
                  isError
                    ? "rounded-md border border-destructive/30 bg-destructive/10 p-3 text-sm leading-5 text-destructive"
                    : "rounded-md border border-border bg-secondary p-3 text-sm leading-5 text-muted-foreground"
                }
              >
                {statusMessage}
              </p>
            ) : null}
            <Button className="w-full" type="submit">
              Send recovery email
            </Button>
            <Button asChild className="w-full" type="button" variant="ghost">
              <Link href="/login">Back to sign in</Link>
            </Button>
          </form>
        </CardContent>
      </Card>
    </main>
  );
}
