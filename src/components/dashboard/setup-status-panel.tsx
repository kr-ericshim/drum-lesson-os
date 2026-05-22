import { CheckCircle2, Settings2 } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { SupabaseSetupStatus } from "@/lib/env";

type SetupStatusPanelProps = {
  status: SupabaseSetupStatus;
};

export function SetupStatusPanel({ status }: SetupStatusPanelProps) {
  const isConfigured = status.state === "configured";

  return (
    <Card>
      <CardHeader className="space-y-3">
        <div className="flex items-center justify-between gap-3">
          <CardTitle>Data foundation</CardTitle>
          <Badge variant={isConfigured ? "steady" : "attention"}>
            {status.label}
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-3 text-sm leading-6 text-muted-foreground">
          {isConfigured ? (
            <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-accent" aria-hidden="true" />
          ) : (
            <Settings2 className="mt-0.5 h-4 w-4 shrink-0 text-primary" aria-hidden="true" />
          )}
          <p>
            {isConfigured
              ? "Supabase environment variables are present. The dashboard can load instructor-owned lesson data."
              : "Add the Supabase URL and anon key, then apply the migration and seed data."}
          </p>
        </div>

        {status.state === "missing" && status.missing.length > 0 ? (
          <div className="rounded-md border border-border bg-secondary p-3 text-sm text-muted-foreground">
            Missing: {status.missing.join(", ")}
          </div>
        ) : null}

        <Button variant={isConfigured ? "secondary" : "default"} className="w-full">
          Review setup
        </Button>
      </CardContent>
    </Card>
  );
}
