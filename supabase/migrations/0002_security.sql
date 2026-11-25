-- PromptKosha, migration 2: Row Level Security (RLS), permissions, storage buckets.
-- RLS is the REAL security layer: even if someone bypasses the website, the database says no.

-- 1) Permissions. Start from nothing, then grant only what each role needs.
revoke all on all tables    in schema public from anon, authenticated;
revoke all on all functions in schema public from public;
grant usage on schema public to anon, authenticated;

-- Visitors (anon) and logged-in users can READ public content (RLS filters the rows).
grant select on public.categories, public.collections, public.tags, public.prompts,
                public.prompt_tags, public.prompt_collections, public.pages,
                public.site_settings to anon, authenticated;
-- Visitors can only SEND forms (insert), never read them back.
grant insert on public.newsletter_subscribers, public.contact_messages to anon, authenticated;
-- Writes: granted to "authenticated" but RLS below lets only admins through.
grant insert, update, delete on public.categories, public.collections, public.tags,
      public.prompts, public.prompt_tags, public.prompt_collections, public.pages,
      public.site_settings to authenticated;
grant select, update, delete on public.newsletter_subscribers, public.contact_messages to authenticated;
-- Profiles: read own row; update ONLY these two columns, so nobody can change their own role.
grant select on public.profiles to authenticated;
grant update (display_name, last_login_at) on public.profiles to authenticated;

grant execute on function public.is_admin()        to anon, authenticated;
grant execute on function public.increment_view(bigint) to anon, authenticated;
grant execute on function public.increment_copy(bigint) to anon, authenticated;

-- 2) Turn RLS on for every table.
alter table public.profiles               enable row level security;
alter table public.categories             enable row level security;
alter table public.collections            enable row level security;
alter table public.tags                   enable row level security;
alter table public.prompts                enable row level security;
alter table public.prompt_tags            enable row level security;
alter table public.prompt_collections     enable row level security;
alter table public.pages                  enable row level security;
alter table public.site_settings          enable row level security;
alter table public.newsletter_subscribers enable row level security;
alter table public.contact_messages       enable row level security;

-- 3) Policies. "(select public.is_admin())" is written that way so Postgres evaluates it once.
create policy profiles_read   on public.profiles for select to authenticated
  using (id = auth.uid() or (select public.is_admin()));
create policy profiles_update on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy categories_read  on public.categories for select
  using (status = 'active' or (select public.is_admin()));
create policy categories_write on public.categories for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

create policy collections_read  on public.collections for select
  using (status = 'active' or (select public.is_admin()));
create policy collections_write on public.collections for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

create policy tags_read  on public.tags for select using (true);
create policy tags_write on public.tags for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- Visitors see a prompt only when it is published AND its publication date has arrived.
create policy prompts_read  on public.prompts for select
  using ((status = 'published' and published_at <= now()) or (select public.is_admin()));
create policy prompts_write on public.prompts for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- Join rows are visible only when their prompt is (so draft prompts do not leak).
create policy prompt_tags_read on public.prompt_tags for select
  using ((select public.is_admin()) or exists (
    select 1 from public.prompts p
    where p.id = prompt_id and p.status = 'published' and p.published_at <= now()));
create policy prompt_tags_write on public.prompt_tags for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

create policy prompt_collections_read on public.prompt_collections for select
  using ((select public.is_admin()) or exists (
    select 1 from public.prompts p
    where p.id = prompt_id and p.status = 'published' and p.published_at <= now()));
create policy prompt_collections_write on public.prompt_collections for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

create policy pages_read  on public.pages for select
  using (status = 'published' or (select public.is_admin()));
create policy pages_write on public.pages for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

create policy settings_read  on public.site_settings for select
  using (is_public or (select public.is_admin()));
create policy settings_write on public.site_settings for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

-- Forms: anyone may submit (with safe values only); only admins may read or manage.
create policy newsletter_submit on public.newsletter_subscribers for insert
  with check (status = 'subscribed');
create policy newsletter_admin_read   on public.newsletter_subscribers for select to authenticated
  using ((select public.is_admin()));
create policy newsletter_admin_update on public.newsletter_subscribers for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy newsletter_admin_delete on public.newsletter_subscribers for delete to authenticated
  using ((select public.is_admin()));

create policy contact_submit on public.contact_messages for insert
  with check (status = 'new');
create policy contact_admin_read   on public.contact_messages for select to authenticated
  using ((select public.is_admin()));
create policy contact_admin_update on public.contact_messages for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy contact_admin_delete on public.contact_messages for delete to authenticated
  using ((select public.is_admin()));

-- 4) Storage: three public-read image buckets (5 MB, images only). Only admins may change files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('prompts',     'prompts',     true, 5242880, array['image/jpeg','image/png','image/webp','image/gif']),
  ('categories',  'categories',  true, 5242880, array['image/jpeg','image/png','image/webp','image/gif']),
  ('collections', 'collections', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update
  set public = excluded.public, file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- No public "list files" policy: images load by their URL, but visitors cannot browse the bucket.
create policy "admin reads images"   on storage.objects for select to authenticated
  using (bucket_id in ('prompts','categories','collections') and (select public.is_admin()));
create policy "admin uploads images" on storage.objects for insert to authenticated
  with check (bucket_id in ('prompts','categories','collections') and (select public.is_admin()));
create policy "admin updates images" on storage.objects for update to authenticated
  using (bucket_id in ('prompts','categories','collections') and (select public.is_admin()));
create policy "admin deletes images" on storage.objects for delete to authenticated
  using (bucket_id in ('prompts','categories','collections') and (select public.is_admin()));
