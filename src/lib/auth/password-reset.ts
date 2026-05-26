import { z } from "zod";

type HeaderReader = {
  get(name: string): string | null;
};

const fallbackPasswordResetOrigin = "http://localhost:3000";
const safeHostPattern = /^[a-z0-9.-]+(?::\d{1,5})?$/i;

export const passwordRecoveryRequestSchema = z.object({
  email: z.string().trim().email().max(254),
});

export const passwordResetInputSchema = z
  .object({
    password: z.string().trim().min(8).max(72),
    confirmPassword: z.string().trim().min(8).max(72),
  })
  .refine((input) => input.password === input.confirmPassword, {
    message: "Passwords must match.",
    path: ["confirmPassword"],
  });

function isLocalHost(host: string) {
  const hostname = host.split(":")[0];

  return hostname === "localhost" || hostname === "127.0.0.1";
}

function normalizeOrigin(origin: string | undefined) {
  if (!origin) {
    return null;
  }

  try {
    const parsed = new URL(origin);

    if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
      return null;
    }

    return parsed.origin;
  } catch {
    return null;
  }
}

function getForwardedHost(headers: HeaderReader) {
  return (headers.get("x-forwarded-host") ?? headers.get("host"))?.split(",")[0]?.trim() ?? null;
}

function getForwardedProtocol(headers: HeaderReader, host: string) {
  const protocol = headers.get("x-forwarded-proto")?.split(",")[0]?.trim().toLowerCase();

  if (protocol === "https") {
    return "https";
  }

  if (protocol === "http" && isLocalHost(host)) {
    return "http";
  }

  return isLocalHost(host) ? "http" : "https";
}

export function getPasswordRecoveryRedirectTo(
  headers: HeaderReader,
  appOrigin = process.env.NEXT_PUBLIC_APP_ORIGIN,
  nodeEnv = process.env.NODE_ENV,
) {
  const configuredOrigin = normalizeOrigin(appOrigin);

  if (configuredOrigin) {
    return `${configuredOrigin}/reset-password`;
  }

  if (nodeEnv === "production") {
    throw new Error("NEXT_PUBLIC_APP_ORIGIN is required for password recovery redirects.");
  }

  const host = getForwardedHost(headers);

  if (!host || !safeHostPattern.test(host)) {
    return `${fallbackPasswordResetOrigin}/reset-password`;
  }

  return `${getForwardedProtocol(headers, host)}://${host}/reset-password`;
}
