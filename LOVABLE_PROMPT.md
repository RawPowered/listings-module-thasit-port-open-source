# Paste this prompt into Lovable

Build a responsive, production-oriented listing management web app using the already-connected Supabase project. Use both `supabase/migrations/001_listings.sql` and `supabase/migrations/002_listings_security_baseline.sql` in order in this repository; do not invent an alternate listings schema. Use `src/lib/listings.ts` as the typed database client adapter. Keep existing host design tokens and component conventions; do not replace my theme.

Implement the following pages with accessible, mobile-first layouts:

1. Public listings at /listings. Search by title/summary, filter by category, listing type, price range, newest/price sort, and paginate. Query only status=published AND visibility=public. Handle empty/loading/error states.
2. Listing detail at /listings/:slug. Display title, price (integer minor units formatted with Intl.NumberFormat), description, location label, category, and ordered HTTPS image gallery. Show only published public listings. Escape user text; do not use dangerouslySetInnerHTML.
3. Member dashboard at /dashboard/listings: authentication required, allow members to create/edit their own listings, save drafts, submit for review, archive. Do not let members edit owner_id, tenant_id, status or published_at directly except approved status transition commands.
4. Workspace owner moderation at /dashboard/moderation: show pending listings and publish/archive them through the database policies and trigger; show non-blocking feedback and audit trail placeholders (do not fake events).
5. Workspace bootstrapping after first login: call RPC create_listings_workspace(name, slug) once, save the returned tenant UUID in app state, use tenant_id in every write and dashboard query. Expose a workspace switcher if user has multiple memberships; never trust arbitrary tenant selection without membership.
6. Data entry: title, summary, description, type, price_minor and currency, category, location label, lat/long optional, structured attributes JSON, and media URLs. Validate on client and server; no user-supplied HTML. Media uploads need signed storage/authorization; do not offer arbitrary uploads until configured.
7. Accessibility: keyboard navigation, semantic headings, labels and errors, focus states, alt text, and reduced-motion handling.

Security: Before moderator workflows, implement TOTP MFA enrollment and AAL2 challenge in Supabase Auth; owners/admins without AAL2 cannot publish or edit categories. Do not offer unvetted external media URL insertion, and disable uploads until a vetted server-backed image service exists. Review docs/SECURITY_BASELINE.md and run supabase/tests/verify_security.sql; test anon/member/AAL1-owner/AAL2-owner/cross-tenant roles. Cloning does not install the security policies.

Security: never remove RLS, never use service_role in browser, never expose drafts in public search, do not add public anonymous inquiry INSERT. Inquiry form should be disabled with a clear integration note until a rate-limited CAPTCHA-checked Supabase Edge Function is implemented.

Deliver the React pages and a functioning Supabase-backed data flow, with no fake production data or fictional successful integrations. Preserve an existing application's auth/layout/theme if present. Provide a manual verification checklist for anonymous, member, owner and cross-tenant access.
