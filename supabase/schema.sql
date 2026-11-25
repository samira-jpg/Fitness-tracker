-- Fitness Tracker — database schema
-- Already applied to the project (migration: sessions_and_coach_share_links).
-- Kept here so the schema lives with the code and can be recreated from scratch.

-- One row per workout session, owned by the athlete.
create table public.sessions (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  id      text not null,                      -- "2026-11-19-A"
  date    date not null,
  workout text not null check (workout in ('A','B')),
  items   jsonb not null default '{}'::jsonb, -- { exerciseId: { name, reps, rl, side, notes, sets:[{w,rpe,r}] } }
  updated timestamptz not null default now(),
  primary key (user_id, id)
);
create index sessions_user_date_idx on public.sessions (user_id, date);

alter table public.sessions enable row level security;

create policy "read own sessions"   on public.sessions for select using (auth.uid() = user_id);
create policy "insert own sessions" on public.sessions for insert with check (auth.uid() = user_id);
create policy "update own sessions" on public.sessions for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own sessions" on public.sessions for delete using (auth.uid() = user_id);

-- A share link lets one coach read one athlete's sessions, without an account.
create table public.share_links (
  token      uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  label      text,
  revoked    boolean not null default false,
  created_at timestamptz not null default now()
);
create index share_links_user_idx on public.share_links (user_id);

alter table public.share_links enable row level security;

create policy "read own links"   on public.share_links for select using (auth.uid() = user_id);
create policy "insert own links" on public.share_links for insert with check (auth.uid() = user_id);
create policy "update own links" on public.share_links for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own links" on public.share_links for delete using (auth.uid() = user_id);

-- The coach's only read path: a valid, unrevoked token in, that athlete's sessions out.
-- SECURITY DEFINER on purpose — the caller is anonymous and has no rows of their own.
-- Supabase's linter flags any such function; this one is safe because it returns
-- nothing without a matching token, and the token is an unguessable uuid.
create or replace function public.sessions_for_token(p_token uuid)
returns table (id text, date date, workout text, items jsonb, updated timestamptz)
language sql
security definer
set search_path = public, pg_temp
stable
as $$
  select s.id, s.date, s.workout, s.items, s.updated
    from public.sessions s
    join public.share_links l on l.user_id = s.user_id
   where l.token = p_token
     and l.revoked = false
   order by s.date;
$$;

revoke all on function public.sessions_for_token(uuid) from public;
grant execute on function public.sessions_for_token(uuid) to anon, authenticated;
