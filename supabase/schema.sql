-- ZabanYar initial schema for Supabase (PostgreSQL)
-- Apply only after creating a Supabase project and reviewing the policies.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'student' check (role in ('student','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  price_irr bigint not null default 0 check (price_irr >= 0),
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  body jsonb not null default '{}'::jsonb,
  position integer not null default 1,
  is_free boolean not null default false,
  status text not null default 'draft' check (status in ('draft','pending_review','published','rejected')),
  generated_by_ai boolean not null default false,
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete restrict,
  amount_irr bigint not null check (amount_irr >= 0),
  provider text not null,
  provider_reference text unique,
  status text not null default 'pending' check (status in ('pending','paid','failed','refunded')),
  created_at timestamptz not null default now()
);

create table if not exists public.ads (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null default '',
  image_url text,
  destination_url text,
  placement text not null check (placement in ('home','between_lessons','page_bottom')),
  starts_at timestamptz,
  ends_at timestamptz,
  approved boolean not null default false,
  active boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

alter table public.profiles enable row level security;
alter table public.courses enable row level security;
alter table public.lessons enable row level security;
alter table public.purchases enable row level security;
alter table public.ads enable row level security;

create policy "Users can read own profile" on public.profiles
for select using (id = auth.uid() or public.is_admin());
create policy "Users can update own display name" on public.profiles
for update using (id = auth.uid()) with check (id = auth.uid() and role = 'student');
create policy "Admins manage profiles" on public.profiles
for all using (public.is_admin()) with check (public.is_admin());

create policy "Published courses are public" on public.courses
for select using (is_published or public.is_admin());
create policy "Admins manage courses" on public.courses
for all using (public.is_admin()) with check (public.is_admin());

create policy "Published lessons and free previews are visible" on public.lessons
for select using (
  public.is_admin()
  or (status = 'published' and exists (
    select 1 from public.courses c where c.id = course_id and c.is_published
  ) and (is_free or exists (
    select 1 from public.purchases p
    where p.course_id = lessons.course_id and p.user_id = auth.uid() and p.status = 'paid'
  )))
);
create policy "Admins manage lessons" on public.lessons
for all using (public.is_admin()) with check (public.is_admin());

create policy "Users see own purchases" on public.purchases
for select using (user_id = auth.uid() or public.is_admin());
create policy "Admins manage purchases" on public.purchases
for all using (public.is_admin()) with check (public.is_admin());

create policy "Approved active ads are public" on public.ads
for select using (
  approved and active and (starts_at is null or starts_at <= now())
  and (ends_at is null or ends_at >= now())
);
create policy "Admins manage ads" on public.ads
for all using (public.is_admin()) with check (public.is_admin());

-- IMPORTANT:
-- Never let a browser client mark a purchase as paid.
-- Verify payment callbacks/webhooks in a trusted server function.
-- AI-generated lessons should be inserted with status='pending_review';
-- only an admin may publish them after review.
-- Create the first admin profile through a trusted SQL editor after verifying
-- the user's auth UUID. Do not expose service-role keys in browser code.