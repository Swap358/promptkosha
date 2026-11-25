// Runs before every matching request. Phase 2: only keeps the session fresh.
// Phase 4 adds the /admin redirect for anonymous visitors.
import { refreshSession } from "@/lib/supabase/session";

export async function proxy(request) {
  // Skip if Supabase isn't configured yet (e.g. first local run before .env.local exists).
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    return;
  }
  const { response } = await refreshSession(request);
  return response;
}

export const config = {
  // Everything except static files and images.
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)"],
};
