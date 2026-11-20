-- Read-only structural security assertions. Run AFTER migrations 001..004.
-- SQL Editor / staging only. Structural checks cannot simulate JWT/RLS behavior.
do $$
declare
  v_missing text;
begin
  select string_agg(req.name, ', ') into v_missing from (
    values ('listing_tenants'),('listing_memberships'),('listings'),
      ('listing_categories'),('listing_media'),('listing_inquiries'),
      ('marketplace_proposals'),('marketplace_engagements'),
      ('marketplace_messages'),('marketplace_deliverables'),
      ('marketplace_revision_requests'),('marketplace_reports'),
      ('marketplace_events'),('marketplace_rate_buckets'),
      ('marketplace_invitations')
  ) as req(name)
  where not exists (
    select 1 from pg_catalog.pg_class c
      join pg_catalog.pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname=req.name
      and c.relkind in ('r','p') and c.relrowsecurity
  );
  if v_missing is not null then raise exception 'RLS missing on: %',v_missing; end if;

  if has_table_privilege('anon','public.marketplace_messages','SELECT')
    or has_table_privilege('anon','public.marketplace_proposals','SELECT')
    or has_table_privilege('anon','public.marketplace_invitations','SELECT')
  then raise exception 'Anonymous grants on protected marketplace tables'; end if;

  if has_table_privilege('authenticated','public.marketplace_engagements','UPDATE')
    or has_table_privilege('authenticated','public.marketplace_proposals','UPDATE')
    or has_table_privilege('authenticated','public.marketplace_events','INSERT')
    or has_table_privilege('authenticated','public.marketplace_deliverables','INSERT')
    or has_table_privilege('authenticated','public.listing_media','INSERT')
    or has_table_privilege('authenticated','public.marketplace_invitations','SELECT')
  then raise exception 'Direct protected mutation/view privilege remains'; end if;

  if has_function_privilege('anon','public.marketplace_accept_proposal(uuid,uuid)','EXECUTE')
    or has_function_privilege('authenticated','public.marketplace_submit_delivery(uuid,uuid,text,text)','EXECUTE')
    or has_function_privilege('authenticated','public.marketplace_consume_limit(text,integer,integer)','EXECUTE')
  then raise exception 'Privileged RPC execution grant is too broad'; end if;

  if not has_function_privilege('authenticated','public.marketplace_submit_proposal(uuid,uuid,bigint,text,integer)','EXECUTE')
    or not has_function_privilege('authenticated','public.marketplace_redeem_invitation(text)','EXECUTE')
  then raise exception 'Required safe RPC permission missing'; end if;

  if pg_catalog.pg_get_functiondef('public.listings_can_moderate(uuid)'::regprocedure) not like '%aal2%'
  then raise exception 'Moderator MFA check missing'; end if;

  if not exists (
    select 1 from pg_catalog.pg_trigger
    where tgrelid='public.marketplace_messages'::regclass
      and tgname='marketplace_message_insert_guard' and not tgisinternal
  ) or not exists (
    select 1 from pg_catalog.pg_trigger
    where tgrelid='public.marketplace_reports'::regclass
      and tgname='marketplace_report_insert_guard' and not tgisinternal
  ) then raise exception 'Rate-limit trigger missing'; end if;

  if exists(
    select 1 from pg_catalog.pg_policies
    where schemaname='public' and tablename='listing_media'
      and cmd in ('INSERT','UPDATE','DELETE','ALL')
  ) then raise exception 'Browser media mutation policy must remain disabled'; end if;

  raise notice 'Static security assertions passed. Now run signed-in role tests and concurrency tests.';
end $$;
