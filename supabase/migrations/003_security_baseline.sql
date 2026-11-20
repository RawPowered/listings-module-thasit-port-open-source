-- 003_security_baseline.sql
-- Additive hardening for generic Lovable marketplace. Run after 001 and 002.
-- Inspect on disposable Supabase project; do not run in an unknown production schema.
begin;

-- Privileged actions require a verified Supabase MFA AAL2 session. AAL1 members
-- can continue normal listing/proposal work; the bootstrap owner must enroll MFA.
create or replace function public.listings_can_moderate(p_tenant uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((auth.jwt()->>'aal')='aal2',false) and exists (
    select 1 from public.listing_memberships m
    where m.tenant_id=p_tenant and m.user_id=(select auth.uid())
      and m.role in ('owner','admin')
  );
$$;
-- Existing public listing RLS calls this helper for anon requests; return false
-- for unauthenticated requests rather than breaking public catalog reads.
revoke all on function public.listings_can_moderate(uuid) from public,anon,authenticated;
grant execute on function public.listings_can_moderate(uuid) to anon,authenticated;

-- Database-enforced listing provenance and unskippable publication review.
create or replace function public.listings_enforce_transition()
returns trigger language plpgsql set search_path = '' as $$
declare v_changed boolean;
begin
  if tg_op='INSERT' then
    if new.status <> 'draft' then raise exception 'Listings must start as draft'; end if;
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
    new.budget_mode,new.budget_max_minor,new.proposal_deadline,new.category_id,
    new.attributes,new.visibility,new.listing_type,new.currency,
    new.location_label,new.latitude,new.longitude)
    is distinct from
    (old.title,old.summary,old.description,old.price_minor,
    old.budget_mode,old.budget_max_minor,old.proposal_deadline,old.category_id,
    old.attributes,old.visibility,old.listing_type,old.currency,
    old.location_label,old.latitude,old.longitude);

  if old.status='archived' and new.status<>'archived' then
    raise exception 'Archived listing requires a new listing';
  end if;

  if v_changed and exists (
    select 1 from public.marketplace_engagements e
    where e.tenant_id=old.tenant_id and e.listing_id=old.id
  ) then raise exception 'Accepted engagement locks the agreed scope'; end if;

  if v_changed and exists (
    select 1 from public.marketplace_proposals p
    where p.tenant_id=old.tenant_id and p.listing_id=old.id
      and p.status='submitted'
  ) then raise exception 'Withdraw or resolve proposals before changing scope'; end if;

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

-- Internal authenticated-action throttling. Fixed parameters in privileged callers,
-- never exposed as a callable user-facing rate-limit bypass.
create table if not exists public.marketplace_rate_buckets (
  actor_id uuid not null references auth.users(id) on delete cascade,
  action text not null check (length(action) between 1 and 64),
  bucket_start timestamptz not null,
  attempts integer not null default 0 check (attempts >= 0),
  primary key(actor_id,action,bucket_start)
);
alter table public.marketplace_rate_buckets enable row level security;
revoke all on public.marketplace_rate_buckets from public,anon,authenticated;

create or replace function public.marketplace_consume_limit(
  p_action text,p_max integer,p_window_seconds integer
) returns void language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := auth.uid();
  v_window timestamptz;
  v_attempts integer;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if p_max < 1 or p_max > 1000 or p_window_seconds < 1 or p_window_seconds > 604800
    or p_action !~ '^[a-z_]{2,64}$' then raise exception 'Invalid rate limit configuration'; end if;
  v_window := to_timestamp(floor(extract(epoch from clock_timestamp()) / p_window_seconds) * p_window_seconds);
  insert into public.marketplace_rate_buckets(actor_id,action,bucket_start,attempts)
    values(v_actor,p_action,v_window,1)
  on conflict(actor_id,action,bucket_start) do update
    set attempts=public.marketplace_rate_buckets.attempts+1
    where public.marketplace_rate_buckets.attempts < p_max
  returning attempts into v_attempts;
  if v_attempts is null then raise exception 'Rate limit exceeded'; end if;
end; $$;
revoke all on function public.marketplace_consume_limit(text,integer,integer)
  from public,anon,authenticated;

-- Workspace creation also has a throttle. No anonymous or automatic tenant joins.
create or replace function public.create_listings_workspace(p_name text,p_slug text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_name is null or p_slug is null
    or char_length(trim(p_name)) not between 1 and 120
    or p_slug !~ '^[a-z0-9][a-z0-9-]{2,63}$'
  then raise exception 'Invalid workspace name or slug'; end if;
  perform public.marketplace_consume_limit('workspace',3,86400);
  insert into public.listing_tenants(name,slug)
    values(trim(p_name),p_slug) returning id into v_id;
  insert into public.listing_memberships(tenant_id,user_id,role)
    values(v_id,auth.uid(),'owner');
  return v_id;
end; $$;

-- Participants must still belong to the tenant. Removed members cannot view
-- sensitive workroom content merely because they were formerly a participant.
create or replace function public.marketplace_is_participant(
  p_tenant uuid,p_engagement uuid
) returns boolean language sql stable security definer set search_path = '' as $$
  select public.listings_is_member(p_tenant) and exists (
    select 1 from public.marketplace_engagements e
    where e.tenant_id=p_tenant and e.id=p_engagement
      and (e.requester_id=(select auth.uid()) or e.provider_id=(select auth.uid()))
  );
$$;

drop policy if exists marketplace_proposals_read on public.marketplace_proposals;
create policy marketplace_proposals_read on public.marketplace_proposals
  for select to authenticated using (
    public.listings_is_member(tenant_id) and (
      provider_id=(select auth.uid()) or public.listings_can_moderate(tenant_id)
      or exists(select 1 from public.listings l
        where l.tenant_id=marketplace_proposals.tenant_id
          and l.id=marketplace_proposals.listing_id and l.owner_id=(select auth.uid()))
    )
  );

drop policy if exists marketplace_engagements_read on public.marketplace_engagements;
create policy marketplace_engagements_read on public.marketplace_engagements
  for select to authenticated using (
    public.listings_is_member(tenant_id) and
    (requester_id=(select auth.uid()) or provider_id=(select auth.uid())
      or public.listings_can_moderate(tenant_id))
  );

drop policy if exists marketplace_reports_read on public.marketplace_reports;
create policy marketplace_reports_read on public.marketplace_reports
  for select to authenticated using (
    public.listings_is_member(tenant_id) and
    (reporter_id=(select auth.uid()) or public.listings_can_moderate(tenant_id))
  );

-- Hide unused/private taxonomy from anonymous visitors.
drop policy if exists categories_read on public.listing_categories;
create policy categories_read on public.listing_categories
  for select to anon,authenticated using (
    public.listings_is_member(tenant_id) or exists (
      select 1 from public.listings l
      where l.tenant_id=listing_categories.tenant_id
        and l.category_id=listing_categories.id and l.status='published'
        and l.visibility='public'
    )
  );

-- No arbitrary third-party image URL insertion by browser users.
-- Re-enable through a vetted server-side media/upload workflow only.
drop policy if exists media_insert on public.listing_media;
drop policy if exists media_delete on public.listing_media;
revoke insert,update,delete on public.listing_media from public,anon,authenticated;

-- Serialize submit/accept on the listing row to eliminate late proposals after
-- acceptance. Recheck the engagement after taking the lock.
create or replace function public.marketplace_submit_proposal(
  p_tenant uuid,p_listing uuid,p_amount bigint,p_message text,p_days integer default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_l public.listings%rowtype; v_id uuid;
begin
  if auth.uid() is null or not public.listings_is_member(p_tenant)
  then raise exception 'Not authorized'; end if;
  select * into v_l from public.listings
    where id=p_listing and tenant_id=p_tenant for update;
  if not found or v_l.status<>'published' or v_l.visibility<>'public'
    or v_l.owner_id=auth.uid()
    or (v_l.proposal_deadline is not null and v_l.proposal_deadline < now())
  then raise exception 'Listing unavailable'; end if;
  if exists (select 1 from public.marketplace_engagements e
    where e.tenant_id=p_tenant and e.listing_id=p_listing)
  then raise exception 'Listing already assigned'; end if;
  if p_amount is not null and p_amount < 0 then raise exception 'Invalid amount'; end if;
  perform public.marketplace_consume_limit('proposal',10,60);
  insert into public.marketplace_proposals(
    tenant_id,listing_id,provider_id,amount_minor,currency,message,estimated_days)
  values(p_tenant,p_listing,auth.uid(),p_amount,v_l.currency,p_message,p_days)
  returning id into v_id;
  return v_id;
end; $$;

-- A requester must remain a tenant member; selected provider must still be
-- eligible to participate. Existing transaction locks and uniqueness remain.
create or replace function public.marketplace_accept_proposal(
  p_tenant uuid,p_proposal uuid
) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_p public.marketplace_proposals%rowtype; v_l public.listings%rowtype; v_id uuid;
begin
  if auth.uid() is null or not public.listings_is_member(p_tenant)
  then raise exception 'Not authorized'; end if;
  select * into v_p from public.marketplace_proposals
    where tenant_id=p_tenant and id=p_proposal;
  if not found or v_p.status<>'submitted' then raise exception 'Proposal unavailable'; end if;
  select * into v_l from public.listings
    where tenant_id=p_tenant and id=v_p.listing_id for update;
  if not found or v_l.owner_id<>auth.uid() or v_l.status<>'published'
  then raise exception 'Not authorized or listing unavailable'; end if;
  select * into v_p from public.marketplace_proposals
    where tenant_id=p_tenant and id=p_proposal for update;
  if not found or v_p.status<>'submitted'
    or not exists(select 1 from public.listing_memberships m
      where m.tenant_id=p_tenant and m.user_id=v_p.provider_id)
  then raise exception 'Proposal unavailable'; end if;
  if exists(select 1 from public.marketplace_engagements
    where tenant_id=p_tenant and listing_id=v_l.id)
  then raise exception 'Listing already assigned'; end if;
  insert into public.marketplace_engagements(
    tenant_id,listing_id,proposal_id,requester_id,provider_id)
  values(p_tenant,v_l.id,v_p.id,auth.uid(),v_p.provider_id)
  returning id into v_id;
  update public.marketplace_proposals set status='accepted',updated_at=now() where id=v_p.id;
  update public.marketplace_proposals set status='declined',updated_at=now()
    where tenant_id=p_tenant and listing_id=v_l.id and id<>v_p.id and status='submitted';
  insert into public.marketplace_events(tenant_id,engagement_id,actor_id,event_type)
    values(p_tenant,v_id,auth.uid(),'proposal.accepted');
  return v_id;
end; $$;

-- Trigger-level throttles cannot be bypassed by using direct PostgREST INSERT.
create or replace function public.marketplace_message_insert_guard()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or new.sender_id is distinct from auth.uid()
    or not public.marketplace_is_participant(new.tenant_id,new.engagement_id)
  then raise exception 'Not authorized'; end if;
  perform public.marketplace_consume_limit('message',30,60);
  new.created_at := clock_timestamp();
  return new;
end; $$;
drop trigger if exists marketplace_message_insert_guard on public.marketplace_messages;
create trigger marketplace_message_insert_guard before insert on public.marketplace_messages
  for each row execute function public.marketplace_message_insert_guard();
revoke all on function public.marketplace_message_insert_guard() from public,anon,authenticated;

create or replace function public.marketplace_report_insert_guard()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or new.reporter_id is distinct from auth.uid()
    or not public.listings_is_member(new.tenant_id)
  then raise exception 'Not authorized'; end if;
  perform public.marketplace_consume_limit('report',5,86400);
  new.status := 'open';
  new.created_at := clock_timestamp();
  return new;
end; $$;
drop trigger if exists marketplace_report_insert_guard on public.marketplace_reports;
create trigger marketplace_report_insert_guard before insert on public.marketplace_reports
  for each row execute function public.marketplace_report_insert_guard();
revoke all on function public.marketplace_report_insert_guard() from public,anon,authenticated;

-- Explicit least-privilege grants for marketplace tables in installations
-- where Supabase default grants were customized.
revoke all on public.marketplace_proposals,public.marketplace_engagements,
  public.marketplace_messages,public.marketplace_deliverables,
  public.marketplace_revision_requests,public.marketplace_reports,
  public.marketplace_events from public,anon,authenticated;
grant select on public.marketplace_proposals,public.marketplace_engagements,
  public.marketplace_messages,public.marketplace_deliverables,
  public.marketplace_revision_requests,public.marketplace_reports,
  public.marketplace_events to authenticated;
grant insert on public.marketplace_messages,public.marketplace_reports to authenticated;

-- No browser permission to forge accepted proposals, financial outcomes,
-- delivery metadata, revisions, or immutable event history.
revoke all on function public.marketplace_submit_delivery(uuid,uuid,text,text)
  from public,anon,authenticated;
revoke all on function public.marketplace_consume_limit(text,integer,integer)
  from public,anon,authenticated;

-- Explicit anonymous/API privilege gate for protected RPCs.
revoke all on function public.create_listings_workspace(text,text)
  from public,anon,authenticated;
grant execute on function public.create_listings_workspace(text,text) to authenticated;
revoke all on function public.marketplace_submit_proposal(uuid,uuid,bigint,text,integer)
  from public,anon,authenticated;
revoke all on function public.marketplace_accept_proposal(uuid,uuid)
  from public,anon,authenticated;
grant execute on function public.marketplace_submit_proposal(uuid,uuid,bigint,text,integer),
  public.marketplace_accept_proposal(uuid,uuid) to authenticated;

commit;