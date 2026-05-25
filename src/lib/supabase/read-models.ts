export type AssignmentContextRow = {
  status: string;
  created_at: string;
  title?: string;
  due_date?: string | null;
  detail?: string;
};

export type NextPlanContextRow = {
  id: string;
  next_action: string;
  priority: string;
  created_at: string;
  planned_for?: string | null;
  detail?: string;
};

export type StudentRosterSourceRow = {
  id: string;
  name: string;
  profile_cue: string;
  current_focus: string;
  primary_weak_point: string;
  assignments: AssignmentContextRow[];
  next_lesson_plans: NextPlanContextRow[];
};

export type StudentRosterItem = {
  id: string;
  name: string;
  profileCue: string;
  currentFocus: string;
  weakPoint: string;
  assignmentStatus: string;
  nextAction: string;
};

export type ProgressItemSourceRow = {
  id: string;
  category: string;
  status: string;
  title: string;
  current_focus: boolean;
  observed_on: string;
  detail: string;
};

export type StudentTraitSourceRow = {
  id: string;
  trait_type: string;
  label: string;
  detail: string;
};

export type LessonNoteSourceRow = {
  id: string;
  lesson_date: string;
  covered_material: string;
  observations: string;
  practice_assigned: string;
  next_step_hint: string;
};

export type StudentDetailSourceRow = StudentRosterSourceRow & {
  progress_items: ProgressItemSourceRow[];
  student_traits: StudentTraitSourceRow[];
  lesson_notes: LessonNoteSourceRow[];
};

export type StudentProgressItem = {
  id: string;
  category: string;
  status: string;
  title: string;
  currentFocus: boolean;
  observedOn: string;
  detail: string;
};

export type StudentTrait = {
  id: string;
  type: string;
  label: string;
  detail: string;
};

export type StudentAssignment = {
  status: string;
  title: string;
  dueDate: string | null;
  detail: string;
};

export type StudentNextPlan = {
  id: string;
  nextAction: string;
  priority: string;
  plannedFor: string | null;
  detail: string;
};

export type StudentLessonNote = {
  id: string;
  lessonDate: string;
  coveredMaterial: string;
  observations: string;
  practiceAssigned: string;
  nextStepHint: string;
};

export type StudentDetail = StudentRosterItem & {
  progressItems: StudentProgressItem[];
  traits: StudentTrait[];
  assignment: StudentAssignment | null;
  nextPlan: StudentNextPlan | null;
  recentNotes: StudentLessonNote[];
};

const priorityRank: Record<string, number> = {
  high: 0,
  normal: 1,
  low: 2,
};

export function pickLatestAssignment(assignments: AssignmentContextRow[]) {
  return [...assignments].sort((a, b) => b.created_at.localeCompare(a.created_at))[0];
}

export function pickPriorityNextPlan(nextPlans: NextPlanContextRow[]) {
  return [...nextPlans].sort((a, b) => {
    const priorityDifference =
      (priorityRank[a.priority] ?? priorityRank.normal) -
      (priorityRank[b.priority] ?? priorityRank.normal);

    if (priorityDifference !== 0) {
      return priorityDifference;
    }

    return b.created_at.localeCompare(a.created_at);
  })[0];
}

export function mapStudentRoster(students: StudentRosterSourceRow[]): StudentRosterItem[] {
  return students.map((student) => {
    const assignment = pickLatestAssignment(student.assignments);
    const nextPlan = pickPriorityNextPlan(student.next_lesson_plans);

    return {
      id: student.id,
      name: student.name,
      profileCue: student.profile_cue,
      currentFocus: student.current_focus,
      weakPoint: student.primary_weak_point,
      assignmentStatus: assignment?.status ?? "not_started",
      nextAction: nextPlan?.next_action ?? "Set next lesson action",
    };
  });
}

export function mapStudentDetail(student: StudentDetailSourceRow): StudentDetail {
  const [rosterItem] = mapStudentRoster([student]);
  const assignment = pickLatestAssignment(student.assignments);
  const nextPlan = pickPriorityNextPlan(student.next_lesson_plans);

  return {
    ...rosterItem,
    progressItems: [...student.progress_items]
      .sort((a, b) => b.observed_on.localeCompare(a.observed_on))
      .map((item) => ({
        id: item.id,
        category: item.category,
        status: item.status,
        title: item.title,
        currentFocus: item.current_focus,
        observedOn: item.observed_on,
        detail: item.detail,
      })),
    traits: [...student.student_traits]
      .sort((a, b) => a.trait_type.localeCompare(b.trait_type) || a.label.localeCompare(b.label))
      .map((trait) => ({
        id: trait.id,
        type: trait.trait_type,
        label: trait.label,
        detail: trait.detail,
      })),
    assignment: assignment
      ? {
          status: assignment.status,
          title: assignment.title ?? "Current assignment",
          dueDate: assignment.due_date ?? null,
          detail: assignment.detail ?? "",
        }
      : null,
    nextPlan: nextPlan
      ? {
          id: nextPlan.id,
          nextAction: nextPlan.next_action,
          priority: nextPlan.priority,
          plannedFor: nextPlan.planned_for ?? null,
          detail: nextPlan.detail ?? "",
        }
      : null,
    recentNotes: [...student.lesson_notes]
      .sort((a, b) => b.lesson_date.localeCompare(a.lesson_date))
      .slice(0, 3)
      .map((note) => ({
        id: note.id,
        lessonDate: note.lesson_date,
        coveredMaterial: note.covered_material,
        observations: note.observations,
        practiceAssigned: note.practice_assigned,
        nextStepHint: note.next_step_hint,
      })),
  };
}
