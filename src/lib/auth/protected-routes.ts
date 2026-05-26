const PUBLIC_FILE_PATTERN = /\.(?:ico|png|jpg|jpeg|svg|webp|gif|txt|xml|json|css|js|map)$/i;

export function isProtectedAppPath(pathname: string) {
  if (pathname === "/login") {
    return false;
  }

  if (
    pathname.startsWith("/_next/") ||
    pathname.startsWith("/api/") ||
    PUBLIC_FILE_PATTERN.test(pathname)
  ) {
    return false;
  }

  return pathname === "/" || pathname.startsWith("/students");
}

export function getLoginRedirectUrl(url: URL) {
  const loginUrl = new URL("/login", url.origin);
  const nextPath = `${url.pathname}${url.search}`;

  if (isProtectedAppPath(url.pathname)) {
    loginUrl.searchParams.set("next", nextPath);
  }

  return loginUrl.toString();
}

export function getUnlinkedLoginRedirectUrl(url: URL) {
  const loginUrl = new URL(getLoginRedirectUrl(url));

  loginUrl.searchParams.set("error", "unlinked");

  return loginUrl.toString();
}

export function getPostLoginRedirectPath(nextPath: FormDataEntryValue | null | undefined) {
  if (typeof nextPath !== "string" || !nextPath.startsWith("/")) {
    return "/";
  }

  if (nextPath.startsWith("//")) {
    return "/";
  }

  const [pathname = "/"] = nextPath.split("?");

  return isProtectedAppPath(pathname) ? nextPath : "/";
}
