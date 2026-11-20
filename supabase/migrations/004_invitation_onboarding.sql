-- 004_invitation_onboarding.sql
-- No open self-join, no emailed secrets and no privilege escalation.
-- Moderators must have AAL2 MFA to issue short-lived, one-time invites.
begin;

create table if not exists public.marketplace_invitations (
  token_hash text primary key check (token_hash ~ '^[a-f0-9]{64}$'),
  tenant_id uuid not null references public.listing_tenants(id) on delete cascade,
  issued_by uuid not null references auth.users(id),
  redeemed_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  redeemed_at timestamptz,
  revoked_at timestamptz,
  constraint marketplace_invite_redeemed_consistency check (
    (redeemed_by is null and redeemed_at is null)
    or (redeemed_by is not null and redeemed_at is not null)
  )
);
create index if not exists marketplace_invites_expiration_idx
  on public.marketplace_invitations(expires_at);
alter table public.marketplace_invitations enable row level security;
revoke all on public.marketplace_invitations from public,anon,authenticated;

-- Return the opaque token exactly once; store only its SHA256 digest.
-- No invitation is generated unless workspace moderator has verified AAL2.
create or replace function public.marketplace_issue_invitation(
  p_tenant uuid,p_ttl_seconds integer default 86400
) returns text language plpgsql security definer set search_path = '' as $$
declare
  v_token text;
begin
  if auth.uid() is null or not public.listings_can_moderate(p_tenant)
  then raise exception 'Moderator MFA required'; end if;
  if p_ttl_seconds < 300 or p_ttl_seconds > 604800
  then raise exception 'Invalid invitation lifetime'; end if;
  perform public.marketplace_consume_limit('invite_issue',15,86400);
  -- Two independent v4 UUIDs give 244 random bits; all functions below
  -- are PostgreSQL built-ins available through pg_catalog with search_path=''.
  v_token := replace(gen_random_uuid()::text,'-','')
    || replace(gen_random_uuid()::text,'-','');
  insert into public.marketplace_invitations(
    token_hash,tenant_id,issued_by,expires_at)
  values(encode(sha256(convert_to(v_token,'UTF8')),'hex'),p_tenant,auth.uid(),
    clock_timestamp()+make_interval(secs=>p_ttl_seconds));
  return v_token;
end; $$;

-- Redeem one-use invite. Always enroll as member, never owner/admin.
-- Row lock prevents same token being redeemed by two accounts concurrently.
create or replace function public.marketplace_redeem_invitation(p_token text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_inv public.marketplace_invitations%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  perform public.marketplace_consume_limit('invite_redeem',10,3600);
  if p_token is null or p_token !~ '^[a-f0-9]{64}$'
  then return null; end if;

  select * into v_inv from public.marketplace_invitations
    where token_hash=encode(sha256(convert_to(p_token,'UTF8')),'hex') for update;
  if not found or v_inv.redeemed_at is not null or v_inv.revoked_at is not null
    or v_inv.expires_at < clock_timestamp()
  then return null; end if;
  if exists (
    select 1 from public.listing_memberships m
    where m.tenant_id=v_inv.tenant_id and m.user_id=auth.uid()
  ) then return null; end if;

  insert into public.listing_memberships(tenant_id,user_id,role)
    values(v_inv.tenant_id,auth.uid(),'member');
  update public.marketplace_invitations
    set redeemed_by=auth.uid(),redeemed_at=clock_timestamp()
    where token_hash=v_inv.token_hash;
  return v_inv.tenant_id;
end; $$;

revoke all on function public.marketplace_issue_invitation(uuid,integer)
  from public,anon,authenticated;
revoke all on function public.marketplace_redeem_invitation(text)
  from public,anon,authenticated;
grant execute on function public.marketplace_issue_invitation(uuid,integer),
  public.marketplace_redeem_invitation(text) to authenticated;

commit;