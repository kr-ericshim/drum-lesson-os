import Link from "next/link";

import { createStudentAction } from "@/app/students/new/actions";
import { SetupStatusPanel } from "@/components/dashboard/setup-status-panel";
import { StudentProfileForm } from "@/components/students/student-profile-form";
import { Button } from "@/components/ui/button";
import { getSupabaseSetupStatus } from "@/lib/env";

export default function NewStudentPage() {
  const setupStatus = getSupabaseSetupStatus();

  if (setupStatus.state === "missing") {
    return (
      <main className="min-h-screen bg-background text-foreground">
        <div className="mx-auto grid w-full max-w-6xl gap-8 px-4 py-8 sm:px-6 lg:grid-cols-[minmax(0,1fr)_320px] lg:px-8 lg:py-12">
          <section className="rounded-lg border border-border bg-card p-5">
            <p className="quiet-label">New student</p>
            <h1 className="mt-2 text-[24px] font-semibold leading-[1.2] text-pretty">
              Supabase setup needed
            </h1>
            <p className="mt-2 max-w-2xl text-sm leading-6 text-muted-foreground text-pretty">
              Add environment variables and run the seed step before creating student records.
            </p>
            <Button asChild className="mt-5">
              <Link href="/">Student roster</Link>
            </Button>
          </section>
          <aside>
            <SetupStatusPanel status={setupStatus} />
          </aside>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-background text-foreground">
      <div className="mx-auto grid w-full max-w-6xl gap-8 px-4 py-8 sm:px-6 lg:grid-cols-[minmax(0,1fr)_320px] lg:px-8 lg:py-12">
        <section className="min-w-0 space-y-4">
          <Button asChild variant="ghost">
            <Link href="/">Back to roster</Link>
          </Button>
          <StudentProfileForm action={createStudentAction} mode="create" />
        </section>
        <aside>
          <SetupStatusPanel status={setupStatus} />
        </aside>
      </div>
    </main>
  );
}
