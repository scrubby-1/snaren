-- Snaarmeter: database voor login en trainersoverzicht
-- Plak dit volledig in Supabase > SQL Editor en klik op Run.
-- Je mag het later opnieuw uitvoeren; bestaande gegevens blijven staan.

-- 1. Tabellen -------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  naam text not null default '',
  rol text not null default 'leerling' check (rol in ('leerling', 'trainer')),
  created_at timestamptz not null default now()
);

create table if not exists public.userdata (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.instellingen (
  id int primary key default 1 check (id = 1),
  clubcode text not null
);

-- Kies hier je eigen clubcode (leerlingen hebben die nodig om een account te maken)
insert into public.instellingen (id, clubcode) values (1, 'VERANDER-MIJ')
on conflict (id) do nothing;

-- 2. Beveiliging ------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.userdata enable row level security;
alter table public.instellingen enable row level security;  -- geen regels: de clubcode is voor niemand leesbaar

create or replace function public.is_trainer()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and rol = 'trainer');
$$;

drop policy if exists "profiel lezen" on public.profiles;
create policy "profiel lezen" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_trainer());

drop policy if exists "eigen naam aanpassen" on public.profiles;
create policy "eigen naam aanpassen" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- leerlingen mogen alleen hun naam wijzigen, nooit hun rol
revoke update on public.profiles from authenticated, anon;
grant update (naam) on public.profiles to authenticated;

drop policy if exists "data lezen" on public.userdata;
create policy "data lezen" on public.userdata
  for select to authenticated
  using (user_id = auth.uid() or public.is_trainer());

drop policy if exists "eigen data toevoegen" on public.userdata;
create policy "eigen data toevoegen" on public.userdata
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "eigen data aanpassen" on public.userdata;
create policy "eigen data aanpassen" on public.userdata
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 3. Nieuw account: clubcode controleren en profiel aanmaken ----------------

create or replace function public.nieuwe_gebruiker()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  if coalesce(new.raw_user_meta_data->>'clubcode', '')
     <> (select clubcode from public.instellingen where id = 1) then
    raise exception 'Ongeldige clubcode';
  end if;
  insert into public.profiles (id, naam)
  values (new.id, coalesce(nullif(trim(new.raw_user_meta_data->>'naam'), ''), split_part(new.email, '@', 1)));
  return new;
end;
$$;

drop trigger if exists bij_nieuwe_gebruiker on auth.users;
create trigger bij_nieuwe_gebruiker
  after insert on auth.users
  for each row execute function public.nieuwe_gebruiker();


-- ===========================================================================
-- LOSSE OPDRACHTEN (voer ze apart uit wanneer nodig)
-- ===========================================================================

-- Jezelf trainer maken, NADAT je in de app een account hebt gemaakt:
-- update public.profiles set rol = 'trainer'
-- where id = (select id from auth.users where email = 'JOUW-EMAIL');

-- Clubcode wijzigen (bestaande accounts blijven werken):
-- update public.instellingen set clubcode = 'NIEUWE-CODE' where id = 1;

-- Overzicht van alle accounts:
-- select p.naam, u.email, p.rol, p.created_at from public.profiles p join auth.users u on u.id = p.id order by p.naam;
