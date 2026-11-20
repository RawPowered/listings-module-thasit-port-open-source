-- Structural checks after applying the listings-only 001 and 002 migrations.
do $$
declare v_bad text;
begin
 select string_agg(req.name,', ') into v_bad
 from (values ('listing_tenants'),('listing_memberships'),('listings'),
 ('listing_categories'),('listing_media'),('listing_inquiries'),
 ('listings_rate_buckets')) req(name)
 where not exists(
   select 1 from pg_catalog.pg_class c
   join pg_catalog.pg_namespace n on n.oid=c.relnamespace
   where n.nspname='public' and c.relname=req.name and c.relrowsecurity
 );
 if v_bad is not null then raise exception 'RLS not enabled: %',v_bad; end if;

 if has_table_privilege('authenticated','public.listing_media','INSERT')
    or has_table_privilege('authenticated','public.listing_media','UPDATE')
    or has_table_privilege('authenticated','public.listing_inquiries','INSERT')
    or has_table_privilege('anon','public.listing_inquiries','INSERT')
 then raise exception 'Unexpected mutable media or inquiry grants'; end if;

 if has_function_privilege('authenticated','public.listings_consume_limit(text,integer,integer)','EXECUTE')
    or has_function_privilege('anon','public.create_listings_workspace(text,text)','EXECUTE')
 then raise exception 'Unsafe function grants'; end if;

 if pg_catalog.pg_get_functiondef('public.listings_can_moderate(uuid)'::regprocedure)
    not like '%aal2%' then raise exception 'AAL2 protection not found'; end if;
 raise notice 'Static checks passed; user-role integration tests remain necessary.';
end $$;
