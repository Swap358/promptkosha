# Database setup (Supabase)

## 1. Create the database (once)
Supabase dashboard > **SQL Editor** > New query. Paste each file, press **Run**, in THIS order:
1. `migrations/0001_schema.sql`  (tables, indexes, triggers)
2. `migrations/0002_security.sql` (security rules, permissions, image buckets)
3. `seed.sql` (optional demo content: 5 categories, 3 collections, 10 prompts, 6 pages, settings)

Run each file only once. If you must start over, use a NEW empty Supabase project.

## 2. Close public sign-ups
Authentication > Sign In / Providers (or Settings) > turn OFF "Allow new users to sign up".
Only people you add by hand can then log in.

## 3. Create your admin (no default password exists)
1. Authentication > Users > **Add user** > enter your email and a strong password, tick "Auto Confirm User".
2. SQL Editor, run this with YOUR email:
```sql
update public.profiles set role = 'admin'
where id = (select id from auth.users where email = 'you@example.com');
```
Only this SQL can create or remove an admin. The website cannot change roles.

## 4. Tests
`tests/01_rls_tests.sql` checks who can read and write what (63 checks, rolled back afterwards).
`tests/00_local_supabase_stub.sql` is ONLY for a plain local Postgres. Never run it on Supabase.
