// Temporary Phase 2 home page. Replaced in Phase 5.
import Link from "next/link";

export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-2xl flex-col justify-center px-6">
      <h1 className="text-4xl font-semibold tracking-tight">PromptKosha</h1>
      <p className="mt-3 text-muted">
        Project setup is working. The prompt gallery arrives in later phases.
      </p>
      <Link
        href="/status/"
        className="mt-6 w-fit rounded-xl bg-accent px-5 py-2.5 text-sm font-medium text-white transition hover:opacity-90"
      >
        Check setup status
      </Link>
    </main>
  );
}
