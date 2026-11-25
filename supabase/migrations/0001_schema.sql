-- PromptKosha, migration 1: tables, indexes, triggers, helper functions.
-- Run this first in Supabase > SQL Editor. Safe to read top to bottom.

-- Fast "contains" search on titles. Kept in the `extensions` schema (Supabase's default place) so
-- the permission lockdown in migration 2 does not take its functions away from visitors.
create schema if not exists extensions;
create extension if not exists pg_trgm with schema extensions;

-- ---------------------------------------------------------------- profiles
-- One row per login (Supabase Auth keeps the password; we never store passwords).
create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text,
  role          text not null default 'user' check (role in ('user', 'admin')),
  is_active     boolean not null default true,
  last_login_at timestamptz,
  created_at    timestamptz not null default now()
);

-- Create a profile automatically whenever a login is created.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)));
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users for each row execute function public.handle_new_user();

-- True only for an active admin. Used by every security rule (policy).
create function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and is_active
  );
$$;

-- Generic "keep updated_at fresh" trigger.
create function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at := now(); return new; end $$;

-- ------------------------------------------------------------- categories
create table public.categories (
  id               bigint generated always as identity primary key,
  name             text not null check (length(name) between 1 and 100),
  slug             text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description      text,
  image            text,
  meta_title       text,
  meta_description text,
  sort_order       integer not null default 0,
  status           text not null default 'active' check (status in ('active', 'inactive')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index categories_status_sort_idx on public.categories (status, sort_order);
create trigger categories_updated before update on public.categories
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------ collections
create table public.collections (
  id               bigint generated always as identity primary key,
  name             text not null check (length(name) between 1 and 150),
  slug             text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description      text,
  cover_image      text,
  meta_title       text,
  meta_description text,
  is_featured      boolean not null default false,
  status           text not null default 'active' check (status in ('active', 'inactive')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index collections_status_idx on public.collections (status, is_featured);
create trigger collections_updated before update on public.collections
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------------ tags
create table public.tags (
  id         bigint generated always as identity primary key,
  name       text not null unique check (length(name) between 1 and 60),
  slug       text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  created_at timestamptz not null default now()
);

-- --------------------------------------------------------------- prompts
create table public.prompts (
  id                bigint generated always as identity primary key,
  title             text not null check (length(title) between 1 and 200),
  slug              text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  short_description text,
  prompt_text       text not null check (length(prompt_text) >= 1),
  prompt_text_hi    text,                       -- optional Hindi version
  preview_image     text,                       -- path inside Supabase Storage
  thumbnail_image   text,
  image_alt         text,
  -- RESTRICT: a category that still has prompts cannot be deleted (no broken links).
  category_id       bigint not null references public.categories(id) on delete restrict,
  prompt_type       text not null default 'image' check (prompt_type in ('image', 'video', 'text', 'design')),
  audience          text not null default 'unisex' check (audience in ('boys', 'girls', 'couple', 'unisex')),
  recommended_tools text[] not null default '{}',
  how_to_use        text,
  tips              text,
  suitable_for      text,
  additional_content text,
  is_featured       boolean not null default false,
  is_trending       boolean not null default false,
  is_pinned         boolean not null default false,
  is_template       boolean not null default false,
  status            text not null default 'draft' check (status in ('draft', 'published')),
  views             bigint not null default 0,
  copy_count        bigint not null default 0,
  seo_title         text,
  seo_description   text,
  published_at      timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  -- Full-text search column, maintained by Postgres itself. Title ranks highest.
  search_vector     tsvector generated always as (
    setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(short_description, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(prompt_text, '')), 'C')
  ) stored
);
create index prompts_list_idx       on public.prompts (status, published_at desc);
create index prompts_category_idx   on public.prompts (category_id, status);
create index prompts_flags_idx      on public.prompts (is_trending, is_template, is_pinned);
create index prompts_audience_idx   on public.prompts (audience);
create index prompts_popular_idx    on public.prompts (views desc);
create index prompts_copied_idx     on public.prompts (copy_count desc);
create index prompts_search_idx     on public.prompts using gin (search_vector);
create index prompts_title_trgm_idx on public.prompts using gin (title extensions.gin_trgm_ops);

-- Before saving a prompt: stamp published_at, and keep "updated" honest.
create function public.prompts_before_write() returns trigger
language plpgsql set search_path = '' as $$
declare ignore_cols text[] := array['views', 'copy_count', 'updated_at', 'search_vector'];
begin
  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;
  if tg_op = 'UPDATE' then
    -- A view/copy counter bump is not an edit, so it must not change updated_at.
    if (to_jsonb(new) - ignore_cols) = (to_jsonb(old) - ignore_cols) then
      new.updated_at := old.updated_at;
    else
      new.updated_at := now();
    end if;
  end if;
  return new;
end $$;
create trigger prompts_write before insert or update on public.prompts
  for each row execute function public.prompts_before_write();

-- -------------------------------------------------------- join tables
create table public.prompt_tags (
  prompt_id bigint not null references public.prompts(id) on delete cascade,
  tag_id    bigint not null references public.tags(id) on delete cascade,
  primary key (prompt_id, tag_id)
);
create index prompt_tags_tag_idx on public.prompt_tags (tag_id);

create table public.prompt_collections (
  prompt_id     bigint not null references public.prompts(id) on delete cascade,
  collection_id bigint not null references public.collections(id) on delete cascade,
  primary key (prompt_id, collection_id)
);
create index prompt_collections_col_idx on public.prompt_collections (collection_id);

-- ---------------------------------------------------------------- pages
create table public.pages (
  id              bigint generated always as identity primary key,
  title           text not null check (length(title) between 1 and 200),
  slug            text not null unique check (
    slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'
    -- These words are real routes, so a page may not use them (page "contact" IS allowed:
    -- its text is shown above the contact form).
    and slug not in ('admin','api','prompts','prompt','category','categories','collection',
                     'collections','templates','search','login','status','sitemap','robots','auth')
  ),
  content         text not null default '',
  seo_title       text,
  seo_description text,
  status          text not null default 'draft' check (status in ('draft', 'published')),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create trigger pages_updated before update on public.pages
  for each row execute function public.set_updated_at();

-- -------------------------------------------------------- site_settings
-- Key/value store. is_public = false hides a row from visitors (none yet, future-proofing).
create table public.site_settings (
  id            bigint generated always as identity primary key,
  setting_key   text not null unique,
  setting_value text,
  is_public     boolean not null default true,
  updated_at    timestamptz not null default now()
);
create trigger site_settings_updated before update on public.site_settings
  for each row execute function public.set_updated_at();

-- ------------------------------------------- newsletter and contact form
create table public.newsletter_subscribers (
  id         bigint generated always as identity primary key,
  email      text not null check (length(email) <= 254 and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  status     text not null default 'subscribed' check (status in ('subscribed', 'unsubscribed')),
  created_at timestamptz not null default now()
);
create unique index newsletter_email_unique on public.newsletter_subscribers (lower(email));

create table public.contact_messages (
  id         bigint generated always as identity primary key,
  name       text not null check (length(name) between 1 and 100),
  email      text not null check (length(email) <= 254 and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  subject    text not null check (length(subject) between 1 and 200),
  message    text not null check (length(message) between 1 and 5000),
  status     text not null default 'new' check (status in ('new', 'read')),
  created_at timestamptz not null default now()
);
create index contact_messages_created_idx on public.contact_messages (created_at desc);

-- Flood guard: public forms accept at most N rows per 10 minutes IN TOTAL. Admins are exempt.
-- (A per-visitor limit is added in the form's Server Action in Phase 8.)
create function public.limit_public_inserts() returns trigger
language plpgsql security definer set search_path = '' as $$
declare recent integer;
begin
  if public.is_admin() then return new; end if;
  execute format('select count(*) from %I.%I where created_at > now() - interval ''10 minutes''',
                 tg_table_schema, tg_table_name) into recent;
  if recent >= tg_argv[0]::integer then
    raise exception 'Too many submissions right now. Please try again later.';
  end if;
  return new;
end $$;
create trigger newsletter_flood before insert on public.newsletter_subscribers
  for each row execute function public.limit_public_inserts(60);
create trigger contact_flood before insert on public.contact_messages
  for each row execute function public.limit_public_inserts(30);

-- ------------------------------------------------------------ counters
-- Visitors cannot update the prompts table, so counting goes through these two functions.
create function public.increment_view(p_prompt_id bigint) returns void
language sql security definer set search_path = '' as $$
  update public.prompts set views = views + 1
  where id = p_prompt_id and status = 'published' and published_at <= now();
$$;

create function public.increment_copy(p_prompt_id bigint) returns void
language sql security definer set search_path = '' as $$
  update public.prompts set copy_count = copy_count + 1
  where id = p_prompt_id and status = 'published' and published_at <= now();
$$;
