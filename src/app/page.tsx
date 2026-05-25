import { SetupStatusPanel } from "@/components/dashboard/setup-status-panel";
import { StudentRosterPreview } from "@/components/dashboard/student-roster-preview";
import { getSupabaseSetupStatus } from "@/lib/env";
import { getStudentRoster } from "@/lib/supabase/queries";

export default async function Home() {
  const setupStatus = getSupabaseSetupStatus();
  const rosterResult =
    setupStatus.state === "configured"
      ? await getStudentRoster()
      : { data: [], error: null };

  return (
    <main className="min-h-screen bg-background text-foreground">
      <div className="mx-auto grid w-full max-w-6xl gap-8 px-4 py-8 sm:px-6 lg:grid-cols-[minmax(0,1fr)_320px] lg:px-8 lg:py-12">
        <section className="min-w-0 space-y-6">
          <div className="space-y-2">
            <p className="quiet-label">Drum Lesson OS</p>
            <h1 className="font-display text-[30px] font-medium leading-[1.1] text-pretty">
              Student progress, traits, and next lesson cues
            </h1>
            <p className="max-w-2xl text-[15px] leading-[1.55] text-muted-foreground text-pretty">
              A working surface for tracking what each student is practicing, where they get stuck, and what should happen next.
            </p>
          </div>

          <StudentRosterPreview
            students={rosterResult.data}
            error={rosterResult.error}
            setupMissing={setupStatus.state === "missing"}
          />
        </section>

        <aside className="space-y-4">
          <SetupStatusPanel status={setupStatus} />
        </aside>
      </div>
    </main>
  );
}
