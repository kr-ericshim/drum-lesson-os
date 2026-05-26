"use client";

import { useMemo, useState } from "react";

import { RosterFilters } from "@/components/dashboard/roster-filters";
import { StudentSummaryRow } from "@/components/dashboard/student-summary-row";
import { Button } from "@/components/ui/button";
import {
  createEmptyRosterFilters,
  matchesRosterFilters,
  type RosterFilterKey,
} from "@/lib/students/roster-filters";
import type { StudentRosterItem } from "@/lib/supabase/queries";

type FilterableStudentRosterProps = {
  students: StudentRosterItem[];
};

export function FilterableStudentRoster({ students }: FilterableStudentRosterProps) {
  const [filters, setFilters] = useState(createEmptyRosterFilters);
  const filteredStudents = useMemo(
    () => students.filter((student) => matchesRosterFilters(student, filters)),
    [filters, students],
  );

  function toggleFilter(key: RosterFilterKey) {
    setFilters((current) => ({ ...current, [key]: !current[key] }));
  }

  function clearFilters() {
    setFilters(createEmptyRosterFilters());
  }

  return (
    <div className="space-y-3">
      <RosterFilters
        filteredCount={filteredStudents.length}
        filters={filters}
        onClear={clearFilters}
        onToggle={toggleFilter}
        totalCount={students.length}
      />

      {filteredStudents.length > 0 ? (
        <div className="space-y-3">
          {filteredStudents.map((student) => (
            <StudentSummaryRow key={student.id} student={student} />
          ))}
        </div>
      ) : (
        <div className="rounded-lg border border-border bg-card p-5">
          <h3 className="text-[18px] font-semibold leading-tight text-pretty">
            No students match these filters
          </h3>
          <p className="mt-2 text-sm leading-6 text-muted-foreground text-pretty">
            Clear filters to return to the full active roster.
          </p>
          <Button className="mt-4" onClick={clearFilters} type="button" variant="secondary">
            Clear filters
          </Button>
        </div>
      )}
    </div>
  );
}
