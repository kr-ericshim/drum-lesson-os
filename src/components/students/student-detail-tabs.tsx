import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { StudentNotesList } from "@/components/students/student-notes-list";
import { StudentProgressList } from "@/components/students/student-progress-list";
import { StudentSummaryPanel } from "@/components/students/student-summary-panel";
import type { StudentDetail } from "@/lib/supabase/queries";

type StudentDetailTabsProps = {
  student: StudentDetail;
};

export function StudentDetailTabs({ student }: StudentDetailTabsProps) {
  return (
    <Tabs defaultValue="summary" className="space-y-4">
      <TabsList aria-label="Student detail sections" className="w-full justify-start overflow-x-auto">
        <TabsTrigger value="summary">Summary</TabsTrigger>
        <TabsTrigger value="progress">Progress</TabsTrigger>
        <TabsTrigger value="notes">Notes</TabsTrigger>
      </TabsList>

      <TabsContent value="summary">
        <StudentSummaryPanel student={student} />
      </TabsContent>
      <TabsContent value="progress">
        <StudentProgressList progressItems={student.progressItems} studentId={student.id} />
      </TabsContent>
      <TabsContent value="notes">
        <StudentNotesList notes={student.recentNotes} studentId={student.id} />
      </TabsContent>
    </Tabs>
  );
}
