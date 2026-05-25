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
  primary_weak_point: string;
  progress_items: ProgressItemSourceRow[];
  assignments: AssignmentContextRow[];
  next_lesson_plans: NextPlanContextRow[];
};

export type ProgressFocusSummary = {
  id: string;
  category: string;
  status: string;
  title: string;
  observedOn: string;
  detail: string;
};

export type StudentNextPlan = {
  id: string;
  nextAction: string;
  priority: string;
  plannedFor: string | null;
  detail: string;
};

export type StudentRosterItem = {
  id: string;
  name: string;
  profileCue: string;
  currentFocus: ProgressFocusSummary | null;
  weakPoint: string;
  assignmentStatus: string;
  nextAction: string;
  nextPlan: StudentNextPlan | null;
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

export type StudentLessonNote = {
  id: string;
  lessonDate: string;
  coveredMaterial: string;
  observations: string;
  practiceAssigned: string;
  nextStepHint: string;
};

export type LessonBrief = {
  profileCue: string;
  currentFocus: ProgressFocusSummary | null;
  weakPoint: string;
  nextAction: string;
  assignmentReviewCue: string;
  latestObservation: string;
  firstCheck: string;
};

export type StudentDetail = StudentRosterItem & {
  progressItems: StudentProgressItem[];
  traits: StudentTrait[];
  assignment: StudentAssignment | null;
  nextPlan: StudentNextPlan | null;
  recentNotes: StudentLessonNote[];
  lessonBrief: LessonBrief;
};

export type LessonQueueItem = {
  studentId: string;
  studentName: string;
  currentFocus: ProgressFocusSummary | null;
  assignmentStatus: string;
  nextAction: string;
  priority: string;
  plannedFor: string;
  dateState: "overdue" | "today" | "upcoming";
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

export function pickCurrentFocusProgressItem(
  progressItems: ProgressItemSourceRow[],
): ProgressFocusSummary | null {
  const focusItem = [...progressItems]
    .filter((item) => item.current_focus)
    .sort(
      (a, b) =>
        b.observed_on.localeCompare(a.observed_on) ||
        a.title.localeCompare(b.title) ||
        a.id.localeCompare(b.id),
    )[0];

  return focusItem ? mapProgressFocusSummary(focusItem) : null;
}

function mapProgressFocusSummary(item: ProgressItemSourceRow): ProgressFocusSummary {
  return {
    id: item.id,
    category: item.category,
    status: item.status,
    title: item.title,
    observedOn: item.observed_on,
    detail: item.detail,
  };
}

function mapNextPlan(nextPlan: NextPlanContextRow | undefined): StudentNextPlan | null {
  return nextPlan
    ? {
        id: nextPlan.id,
        nextAction: nextPlan.next_action,
        priority: nextPlan.priority,
        plannedFor: nextPlan.planned_for ?? null,
        detail: nextPlan.detail ?? "",
      }
    : null;
}

export function mapStudentRoster(students: StudentRosterSourceRow[]): StudentRosterItem[] {
  return students.map((student) => {
    const assignment = pickLatestAssignment(student.assignments);
    const nextPlan = pickPriorityNextPlan(student.next_lesson_plans);
    const mappedNextPlan = mapNextPlan(nextPlan);

    return {
      id: student.id,
      name: student.name,
      profileCue: student.profile_cue,
      currentFocus: pickCurrentFocusProgressItem(student.progress_items),
      weakPoint: student.primary_weak_point,
      assignmentStatus: assignment?.status ?? "not_started",
      nextAction: mappedNextPlan?.nextAction ?? "Set next lesson action",
      nextPlan: mappedNextPlan,
    };
  });
}

export function mapStudentDetail(student: StudentDetailSourceRow): StudentDetail {
  const [rosterItem] = mapStudentRoster([student]);
  const assignment = pickLatestAssignment(student.assignments);
  const nextPlan = pickPriorityNextPlan(student.next_lesson_plans);
  const progressItems = [...student.progress_items]
    .sort((a, b) => b.observed_on.localeCompare(a.observed_on))
    .map((item) => ({
      id: item.id,
      category: item.category,
      status: item.status,
      title: item.title,
      currentFocus: item.current_focus,
      observedOn: item.observed_on,
      detail: item.detail,
    }));
  const recentNotes = [...student.lesson_notes]
    .sort((a, b) => b.lesson_date.localeCompare(a.lesson_date))
    .slice(0, 3)
    .map((note) => ({
      id: note.id,
      lessonDate: note.lesson_date,
      coveredMaterial: note.covered_material,
      observations: note.observations,
      practiceAssigned: note.practice_assigned,
      nextStepHint: note.next_step_hint,
    }));
  const mappedAssignment = assignment
    ? {
        status: assignment.status,
        title: assignment.title ?? "Current assignment",
        dueDate: assignment.due_date ?? null,
        detail: assignment.detail ?? "",
      }
    : null;
  const mappedNextPlan = mapNextPlan(nextPlan);

  return {
    ...rosterItem,
    progressItems,
    traits: [...student.student_traits]
      .sort((a, b) => a.trait_type.localeCompare(b.trait_type) || a.label.localeCompare(b.label))
      .map((trait) => ({
        id: trait.id,
        type: trait.trait_type,
        label: trait.label,
        detail: trait.detail,
      })),
    assignment: mappedAssignment,
    nextPlan: mappedNextPlan,
    recentNotes,
    lessonBrief: buildLessonBrief({
      profileCue: rosterItem.profileCue,
      currentFocus: rosterItem.currentFocus,
      weakPoint: rosterItem.weakPoint,
      assignment: mappedAssignment,
      nextAction: rosterItem.nextAction,
      nextPlan: mappedNextPlan,
      recentNotes,
    }),
  };
}

export function buildLessonBrief({
  profileCue,
  currentFocus,
  weakPoint,
  assignment,
  nextAction,
  nextPlan,
  recentNotes,
}: {
  profileCue: string;
  currentFocus: ProgressFocusSummary | null;
  weakPoint: string;
  assignment: StudentAssignment | null;
  nextAction: string;
  nextPlan: StudentNextPlan | null;
  recentNotes: StudentLessonNote[];
}): LessonBrief {
  const latestNote = recentNotes[0];

  return {
    profileCue,
    currentFocus,
    weakPoint,
    nextAction,
    assignmentReviewCue: buildAssignmentReviewCue(assignment),
    latestObservation: latestNote?.observations ?? "No recent observation recorded.",
    firstCheck: nextPlan?.nextAction ?? latestNote?.nextStepHint ?? currentFocus?.title ?? "Set next lesson action",
  };
}

function buildAssignmentReviewCue(assignment: StudentAssignment | null) {
  if (!assignment) {
    return "No assignment recorded yet.";
  }

  if (assignment.status === "needs_review") {
    return `${assignment.title} needs review.`;
  }

  if (assignment.status === "complete") {
    return `${assignment.title} is complete.`;
  }

  if (assignment.status === "paused") {
    return `${assignment.title} is paused.`;
  }

  if (assignment.status === "not_started") {
    return `${assignment.title} has not started.`;
  }

  return `${assignment.title} is in progress.`;
}

export function mapLessonQueue(
  students: StudentRosterItem[],
  todayDate: string,
): LessonQueueItem[] {
  return students
    .filter((student) => student.nextPlan?.plannedFor)
    .map((student) => {
      const plannedFor = student.nextPlan?.plannedFor ?? "";

      return {
        studentId: student.id,
        studentName: student.name,
        currentFocus: student.currentFocus,
        assignmentStatus: student.assignmentStatus,
        nextAction: student.nextAction,
        priority: student.nextPlan?.priority ?? "normal",
        plannedFor,
        dateState: getDateState(plannedFor, todayDate),
      };
    })
    .sort(
      (a, b) =>
        a.plannedFor.localeCompare(b.plannedFor) ||
        (priorityRank[a.priority] ?? priorityRank.normal) -
          (priorityRank[b.priority] ?? priorityRank.normal) ||
        a.studentName.localeCompare(b.studentName),
    );
}

function getDateState(plannedFor: string, todayDate: string): LessonQueueItem["dateState"] {
  if (plannedFor < todayDate) {
    return "overdue";
  }

  if (plannedFor === todayDate) {
    return "today";
  }

  return "upcoming";
}
