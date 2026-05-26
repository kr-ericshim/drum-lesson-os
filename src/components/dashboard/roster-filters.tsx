"use client";

import { Filter, RotateCcw } from "lucide-react";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { rosterFilterKeys, type RosterFilterKey, type RosterFilterState } from "@/lib/students/roster-filters";

type RosterFiltersProps = {
  filters: RosterFilterState;
  filteredCount: number;
  totalCount: number;
  onClear: () => void;
  onToggle: (key: RosterFilterKey) => void;
};

const filterLabels: Record<RosterFilterKey, string> = {
  highPriority: "High priority",
  missingFocus: "Missing focus",
  needsReview: "Needs review",
  noRecentNote: "No recent note",
};

export function RosterFilters({
  filters,
  filteredCount,
  totalCount,
  onClear,
  onToggle,
}: RosterFiltersProps) {
  const activeCount = rosterFilterKeys.filter((key) => filters[key]).length;

  return (
    <div className="rounded-lg border border-border bg-card p-3">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex min-w-0 items-center gap-2">
          <Filter className="h-4 w-4 shrink-0 text-primary" aria-hidden="true" />
          <p className="text-sm font-semibold leading-5">
            {filteredCount} of {totalCount} students
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          {rosterFilterKeys.map((key) => (
            <button
              aria-pressed={filters[key]}
              className={cn(
                "min-h-11 rounded-md border px-3 py-2 text-sm font-semibold leading-5 transition-colors focus-visible:outline-2 focus-visible:outline-ring",
                filters[key]
                  ? "border-primary/30 bg-primary/10 text-primary"
                  : "border-border bg-secondary text-muted-foreground hover:bg-muted",
              )}
              key={key}
              onClick={() => onToggle(key)}
              type="button"
            >
              {filterLabels[key]}
            </button>
          ))}

          {activeCount > 0 ? (
            <Button className="min-h-11 px-3 py-2" onClick={onClear} type="button" variant="ghost">
              <RotateCcw className="h-4 w-4" aria-hidden="true" />
              Clear
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
