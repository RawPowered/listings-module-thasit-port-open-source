-- 002_listings_security_baseline.sql
-- Portable listings-only hardening. Run AFTER 001_listings.sql on a reviewed
-- development Supabase project. This is not the marketplace-specific 002.
begin;

create or replace function public.listings_can_moderate(p_tenant uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((auth.jwt()->>'aal')='aal2',false) and exists (
    select 1 from public.listing_memberships m
    where m.tenant_id=p_tenant and m.user_id=(select auth.uid())
      and m.role in ('owner','admin')
  );
$$;
-- Public catalog RLS references this helper, so anon needs EXECUTE but gets
-- false when lacking a signed-in AAL2 moderator identity.
revoke all on function public.listings_can_moderate(uuid) from public,anon,authenticated;
grant execute on function public.listings_can_moderate(uuid) to anon,authenticated;

create or replace function public.listings_enforce_transition()
returns trigger language plpgsql set search_path = '' as $$
declare v_changed boolean;
begin
  if tg_op='INSERT' then
    if new.status<>'draft' then raise exception 'Listings must start as draft'; end if;
    new.created_at := clock_timestamp();
    new.updated_at := new.created_at;
    new.published_at := null;
    return new;
  end if;

  if new.tenant_id is distinct from old.tenant_id
    or new.owner_id is distinct from old.owner_id
    or new.slug is distinct from old.slug
    or new.created_at is distinct from old.created_at
  then raise exception 'Immutable listing identity and creation timestamp'; end if;

  v_changed := (new.title,new.summary,new.description,new.price_minor,
    new.category_id,new.attributes,new.visibility,new.listing_type,
    new.currency,new.location_label,new.latitude,new.longitude)
    is distinct from
    (old.title,old.summary,old.description,old.price_minor,
    old.category_id,old.attributes,old.visibility,old.listing_type,
    old.currency,old.location_label,old.latitude,old.longitude);

  if old.status='archived' and new.status<>'archived'
  then raise exception 'Archived listing requires a new draft'; end if;

  if old.status='published' and new.status='published'
    and v_changed and not public.listings_can_moderate(old.tenant_id)
  then new.status := 'pending'; end if;

  if new.status='published' and old.status<>'published' then
    if old.status<>'pending' or not public.listings_can_moderate(old.tenant_id)
    then raise exception 'Publication requires moderator MFA and pending review'; end if;
    new.published_at := clock_timestamp();
  elsif new.status='published' then
    new.published_at := old.published_at;
  else
    new.published_at := null;
  end if;
  new.updated_at := clock_timestamp();
  return new;
end; $$;

create table if not exists public.listings_rate_buckets (
  actor_id uuid not null references auth.users(id) on delete cascade,
  action text not null check (length(action) between 1 and 64),
  bucket_start timestamptz not null,
  attempts integer not null default 0 check (attempts >= 0),
  primary key(actor_id,action,bucket_start)
);
alter table public.listings_rate_buckets enable row level security;
revoke all on public.listings_rate_buckets from public,anon,authenticated;

create or replace function public.listings_consume_limit(p_action text,p_max integer,p_window_seconds integer)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_window timestamptz;
  v_attempts integer;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if p_max < 1 or p_max > 1000 or p_window_seconds < 1
    or p_window_seconds > 604800 or p_action !~ '^[a-z_]{2,64}$'
  then raise exception 'Invalid rate limit configuration'; end if;
  v_window := to_timestamp(floor(extract(epoch from clock_timestamp()) / p_window_seconds) * p_window_seconds);
  insert into public.listings_rate_buckets(actor_id,action,bucket_start,attempts)
    values(v_actor,p_action,v_window,1)
  on conflict(actor_id,action,bucket_start) do update
    set attempts=public.listings_rate_buckets.attempts+1
    where public.listings_rate_buckets.attempts<p_max
  returning attempts into v_attempts;
  if v_attempts is null then raise exception 'Rate limit exceeded'; end if;
end; $$;
revoke all on function public.listings_consume_limit(text,integer,integer)
  from public,anon,authenticated;

create or replace function public.create_listings_workspace(p_name text,p_slug text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_name is null or p_slug is null
    or length(trim(p_name)) not between 1 and 120
    or p_slug !~ '^[a-z0-9][a-z0-9-]{2,63}$'
  then raise exception 'Invalid workspace name or slug'; end if;
  perform public.listings_consume_limit('workspace',3,86400);
  insert into public.listing_tenants(name,slug)
    values(trim(p_name),p_slug) returning id into v_id;
  insert into public.listing_memberships(tenant_id,user_id,role)
    values(v_id,auth.uid(),'owner');
  return v_id;
end; $$;

-- Categories with no public listings are private to tenant members.
drop policy if exists categories_read on public.listing_categories;
create policy categories_read on public.listing_categories
  for select to anon,authenticated using (
    public.listings_is_member(tenant_id) or exists (
      select 1 from public.listings l
      where l.tenant_id=listing_categories.tenant_id
        and l.category_id=listing_categories.id
        and l.status='published' and l.visibility='public'
    )
  );

-- Unvetted browser-supplied HTTPS media URLs can leak visitors to third parties.
-- Enforce a vetted media/upload server instead of allowing direct mutations.
drop policy if exists media_insert on public.listing_media;
drop policy if exists media_delete on public.listing_media;
revoke insert,update,delete on public.listing_media from public,anon,authenticated;

revoke all on function public.create_listings_workspace(text,text) from public,anon,authenticated;
grant execute on function public.create_listings_workspace(text,text) to authenticated;

commit;