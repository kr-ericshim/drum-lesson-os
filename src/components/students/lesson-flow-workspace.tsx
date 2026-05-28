"use client";

import { useState } from "react";

import { LessonBrief } from "@/components/students/lesson-brief";
import { LessonCloseoutForm } from "@/components/students/lesson-closeout-form";
import { LessonRunPanel } from "@/components/students/lesson-run-panel";
import type { LessonCloseoutDraft } from "@/lib/students/lesson-closeout-draft";
import type { StudentDetail } from "@/lib/supabase/queries";

type LessonFlowWorkspaceProps = {
  student: StudentDetail;
};

export function LessonFlowWorkspace({ student }: LessonFlowWorkspaceProps) {
  const [draft, setDraft] = useState<LessonCloseoutDraft | null>(null);
  const [draftVersion, setDraftVersion] = useState(0);

  function handleDraftReady(nextDraft: LessonCloseoutDraft) {
    setDraft(nextDraft);
    setDraftVersion((current) => current + 1);
  }

  return (
    <section className="space-y-6" aria-label={`${student.name} lesson flow`}>
      <LessonBrief student={student} />
      <LessonRunPanel student={student} onDraftReady={handleDraftReady} />
      <LessonCloseoutForm key={draftVersion} draft={draft} student={student} />
    </section>
  );
}
