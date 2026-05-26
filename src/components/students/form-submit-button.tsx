"use client";

import { useFormStatus } from "react-dom";

import { Button } from "@/components/ui/button";
import type { ButtonProps } from "@/components/ui/button";

type FormSubmitButtonProps = {
  label: string;
  pendingLabel: string;
  variant?: ButtonProps["variant"];
};

export function FormSubmitButton({ label, pendingLabel, variant }: FormSubmitButtonProps) {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" disabled={pending} variant={variant}>
      {pending ? pendingLabel : label}
    </Button>
  );
}
