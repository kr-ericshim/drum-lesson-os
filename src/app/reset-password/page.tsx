import { PasswordResetForm } from "@/components/auth/password-reset-form";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function ResetPasswordPage() {
  return (
    <main className="flex min-h-screen items-center bg-background px-4 py-8 text-foreground">
      <Card className="mx-auto w-full max-w-sm">
        <CardHeader className="space-y-2">
          <p className="quiet-label">Drum Lesson OS</p>
          <CardTitle>Reset password</CardTitle>
          <p className="text-sm leading-6 text-muted-foreground">
            Set a new password after opening the recovery email from Supabase.
          </p>
        </CardHeader>
        <CardContent>
          <PasswordResetForm />
        </CardContent>
      </Card>
    </main>
  );
}
