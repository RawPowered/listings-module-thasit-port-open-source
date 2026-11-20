-- Marketplace core v0.1. Apply AFTER 001_listings.sql in a reviewed development database.
-- All protected transitions use SECURITY DEFINER RPC with explicit auth checks.
-- No uploads, money movement, open invitations or generic admin service keys.
alter table public.listings
  add column if not exists budget_mode text not null default 'open'
    check (budget_mode in ('fixed','range','open')),
  add column if not exists budget_max_minor bigint check (budget_max_minor >= 0),
  add column if not exists proposal_deadline timestamptz;
alter table public.listings
  add constraint listings_budget_consistency check (
    (budget_mode = 'open' and price_minor is null and budget_max_minor is null)
    or (budget_mode = 'fixed' and price_minor is not null and budget_max_minor is null)
    or (budget_mode = 'range' and price_minor is not null and budget_max_minor is not null and budget_max_minor >= price_minor)
  ) not valid;
-- Existing listing records with a non-null price_minor need explicit budget_mode='fixed' migration
-- before running VALIDATE CONSTRAINT. New drafts default to open and require no price.
update public.listings set budget_mode='fixed' where price_minor is not null and budget_max_minor is null;
alter table public.listings validate constraint listings_budget_consistency;

create table public.marketplace_proposals (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  listing_id uuid not null,
  provider_id uuid not null references auth.users(id),
  amount_minor bigint check (amount_minor >= 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  message text not null check (length(trim(message)) between 1 and 12000),
  estimated_days integer check (estimated_days between 1 and 3650),
  status text not null default 'submitted' check (status in ('submitted','withdrawn','accepted','declined')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (tenant_id,listing_id) references public.listings(tenant_id,id) on delete restrict,
  unique (tenant_id,id)
);
create unique index marketplace_one_active_proposal_per_provider
  on public.marketplace_proposals(tenant_id,listing_id,provider_id)
  where status in ('submitted','accepted');
create index marketplace_proposal_listing_idx on public.marketplace_proposals(tenant_id,listing_id,created_at desc);
create index marketplace_proposal_provider_idx on public.marketplace_proposals(provider_id,created_at desc);

create table public.marketplace_engagements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  listing_id uuid not null,
  proposal_id uuid not null,
  requester_id uuid not null references auth.users(id),
  provider_id uuid not null references auth.users(id),
  status text not null default 'active' check (status in ('active','delivered','completed','cancelled','disputed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  foreign key (tenant_id,listing_id) references public.listings(tenant_id,id) on delete restrict,
  foreign key (tenant_id,proposal_id) references public.marketplace_proposals(tenant_id,id) on delete restrict,
  unique (tenant_id,id), unique (tenant_id,listing_id), unique (tenant_id,proposal_id),
  check (requester_id <> provider_id)
);
create index marketplace_engagement_actor_idx on public.marketplace_engagements(tenant_id,requester_id,provider_id);

create table public.marketplace_messages (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  engagement_id uuid not null,
  sender_id uuid not null references auth.users(id),
  body text not null check (length(trim(body)) between 1 and 10000),
  created_at timestamptz not null default now(),
  foreign key (tenant_id,engagement_id) references public.marketplace_engagements(tenant_id,id) on delete restrict
);
create index marketplace_messages_thread_idx on public.marketplace_messages(tenant_id,engagement_id,created_at);

create table public.marketplace_deliverables (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  engagement_id uuid not null,
  provider_id uuid not null references auth.users(id),
  -- storage_key is an opaque PRIVATE path; never use public object URLs
  storage_key text not null check (length(storage_key) between 1 and 1024),
  original_filename text not null check (length(original_filename) between 1 and 255),
  submitted_at timestamptz not null default now(),
  foreign key (tenant_id,engagement_id) references public.marketplace_engagements(tenant_id,id) on delete restrict
);
create index marketplace_deliverables_engagement_idx on public.marketplace_deliverables(tenant_id,engagement_id,submitted_at);

create table public.marketplace_revision_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  engagement_id uuid not null,
  requester_id uuid not null references auth.users(id),
  reason text not null check (length(trim(reason)) between 1 and 10000),
  created_at timestamptz not null default now(),
  foreign key (tenant_id,engagement_id) references public.marketplace_engagements(tenant_id,id) on delete restrict
);

create table public.marketplace_reports (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.listing_tenants(id),
  listing_id uuid,
  reporter_id uuid not null references auth.users(id),
  reason text not null check (length(trim(reason)) between 1 and 5000),
  status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now(),
  foreign key (tenant_id,listing_id) references public.listings(tenant_id,id) on delete restrict
);
create index marketplace_reports_tenant_idx on public.marketplace_reports(tenant_id,created_at desc);

create table public.marketplace_events (
  id bigint generated always as identity primary key,
  tenant_id uuid not null,
  engagement_id uuid,
  actor_id uuid not null references auth.users(id),
  event_type text not null,
  event_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  foreign key (tenant_id,engagement_id) references public.marketplace_engagements(tenant_id,id) on delete restrict
);
create index marketplace_events_engagement_idx on public.marketplace_events(tenant_id,engagement_id,id);

-- By default no direct write policies on proposals, engagements, deliveries, revisions or events.
alter table public.marketplace_proposals enable row level security;
alter table public.marketplace_engagements enable row level security;
alter table public.marketplace_messages enable row level security;
alter table public.marketplace_deliverables enable row level security;
alter table public.marketplace_revision_requests enable row level security;
alter table public.marketplace_reports enable row level security;
alter table public.marketplace_events enable row level security;

create or replace function public.marketplace_is_participant(p_tenant uuid,p_engagement uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.marketplace_engagements e
    where e.tenant_id=p_tenant and e.id=p_engagement
      and (e.requester_id=(select auth.uid()) or e.provider_id=(select auth.uid()))
  )
$$;
revoke all on function public.marketplace_is_participant(uuid,uuid) from public;
grant execute on function public.marketplace_is_participant(uuid,uuid) to authenticated;

create policy marketplace_proposals_read on public.marketplace_proposals
  for select to authenticated using (
    provider_id=(select auth.uid()) or exists (
      select 1 from public.listings l where l.tenant_id=marketplace_proposals.tenant_id
      and l.id=marketplace_proposals.listing_id and l.owner_id=(select auth.uid())
    ) or public.listings_can_moderate(tenant_id)
  );
create policy marketplace_engagements_read on public.marketplace_engagements
  for select to authenticated using (
    requester_id=(select auth.uid()) or provider_id=(select auth.uid()) or public.listings_can_moderate(tenant_id)
  );
create policy marketplace_messages_read on public.marketplace_messages
  for select to authenticated using (public.marketplace_is_participant(tenant_id,engagement_id));
create policy marketplace_messages_insert on public.marketplace_messages
  for insert to authenticated with check (
    sender_id=(select auth.uid()) and public.marketplace_is_participant(tenant_id,engagement_id)
    and exists (select 1 from public.marketplace_engagements e
      where e.tenant_id=marketplace_messages.tenant_id and e.id=marketplace_messages.engagement_id
      and e.status in ('active','delivered'))
  );
create policy marketplace_deliverables_read on public.marketplace_deliverables
  for select to authenticated using (public.marketplace_is_participant(tenant_id,engagement_id));
create policy marketplace_revisions_read on public.marketplace_revision_requests
  for select to authenticated using (public.marketplace_is_participant(tenant_id,engagement_id));
create policy marketplace_reports_read on public.marketplace_reports
  for select to authenticated using (reporter_id=(select auth.uid()) or public.listings_can_moderate(tenant_id));
create policy marketplace_reports_insert on public.marketplace_reports
  for insert to authenticated with check (
    reporter_id=(select auth.uid()) and public.listings_is_member(tenant_id)
    and status='open'
  );
create policy marketplace_events_read on public.marketplace_events
  for select to authenticated using (
    (engagement_id is not null and public.marketplace_is_participant(tenant_id,engagement_id))
    or public.listings_can_moderate(tenant_id)
  );

-- Database transaction and row locks are authoritative for proposal acceptance.
create or replace function public.marketplace_submit_proposal(
  p_tenant uuid, p_listing uuid, p_amount bigint, p_message text, p_days integer default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_l public.listings%rowtype; v_id uuid;
begin
 if auth.uid() is null or not public.listings_is_member(p_tenant) then raise exception 'Not authorized'; end if;
 select * into v_l from public.listings where id=p_listing and tenant_id=p_tenant;
 if not found or v_l.status <> 'published' or v_l.visibility <> 'public'
   or v_l.owner_id=auth.uid() or (v_l.proposal_deadline is not null and v_l.proposal_deadline < now())
 then raise exception 'Listing unavailable'; end if;
 if exists(select 1 from public.marketplace_engagements e where e.tenant_id=p_tenant and e.listing_id=p_listing)
 then raise exception 'Listing already assigned'; end if;
 if p_amount is not null and p_amount < 0 then raise exception 'Invalid amount'; end if;
 insert into public.marketplace_proposals(tenant_id,listing_id,provider_id,amount_minor,currency,message,estimated_days)
 values(p_tenant,p_listing,auth.uid(),p_amount,v_l.currency,p_message,p_days) returning id into v_id;
 return v_id;
end; $$;

create or replace function public.marketplace_withdraw_proposal(p_tenant uuid,p_proposal uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
 update public.marketplace_proposals p set status='withdrawn',updated_at=now()
 where p.tenant_id=p_tenant and p.id=p_proposal and p.provider_id=auth.uid() and p.status='submitted';
 if not found then raise exception 'Proposal unavailable'; end if;
end; $$;

create or replace function public.marketplace_accept_proposal(p_tenant uuid,p_proposal uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_p public.marketplace_proposals%rowtype; v_l public.listings%rowtype; v_id uuid;
begin
 if auth.uid() is null then raise exception 'Not authorized'; end if;
 select * into v_p from public.marketplace_proposals where tenant_id=p_tenant and id=p_proposal;
 if not found or v_p.status<>'submitted' then raise exception 'Proposal unavailable'; end if;
 select * into v_l from public.listings where tenant_id=p_tenant and id=v_p.listing_id for update;
 if not found or v_l.owner_id<>auth.uid() or v_l.status<>'published' then raise exception 'Not authorized or listing unavailable'; end if;
 -- Recheck proposal after taking the lock, to avoid racing withdraw/accept operations.
 select * into v_p from public.marketplace_proposals where tenant_id=p_tenant and id=p_proposal for update;
 if v_p.status<>'submitted' then raise exception 'Proposal unavailable'; end if;
 if exists(select 1 from public.marketplace_engagements where tenant_id=p_tenant and listing_id=v_p.listing_id)
 then raise exception 'Listing already assigned'; end if;
 insert into public.marketplace_engagements(tenant_id,listing_id,proposal_id,requester_id,provider_id)
 values(p_tenant,v_l.id,v_p.id,auth.uid(),v_p.provider_id) returning id into v_id;
 update public.marketplace_proposals set status='accepted',updated_at=now() where id=v_p.id;
 update public.marketplace_proposals set status='declined',updated_at=now()
 where tenant_id=p_tenant and listing_id=v_l.id and id<>v_p.id and status='submitted';
 insert into public.marketplace_events(tenant_id,engagement_id,actor_id,event_type)
 values(p_tenant,v_id,auth.uid(),'proposal.accepted');
 return v_id;
end; $$;

create or replace function public.marketplace_submit_delivery(
  p_tenant uuid,p_engagement uuid,p_storage_key text,p_filename text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_e public.marketplace_engagements%rowtype; v_id uuid;
begin
 select * into v_e from public.marketplace_engagements
 where tenant_id=p_tenant and id=p_engagement for update;
 if not found or v_e.provider_id<>auth.uid() or v_e.status<>'active'
 then raise exception 'Not authorized or engagement unavailable'; end if;
 -- The consuming backend MUST verify file ownership, scanning and private storage existence
 -- before calling this RPC. Until then disable document upload in the UI.
 insert into public.marketplace_deliverables(tenant_id,engagement_id,provider_id,storage_key,original_filename)
 values(p_tenant,p_engagement,auth.uid(),p_storage_key,p_filename) returning id into v_id;
 update public.marketplace_engagements set status='delivered',updated_at=now() where id=p_engagement;
 insert into public.marketplace_events(tenant_id,engagement_id,actor_id,event_type)
 values(p_tenant,p_engagement,auth.uid(),'delivery.submitted');
 return v_id;
end; $$;

create or replace function public.marketplace_request_revision(
  p_tenant uuid,p_engagement uuid,p_reason text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_e public.marketplace_engagements%rowtype; v_id uuid;
begin
 select * into v_e from public.marketplace_engagements where tenant_id=p_tenant and id=p_engagement for update;
 if not found or v_e.requester_id<>auth.uid() or v_e.status<>'delivered'
 then raise exception 'Not authorized or engagement not delivered'; end if;
 insert into public.marketplace_revision_requests(tenant_id,engagement_id,requester_id,reason)
 values(p_tenant,p_engagement,auth.uid(),p_reason) returning id into v_id;
 update public.marketplace_engagements set status='active',updated_at=now() where id=p_engagement;
 insert into public.marketplace_events(tenant_id,engagement_id,actor_id,event_type)
 values(p_tenant,p_engagement,auth.uid(),'revision.requested');
 return v_id;
end; $$;

create or replace function public.marketplace_complete_engagement(p_tenant uuid,p_engagement uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_e public.marketplace_engagements%rowtype;
begin
 select * into v_e from public.marketplace_engagements where tenant_id=p_tenant and id=p_engagement for update;
 if not found or v_e.requester_id<>auth.uid() or v_e.status<>'delivered'
 then raise exception 'Not authorized or engagement not delivered'; end if;
 update public.marketplace_engagements
 set status='completed',completed_at=now(),updated_at=now() where id=p_engagement;
 insert into public.marketplace_events(tenant_id,engagement_id,actor_id,event_type)
 values(p_tenant,p_engagement,auth.uid(),'engagement.completed');
end; $$;

-- Do not expose the delivery registration RPC to browsers until a server-side
-- verified private storage upload flow exists. Service context may be added later.
revoke all on function public.marketplace_submit_proposal(uuid,uuid,bigint,text,integer) from public;
revoke all on function public.marketplace_withdraw_proposal(uuid,uuid) from public;
revoke all on function public.marketplace_accept_proposal(uuid,uuid) from public;
revoke all on function public.marketplace_submit_delivery(uuid,uuid,text,text) from public;
revoke all on function public.marketplace_request_revision(uuid,uuid,text) from public;
revoke all on function public.marketplace_complete_engagement(uuid,uuid) from public;
grant execute on function public.marketplace_submit_proposal(uuid,uuid,bigint,text,integer),
 public.marketplace_withdraw_proposal(uuid,uuid),
 public.marketplace_accept_proposal(uuid,uuid),
 public.marketplace_request_revision(uuid,uuid,text),
 public.marketplace_complete_engagement(uuid,uuid) to authenticated;
-- marketplace_submit_delivery intentionally has no authenticated grant.
-- Grant to a tightly scoped server role only after verified storage integration.
