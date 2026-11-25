# PromptKosha

AI prompt gallery built with Next.js (App Router, JavaScript), Tailwind CSS v4, Supabase and Netlify.

## Run locally
1. Install Node.js 20.9 or newer (22 recommended).
2. `npm install`
3. Copy `.env.example` to `.env.local` and fill in your Supabase values (Supabase dashboard > Project Settings > API).
4. `npm run dev`, then open http://localhost:3000 and http://localhost:3000/status/

## Folder guide
- `app/`: pages (each folder is a URL). `app/status/` is a temporary setup check.
- `components/`: reusable UI pieces (empty until Phase 5)
- `lib/supabase/`: the three Supabase connections (browser, server, session refresh)
- `lib/queries/`: every database READ will live here (Phase 5+)
- `lib/actions/`: every database WRITE (Server Actions) will live here (Phase 7+)
- `supabase/`: database SQL, demo data and security tests. Read `supabase/README.md` (Phase 3)
- `proxy.js`: runs before each request; keeps the login session fresh

## Security rules
- Never commit `.env.local`.
- Never put the Supabase `service_role` / secret key in any `NEXT_PUBLIC_` variable.

## Deploy (Netlify)
1. Push this folder to a GitHub repository.
2. Netlify > Add new site > Import from Git > pick the repo. Build settings come from `netlify.toml`.
3. Site configuration > Environment variables: add the three variables from `.env.example`
   (set `NEXT_PUBLIC_SITE_URL` to your Netlify address).
4. Deploy. Open `/status/` on the live site to check the setup.
