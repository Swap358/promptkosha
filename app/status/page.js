// Setup check page (Phase 2 only). DELETE this folder before launch (tracked in Phase 10).
// It reports whether env vars exist and whether Supabase answers. It never prints secret values.
export const dynamic = "force-dynamic"; // always run fresh, never cache
export const metadata = { title: "Setup status", robots: { index: false, follow: false } };

async function checkSupabase() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return { ok: false, text: "Not configured: add the variables to .env.local" };

  try {
    // The Supabase Auth health endpoint needs no tables, so it works before Phase 3.
    const res = await fetch(`${url}/auth/v1/health`, {
      headers: { apikey: key },
      cache: "no-store",
      signal: AbortSignal.timeout(5000),
    });
    return res.ok
      ? { ok: true, text: "Supabase reachable" }
      : { ok: false, text: `Supabase answered with HTTP ${res.status} (check the key)` };
  } catch {
    return { ok: false, text: "Could not reach Supabase (check the URL and your network)" };
  }
}

export default async function StatusPage() {
  const supabase = await checkSupabase();
  const rows = [
    { label: "NEXT_PUBLIC_SUPABASE_URL", ok: !!process.env.NEXT_PUBLIC_SUPABASE_URL, text: process.env.NEXT_PUBLIC_SUPABASE_URL ? "Set" : "Missing" },
    { label: "NEXT_PUBLIC_SUPABASE_ANON_KEY", ok: !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY, text: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ? "Set" : "Missing" },
    { label: "NEXT_PUBLIC_SITE_URL", ok: !!process.env.NEXT_PUBLIC_SITE_URL, text: process.env.NEXT_PUBLIC_SITE_URL ? "Set" : "Missing (defaults to localhost)" },
    { label: "Supabase connection", ok: supabase.ok, text: supabase.text },
  ];

  return (
    <main className="mx-auto max-w-2xl px-6 py-16">
      <h1 className="text-2xl font-semibold">Setup status</h1>
      <ul className="mt-6 divide-y divide-line rounded-card border border-line bg-surface">
        {rows.map((row) => (
          <li key={row.label} className="flex items-center justify-between gap-4 px-4 py-3 text-sm">
            <span className="font-mono">{row.label}</span>
            <span className={row.ok ? "text-green-700" : "text-red-700"}>
              {row.ok ? "OK: " : "Problem: "}
              {row.text}
            </span>
          </li>
        ))}
      </ul>
    </main>
  );
}
