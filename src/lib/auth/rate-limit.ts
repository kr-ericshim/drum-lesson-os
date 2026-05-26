type HeaderReader = {
  get(name: string): string | null;
};

export type RateLimitOptions = {
  maxAttempts: number;
  windowMs: number;
};

export type RateLimitResult =
  | { allowed: true; remaining: number; resetAt: number }
  | { allowed: false; retryAfterSeconds: number; resetAt: number };

type RateLimitBucket = {
  attempts: number;
  resetAt: number;
};

const buckets = new Map<string, RateLimitBucket>();

function getClientIp(headers: HeaderReader) {
  const forwardedFor = headers.get("x-forwarded-for")?.split(",")[0]?.trim();

  return forwardedFor || headers.get("x-real-ip")?.trim() || "unknown";
}

function normalizeIdentifier(identifier: string) {
  return identifier.trim().toLowerCase() || "anonymous";
}

export function getAuthRateLimitKeys(scope: string, identifier: string, headers: HeaderReader) {
  return [
    `${scope}:ip:${getClientIp(headers)}`,
    `${scope}:id:${normalizeIdentifier(identifier)}`,
  ];
}

export function consumeRateLimit(
  key: string,
  options: RateLimitOptions,
  now = Date.now(),
): RateLimitResult {
  const existing = buckets.get(key);
  const current =
    existing && existing.resetAt > now
      ? existing
      : {
          attempts: 0,
          resetAt: now + options.windowMs,
        };

  if (current.attempts >= options.maxAttempts) {
    return {
      allowed: false,
      retryAfterSeconds: Math.ceil((current.resetAt - now) / 1000),
      resetAt: current.resetAt,
    };
  }

  current.attempts += 1;
  buckets.set(key, current);

  return {
    allowed: true,
    remaining: options.maxAttempts - current.attempts,
    resetAt: current.resetAt,
  };
}

export function clearRateLimit(key: string) {
  buckets.delete(key);
}

export function resetRateLimitsForTest() {
  buckets.clear();
}
