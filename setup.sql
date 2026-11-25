-- Jhumka Base: Supabase setup. Paste this whole file into Supabase > SQL Editor > Run.
-- Before running: change the owner email on the line marked  <<< YOUR EMAIL.

create table if not exists public.members (
  email     text primary key,
  role      text not null default 'member' check (role in ('owner','member')),
  added_at  timestamptz not null default now(),
  added_by  text
);

create table if not exists public.docs (
  coll        text not null,
  id          text not null,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now(),
  primary key (coll, id)
);

-- The first owner. Only this email can create the first account.
insert into public.members(email, role) values (lower('shibliiiparamban@gmail.com'), 'owner')  -- <<< YOUR EMAIL
on conflict (email) do nothing;

-- ---------- helpers ----------
create or replace function public.my_email() returns text
language sql stable as $$ select lower(coalesce(auth.jwt() ->> 'email','')) $$;

create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.members m where m.email = public.my_email())
$$;

create or replace function public.is_owner() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.members m where m.email = public.my_email() and m.role = 'owner')
$$;

-- ---------- only invited emails can create an account ----------
create or replace function public.only_invited() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.members m where m.email = lower(new.email)) then
    raise exception 'NOT_INVITED';
  end if;
  return new;
end $$;

do $$ begin
  if to_regclass('auth.users') is not null then
    drop trigger if exists only_invited on auth.users;
    create trigger only_invited before insert on auth.users
      for each row execute function public.only_invited();
  end if;
end $$;

-- ---------- owner actions ----------
create or replace function public.invite_member(p_email text) returns void
language plpgsql security definer set search_path = public as $$
declare e text := lower(trim(p_email));
begin
  if not public.is_owner() then raise exception 'OWNER_ONLY'; end if;
  if e !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then raise exception 'BAD_EMAIL'; end if;
  insert into public.members(email, role, added_by) values (e, 'member', public.my_email())
  on conflict (email) do nothing;
end $$;

-- Removes access for good: deletes the member and the login, so the email must be invited again.
create or replace function public.remove_member(p_email text) returns void
language plpgsql security definer set search_path = public as $$
declare e text := lower(trim(p_email));
begin
  if not public.is_owner() then raise exception 'OWNER_ONLY'; end if;
  if exists (select 1 from public.members where email = e and role = 'owner') then raise exception 'CANNOT_REMOVE_OWNER'; end if;
  delete from public.members where email = e;
  if to_regclass('auth.users') is not null then
    execute 'delete from auth.users where lower(email) = $1' using e;
  end if;
end $$;

-- Owner list with sign-up status.
create or replace function public.list_members() returns table(email text, role text, added_at timestamptz, joined boolean)
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_owner() then raise exception 'OWNER_ONLY'; end if;
  if to_regclass('auth.users') is null then
    return query select m.email, m.role, m.added_at, false from public.members m order by m.added_at;
  else
    return query execute 'select m.email, m.role, m.added_at, exists(select 1 from auth.users u where lower(u.email)=m.email) from public.members m order by m.added_at';
  end if;
end $$;

-- Lets the sign-up screen say "not invited" before sending a code. Returns true/false only.
create or replace function public.is_invited(p_email text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.members where email = lower(trim(p_email)))
$$;

revoke all on function public.invite_member(text), public.remove_member(text), public.list_members() from public, anon;
grant execute on function public.invite_member(text), public.remove_member(text), public.list_members() to authenticated;
grant execute on function public.is_invited(text) to anon, authenticated;
grant execute on function public.is_member(), public.is_owner(), public.my_email() to anon, authenticated;

-- ---------- row level security ----------
alter table public.members enable row level security;
alter table public.docs    enable row level security;

drop policy if exists members_self on public.members;
create policy members_self on public.members for select to authenticated
  using (email = public.my_email() or public.is_owner());

drop policy if exists docs_read on public.docs;
create policy docs_read on public.docs for select to authenticated using (public.is_member());

-- Everyone invited can add and change entries. Settings, roles and goals are owner only.
-- Each person writes only their own profile (team/<their id>); the owner can change any.
create or replace function public.can_write(p_coll text, p_id text) returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_member() and (
    p_coll in ('products','purchases','expenses','customers','sales','returns','barcodes','activity')
    or (p_coll = 'config' and p_id = 'backup')
    or (p_coll = 'team' and p_id = auth.uid()::text)
    or public.is_owner()
  )
$$;

drop policy if exists docs_ins on public.docs;
create policy docs_ins on public.docs for insert to authenticated with check (public.can_write(coll, id));
drop policy if exists docs_upd on public.docs;
create policy docs_upd on public.docs for update to authenticated using (public.can_write(coll, id)) with check (public.can_write(coll, id));
drop policy if exists docs_del on public.docs;
create policy docs_del on public.docs for delete to authenticated using (public.can_write(coll, id));

grant select, insert, update, delete on public.docs to authenticated;
grant select on public.members to authenticated;

-- live updates between phones
do $$ begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin alter publication supabase_realtime add table public.docs; exception when duplicate_object then null; end;
  end if;
end $$;
alter table public.docs replica identity full;
