import Link from "next/link";

import { SetupStatusPanel } from "@/components/dashboard/setup-status-panel";
import { LessonBrief } from "@/components/students/lesson-brief";
import { StudentDetailHeader } from "@/components/students/student-detail-header";
import { StudentDetailTabs } from "@/components/students/student-detail-tabs";
import { Button } from "@/components/ui/button";
import { getSupabaseSetupStatus } from "@/lib/env";
import { getStudentDetail } from "@/lib/supabase/queries";

type StudentDetailPageProps = {
  params: Promise<{
    studentId?: string;
  }>;
};

export default async function StudentDetailPage({ params }: StudentDetailPageProps) {
  const { studentId } = await params;
  const setupStatus = getSupabaseSetupStatus();

  if (setupStatus.state === "missing") {
    return (
      <StudentDetailState
        title="Supabase setup needed"
        body="Add environment variables and run the seed step before loading student records."
        setupStatus={setupStatus}
      />
    );
  }

  if (!studentId) {
    return (
      <StudentDetailState
        title="Student not found"
        body="Return to the roster and choose an active student."
        setupStatus={setupStatus}
      />
    );
  }

  const studentResult = await getStudentDetail(studentId);

  if (studentResult.error) {
    return (
      <StudentDetailState
        title="Student data could not be loaded"
        body="Check Supabase environment variables, database access, and seed state."
        detail={studentResult.error}
        setupStatus={setupStatus}
      />
    );
  }

  if (!studentResult.data) {
    return (
      <StudentDetailState
        title="Student not found"
        body="Return to the roster and choose an active student."
        setupStatus={setupStatus}
      />
    );
  }

  return (
    <main className="min-h-screen bg-background text-foreground">
      <div className="mx-auto w-full max-w-6xl space-y-6 px-4 py-8 sm:px-6 lg:px-8 lg:py-12">
        <StudentDetailHeader student={studentResult.data} />
        <LessonBrief student={studentResult.data} />
        <StudentDetailTabs student={studentResult.data} />
      </div>
    </main>
  );
}

function StudentDetailState({
  title,
  body,
  detail,
  setupStatus,
}: {
  title: string;
  body: string;
  detail?: string;
  setupStatus: ReturnType<typeof getSupabaseSetupStatus>;
}) {
  return (
    <main className="min-h-screen bg-background text-foreground">
      <div className="mx-auto grid w-full max-w-6xl gap-8 px-4 py-8 sm:px-6 lg:grid-cols-[minmax(0,1fr)_320px] lg:px-8 lg:py-12">
        <section className="rounded-lg border border-border bg-card p-5">
          <p className="quiet-label">Student detail</p>
          <h1 className="mt-2 text-[24px] font-semibold leading-[1.2] text-pretty">{title}</h1>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-muted-foreground text-pretty">
            {body}
          </p>
          {detail ? (
            <p className="mt-3 break-words text-xs leading-5 text-muted-foreground">{detail}</p>
          ) : null}
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
