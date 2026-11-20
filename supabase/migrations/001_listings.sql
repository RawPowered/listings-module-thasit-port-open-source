-- Portable Listings / Lovable v0.1: PostgreSQL 15+, Supabase Auth.
-- Apply via SQL editor on a reviewed project. No demo customer data.
create extension if not exists pgcrypto;

create table if not exists public.listing_tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{2,63}$'),
  created_at timestamptz not null default now()
);
create table if not exists public.listing_memberships (
  tenant_id uuid not null references public.listing_tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','member')),
  created_at timestamptz not null default now(),
  primary key (tenant_id,user_id)
);

create or replace function public.listings_is_member(p_tenant uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select exists (select 1 from public.listing_memberships m where m.tenant_id=p_tenant and m.user_id=(select auth.uid()));
$$;
create or replace function public.listings_can_moderate(p_tenant uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select exists (select 1 from public.listing_memberships m where m.tenant_id=p_tenant and m.user_id=(select auth.uid()) and m.role in ('owner','admin'));
$$;
revoke all on function public.listings_is_member(uuid) from public;
revoke all on function public.listings_can_moderate(uuid) from public;
grant execute on function public.listings_is_member(uuid), public.listings_can_moderate(uuid) to authenticated, anon;

create or replace function public.create_listings_workspace(p_name text, p_slug text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if char_length(trim(p_name)) not between 1 and 120
    or p_slug !~ '^[a-z0-9][a-z0-9-]{2,63}$' then
   raise exception 'Invalid workspace name or slug';
 end if;
 insert into public.listing_tenants(name,slug) values(trim(p_name),p_slug) returning id into v_id;
 insert into public.listing_memberships(tenant_id,user_id,role) values(v_id,auth.uid(),'owner');
 return v_id;
end; $$;
revoke all on function public.create_listings_workspace(text,text) from public;
grant execute on function public.create_listings_workspace(text,text) to authenticated;

create table if not exists public.listing_categories (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null references public.listing_tenants(id) on delete cascade,
 name text not null check (char_length(name) between 1 and 120),
 slug text not null check (slug ~ '^[a-z0-9][a-z0-9-]{0,99}$'),
 description text not null default '',
 created_at timestamptz not null default now(),
 unique(tenant_id,slug),
 unique(tenant_id,id)
);
create table if not exists public.listings (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null references public.listing_tenants(id) on delete cascade,
 owner_id uuid not null references auth.users(id),
 category_id uuid,
 title text not null check (char_length(title) between 1 and 180),
 slug text not null default (encode(gen_random_bytes(8),'hex')),
 summary text not null default '' check (char_length(summary)<=500),
 description text not null default '' check (char_length(description)<=50000),
 listing_type text not null default 'general' check (listing_type ~ '^[a-z][a-z0-9_-]{0,39}$'),
 status text not null default 'draft' check (status in ('draft','pending','published','archived')),
 visibility text not null default 'public' check (visibility in ('public','unlisted','private')),
 price_minor bigint check (price_minor >= 0),
 currency text not null default 'USD' check (currency ~ '^[A-Z]{3}$'),
 location_label text not null default '' check (char_length(location_label)<=180),
 latitude numeric(10,7) check (latitude between -90 and 90),
 longitude numeric(10,7) check (longitude between -180 and 180),
 attributes jsonb not null default '{}'::jsonb check (jsonb_typeof(attributes)='object'),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 published_at timestamptz,
 unique(tenant_id,slug),
 unique(tenant_id,id),
 foreign key(tenant_id,category_id) references public.listing_categories(tenant_id,id)
);
create index if not exists listings_feed_idx on public.listings(tenant_id,status,visibility,created_at desc);
create index if not exists listings_owner_idx on public.listings(tenant_id,owner_id,status);
create index if not exists listings_category_idx on public.listings(tenant_id,category_id,status);

create table if not exists public.listing_media (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null,
 listing_id uuid not null,
 media_url text not null check (media_url ~ '^https://[^[:space:]]+$' and char_length(media_url)<=2048),
 alt_text text not null default '' check (char_length(alt_text)<=255),
 sort_order integer not null default 0 check (sort_order between 0 and 100000),
 created_at timestamptz not null default now(),
 foreign key (tenant_id,listing_id) references public.listings(tenant_id,id) on delete cascade
);
create index if not exists listing_media_order_idx on public.listing_media(tenant_id,listing_id,sort_order);

create table if not exists public.listing_inquiries (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null,
 listing_id uuid not null,
 sender_name text not null,
 sender_email text not null,
 message text not null,
 status text not null default 'open',
 created_at timestamptz not null default now(),
 foreign key(tenant_id,listing_id) references public.listings(tenant_id,id) on delete cascade
);
create index if not exists listing_inquiries_tenant_idx on public.listing_inquiries(tenant_id,listing_id,created_at);

create or replace function public.listings_enforce_transition()
returns trigger language plpgsql set search_path = '' as $$
begin
 if tg_op='UPDATE' then
   if new.tenant_id <> old.tenant_id or new.owner_id <> old.owner_id or new.slug <> old.slug then
     raise exception 'Immutable listing identity';
   end if;
   if (new.status='published' and old.status is distinct from new.status)
     and not public.listings_can_moderate(old.tenant_id) then
     raise exception 'Only tenant moderators may publish';
   end if;
   if old.status='published' and new.status='published' and
      (new.title,new.summary,new.description,new.price_minor,new.category_id,new.attributes,new.visibility)
       is distinct from (old.title,old.summary,old.description,old.price_minor,old.category_id,old.attributes,old.visibility)
       and not public.listings_can_moderate(old.tenant_id) then
     new.status := 'pending';
   end if;
 end if;
 if new.status='published' and (tg_op='INSERT' or old.status is distinct from new.status) then
   new.published_at := now();
 elsif new.status <> 'published' then new.published_at := null;
 end if;
 new.updated_at := now();
 return new;
end; $$;
drop trigger if exists listings_transition_guard on public.listings;
create trigger listings_transition_guard before insert or update on public.listings for each row execute function public.listings_enforce_transition();

alter table public.listing_tenants enable row level security;
alter table public.listing_memberships enable row level security;
alter table public.listing_categories enable row level security;
alter table public.listings enable row level security;
alter table public.listing_media enable row level security;
alter table public.listing_inquiries enable row level security;

create policy tenants_read on public.listing_tenants for select to authenticated using (public.listings_is_member(id));
create policy memberships_read on public.listing_memberships for select to authenticated using (user_id=(select auth.uid()));
-- No direct membership INSERT/UPDATE/DELETE policies; use audited privileged invite flows.
create policy categories_read on public.listing_categories for select to anon,authenticated using (true);
create policy categories_insert on public.listing_categories for insert to authenticated with check (public.listings_can_moderate(tenant_id));
create policy categories_update on public.listing_categories for update to authenticated using (public.listings_can_moderate(tenant_id)) with check(public.listings_can_moderate(tenant_id));
create policy categories_delete on public.listing_categories for delete to authenticated using (public.listings_can_moderate(tenant_id));

create policy listings_read on public.listings for select to anon,authenticated using (
 (status='published' and visibility='public') or
 (owner_id=(select auth.uid()) and public.listings_is_member(tenant_id)) or
 public.listings_can_moderate(tenant_id)
);
create policy listings_insert on public.listings for insert to authenticated with check (
 owner_id=(select auth.uid()) and public.listings_is_member(tenant_id) and status='draft'
);
create policy listings_update on public.listings for update to authenticated using (
 (owner_id=(select auth.uid()) and public.listings_is_member(tenant_id)) or public.listings_can_moderate(tenant_id)
) with check (
 (owner_id=(select auth.uid()) and public.listings_is_member(tenant_id)) or public.listings_can_moderate(tenant_id)
);
create policy listings_delete on public.listings for delete to authenticated using (public.listings_can_moderate(tenant_id));

create policy media_read on public.listing_media for select to anon,authenticated using (
 exists (select 1 from public.listings l where l.tenant_id=listing_media.tenant_id and l.id=listing_media.listing_id)
);
create policy media_insert on public.listing_media for insert to authenticated with check (
 exists (select 1 from public.listings l where l.id=listing_media.listing_id and l.tenant_id=listing_media.tenant_id and
 (l.owner_id=(select auth.uid()) or public.listings_can_moderate(l.tenant_id)))
);
create policy media_delete on public.listing_media for delete to authenticated using (
 exists (select 1 from public.listings l where l.id=listing_media.listing_id and l.tenant_id=listing_media.tenant_id and
 (l.owner_id=(select auth.uid()) or public.listings_can_moderate(l.tenant_id)))
);
-- Inquiries: no API read/write policies. Use protected server functions and auditable permissions.
