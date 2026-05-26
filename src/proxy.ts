import { createServerClient } from "@supabase/ssr";
import { type NextRequest, NextResponse } from "next/server";

import {
  getLoginRedirectUrl,
  getPostLoginRedirectPath,
  getUnlinkedLoginRedirectUrl,
  isProtectedAppPath,
} from "@/lib/auth/protected-routes";
import { getSupabaseSetupStatus } from "@/lib/env";
import type { Database } from "@/types/database";

export async function proxy(request: NextRequest) {
  const status = getSupabaseSetupStatus();

  if (status.state !== "configured") {
    return NextResponse.next();
  }

  let response = NextResponse.next({
    request,
  });

  const supabase = createServerClient<Database>(
    status.env.NEXT_PUBLIC_SUPABASE_URL,
    status.env.NEXT_PUBLIC_SUPABASE_KEY,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) => {
            response.cookies.set(name, value, options);
          });
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();
  const isProtectedPath = isProtectedAppPath(request.nextUrl.pathname);

  if (!user && isProtectedPath) {
    return NextResponse.redirect(getLoginRedirectUrl(request.nextUrl));
  }

  const { data: instructor } = user
    ? await supabase
        .from("instructors")
        .select("id")
        .eq("auth_user_id", user.id)
        .maybeSingle()
    : { data: null };

  if (user && !instructor && isProtectedPath) {
    return NextResponse.redirect(getUnlinkedLoginRedirectUrl(request.nextUrl));
  }

  if (user && instructor && request.nextUrl.pathname === "/login") {
    return NextResponse.redirect(
      new URL(getPostLoginRedirectPath(request.nextUrl.searchParams.get("next")), request.url),
    );
  }

  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"],
};
