-- PromptKosha security tests. Run AFTER migrations + seed. Everything is rolled back at the end,
-- so it changes nothing. Works on Supabase SQL Editor too (skip 00_local_supabase_stub.sql there).
-- Look at the last result table: every row should say PASS.
begin;

create table test_results (label text, ok boolean, detail text);
create table scratch (k text, v bigint);
grant all on test_results, scratch to public;

create function t(p_label text, p_ok boolean) returns void language sql as
  $$ insert into test_results values (p_label, coalesce(p_ok, false), null) $$;
-- passes if the statement raises an error (permission denied, policy violation, constraint...)
create function expect_error(p_label text, q text) returns void language plpgsql as $$
begin execute q; insert into test_results values (p_label, false, 'statement succeeded but should have failed');
exception when others then insert into test_results values (p_label, true, sqlerrm); end $$;
-- passes if the statement succeeds
create function expect_ok(p_label text, q text) returns void language plpgsql as $$
begin execute q; insert into test_results values (p_label, true, null);
exception when others then insert into test_results values (p_label, false, sqlerrm); end $$;
-- passes if the statement errors OR changes zero rows (RLS silently hides rows from updates/deletes)
create function expect_blocked(p_label text, q text) returns void language plpgsql as $$
declare n integer;
begin execute q; get diagnostics n = row_count; insert into test_results values (p_label, n = 0, 'rows changed: ' || n);
exception when others then insert into test_results values (p_label, true, sqlerrm); end $$;
grant execute on function t, expect_error, expect_ok, expect_blocked to public;

-- ============================ fixtures (as the database owner) ============================
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'admin@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'user@example.com');
select t('profile is created automatically with role user',
  (select role from profiles where id = '22222222-2222-2222-2222-222222222222') = 'user');
update profiles set role = 'admin' where id = '11111111-1111-1111-1111-111111111111';

insert into categories (name, slug, status) values ('Hidden Cat', 'hidden-cat', 'inactive');
insert into prompts (title, slug, prompt_text, category_id, status)
  values ('Draft Secret', 'draft-secret', 'secret', (select id from categories where slug='portrait'), 'draft');
insert into prompts (title, slug, prompt_text, category_id, status, published_at)
  values ('Future Prompt', 'future-prompt', 'later', (select id from categories where slug='portrait'), 'published', now() + interval '1 day');
insert into prompts (title, slug, prompt_text, category_id, status)
  values ('Auto Published', 'auto-published', 'x', (select id from categories where slug='portrait'), 'published');
insert into prompt_tags select (select id from prompts where slug='draft-secret'), id from tags where slug='portrait';
insert into site_settings (setting_key, setting_value, is_public) values ('secret_note', 'private', false);
insert into contact_messages (name, email, subject, message) values ('Seed', 'seed@example.com', 'Hi', 'Hello');
insert into newsletter_subscribers (email) values ('seed@example.com');
insert into scratch select 'draft_id', id from prompts where slug = 'draft-secret';

select t('publishing without a date stamps published_at',
  (select published_at is not null from prompts where slug = 'auto-published'));
select t('full-text search finds a title word',
  (select count(*) from prompts where search_vector @@ plainto_tsquery('simple', 'neon')) >= 1);
select t('partial title search works (ILIKE)',
  (select count(*) from prompts where title ilike '%watercolor%') = 1);

-- updated_at must change on a real edit but NOT on a counter bump
alter table prompts disable trigger prompts_write;
update prompts set updated_at = '2020-01-01' where slug = 'golden-hour-portrait-prompt';
alter table prompts enable trigger prompts_write;
select increment_copy(id) from prompts where slug = 'golden-hour-portrait-prompt';
select t('counter bump keeps updated_at',
  (select updated_at = '2020-01-01' from prompts where slug = 'golden-hour-portrait-prompt'));
update prompts set short_description = 'edited' where slug = 'golden-hour-portrait-prompt';
select t('real edit refreshes updated_at',
  (select updated_at > '2020-01-01' from prompts where slug = 'golden-hour-portrait-prompt'));

-- ================================= anonymous visitor =====================================
set local role anon;
select set_config('request.jwt.claim.sub', '', true);

select t('anon sees only live prompts (10 seed + 1 auto, no draft/future)', (select count(*) from prompts) = 11);
select t('anon cannot see draft or future prompt', not exists (select 1 from prompts where slug in ('draft-secret','future-prompt')));
select t('anon sees only active categories', (select count(*) from categories) = 5);
select t('draft prompt tag links are hidden from anon', (select count(*) from prompt_tags) = 16);
select t('anon sees public settings only', (select count(*) from site_settings) = 34
  and not exists (select 1 from site_settings where setting_key = 'secret_note'));
select t('anon title search works (ILIKE with trigram index)', (select count(*) from prompts where title ilike '%watercolor%') = 1);
select t('anon full-text search works', (select count(*) from prompts where search_vector @@ plainto_tsquery('simple', 'cinematic')) >= 1);
select t('anon sees published pages', (select count(*) from pages) = 6);

select expect_error('anon cannot insert a prompt', $q$insert into prompts (title, slug, prompt_text, category_id) values ('x','x','x',1)$q$);
select expect_blocked('anon cannot update a prompt', $q$update prompts set title = 'hacked'$q$);
select expect_blocked('anon cannot delete prompts', $q$delete from prompts$q$);
select expect_blocked('anon cannot update counters directly', $q$update prompts set views = 999999$q$);
select expect_error('anon cannot insert a category', $q$insert into categories (name, slug) values ('x','x')$q$);
select expect_blocked('anon cannot change settings', $q$update site_settings set setting_value = 'x'$q$);
select expect_error('anon cannot create a page', $q$insert into pages (title, slug) values ('x','x')$q$);
select expect_error('anon cannot read newsletter list', $q$select * from newsletter_subscribers$q$);
select expect_error('anon cannot read contact messages', $q$select * from contact_messages$q$);
select expect_error('anon cannot read profiles', $q$select * from profiles$q$);
select expect_error('anon cannot upload to storage', $q$insert into storage.objects (bucket_id, name) values ('prompts', 'evil.png')$q$);

select expect_ok('anon can subscribe to newsletter', $q$insert into newsletter_subscribers (email) values ('visitor@example.com')$q$);
select expect_error('duplicate email blocked (case-insensitive)', $q$insert into newsletter_subscribers (email) values ('VISITOR@example.com')$q$);
select expect_error('invalid email rejected', $q$insert into newsletter_subscribers (email) values ('not-an-email')$q$);
select expect_ok('anon can send a contact message', $q$insert into contact_messages (name, email, subject, message) values ('V','v@example.com','Hello','Nice site')$q$);
select expect_error('contact status cannot be forged', $q$insert into contact_messages (name, email, subject, message, status) values ('V','v@example.com','S','M','read')$q$);
select expect_error('over-long contact message rejected', $q$insert into contact_messages (name, email, subject, message) values ('V','v@example.com','S', repeat('a', 5001))$q$);

insert into scratch select 'before', copy_count from prompts where slug = 'rain-soaked-street-cinematic-prompt';
select increment_copy(id) from prompts where slug = 'rain-soaked-street-cinematic-prompt';
select increment_view(id) from prompts where slug = 'rain-soaked-street-cinematic-prompt';
insert into scratch select 'after', copy_count from prompts where slug = 'rain-soaked-street-cinematic-prompt';
select increment_copy(v) from scratch where k = 'draft_id';   -- try to count a draft prompt

-- ============================ logged-in user who is NOT an admin ==========================
reset role;
select t('counter RPC increments by exactly 1', (select v from scratch where k='after') = (select v from scratch where k='before') + 1);
select t('counter RPC ignores draft prompts', (select copy_count from prompts where slug = 'draft-secret') = 0);

set local role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);

select t('normal user is not admin', not public.is_admin());
select t('normal user sees only their own profile', (select count(*) from profiles) = 1);
select expect_error('user cannot promote themselves to admin', $q$update profiles set role = 'admin' where id = '22222222-2222-2222-2222-222222222222'$q$);
select expect_error('user cannot re-activate/alter is_active', $q$update profiles set is_active = true$q$);
select t('normal user cannot see drafts', not exists (select 1 from prompts where slug = 'draft-secret'));
select expect_error('normal user cannot insert a prompt', $q$insert into prompts (title, slug, prompt_text, category_id) values ('x','x','x',1)$q$);
select expect_blocked('normal user cannot edit prompts', $q$update prompts set title = 'hacked'$q$);
select expect_blocked('normal user cannot delete prompts', $q$delete from prompts$q$);
select t('normal user cannot read contact messages', (select count(*) from contact_messages) = 0);
select t('normal user cannot read newsletter list', (select count(*) from newsletter_subscribers) = 0);
select expect_error('normal user cannot upload to storage', $q$insert into storage.objects (bucket_id, name) values ('prompts', 'evil.png')$q$);

-- ==================================== admin ===============================================
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);

select t('admin is recognised', public.is_admin());
select t('admin sees drafts and future prompts', (select count(*) from prompts) = 13);
select t('admin sees inactive categories', exists (select 1 from categories where slug = 'hidden-cat'));
select t('admin sees private settings', exists (select 1 from site_settings where setting_key = 'secret_note'));
select t('admin can read contact messages', (select count(*) from contact_messages) >= 2);
select t('admin can read newsletter list', (select count(*) from newsletter_subscribers) >= 2);
select expect_ok('admin can create a prompt', $q$insert into prompts (title, slug, prompt_text, category_id) values ('Admin New','admin-new','text',(select id from categories where slug='portrait'))$q$);
select expect_ok('admin can edit a prompt', $q$update prompts set title = 'Admin Edited' where slug = 'admin-new'$q$);
select expect_ok('admin can upload to storage', $q$insert into storage.objects (bucket_id, name) values ('prompts', 'ok.webp')$q$);
select expect_error('admin cannot change own role through the API', $q$update profiles set role = 'user' where id = '11111111-1111-1111-1111-111111111111'$q$);
select expect_error('duplicate prompt slug rejected', $q$insert into prompts (title, slug, prompt_text, category_id) values ('Dup','admin-new','t',1)$q$);
select expect_error('bad slug format rejected', $q$insert into prompts (title, slug, prompt_text, category_id) values ('Bad','Bad Slug','t',1)$q$);
select expect_error('reserved page slug rejected', $q$insert into pages (title, slug) values ('Admin','admin')$q$);
select expect_error('invalid prompt type rejected', $q$update prompts set prompt_type = 'audio' where slug = 'admin-new'$q$);
select expect_error('category with prompts cannot be deleted', $q$delete from categories where slug = 'portrait'$q$);
select expect_ok('admin can delete a prompt', $q$delete from prompts where slug = 'golden-hour-portrait-prompt'$q$);

reset role;
select t('deleting a prompt also removes its tag links', (select count(*) from prompt_tags pt where pt.prompt_id not in (select id from prompts)) = 0);
select t('deleting a prompt also removes its collection links', (select count(*) from prompt_collections pc where pc.prompt_id not in (select id from prompts)) = 0);

-- ================================ flood guard (anon) ======================================
set local role anon;
select set_config('request.jwt.claim.sub', '', true);   -- truly anonymous again
select expect_error('flood guard stops mass contact submissions', $q$
  do $x$ begin for i in 1..40 loop
    insert into contact_messages (name, email, subject, message) values ('Bot','bot@example.com','spam','spam');
  end loop; end $x$ $q$);

reset role;
-- ================================= RESULTS ================================================
select case when ok then 'PASS' else 'FAIL' end as result, label, case when ok then '' else detail end as detail
from test_results order by ok, label;
select count(*) filter (where ok) as passed, count(*) filter (where not ok) as failed, count(*) as total from test_results;
rollback;
