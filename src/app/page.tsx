import { SetupStatusPanel } from "@/components/dashboard/setup-status-panel";
import { getSupabaseSetupStatus } from "@/lib/env";

export default function Home() {
  const setupStatus = getSupabaseSetupStatus();

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

          <div className="rounded-lg border border-border bg-card p-6">
            <p className="quiet-label">Roster preview</p>
            <h2 className="mt-2 text-[22px] font-semibold leading-[1.2] text-pretty">
              Student data foundation
            </h2>
            <p className="mt-3 text-[15px] leading-[1.55] text-muted-foreground">
              The seed-backed roster appears here once Supabase environment variables and seed data are in place.
            </p>
          </div>
        </section>

        <aside className="space-y-4">
          <SetupStatusPanel status={setupStatus} />
        </aside>
      </div>
    </main>
  );
}
