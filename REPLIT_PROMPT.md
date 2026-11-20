# Paste into Replit Agent

Create a full-stack responsive listings platform using TypeScript/React for the UI and a server-side API where needed. The authoritative source is this repository branch: https://github.com/RawPowered/listings-module-thasit-port-open-source/tree/integrations/replit

Apply the supplied `supabase/migrations/001_listings.sql` then `supabase/migrations/002_listings_security_baseline.sql`; use `src/lib/listings.ts` as the data and client contract. Do not invent incompatible tables, do not remove RLS, and do not expose Supabase service-role credentials to the browser. Use Supabase Auth, PostgreSQL and React. Read this repo's `LOVABLE_PROMPT.md` for functional page requirements, but implement in Replit's app setup.

Deliver:
- Public listings feed and detail pages, with search, category and price filtering, pagination, and media galleries.
- Authenticated workspace initialization with `create_listings_workspace` RPC and workspace switcher.
- Member dashboard for create/edit/submit/archive, owner moderation for publish (MFA AAL2 required), and loading/error/empty states.
- Supabase Auth TOTP MFA enrollment/challenge for moderators, with a clear blocked state until AAL2.
- Accessible responsive UI, theme tokens, safe text rendering and integer-currency formatting.
- `.env.example` documenting public Supabase URL + publishable/anon key; never commit real keys.
- A manual integration test script: anonymous read, member draft creation, member self-publish denied, owner approval, cross-workspace draft denied.

Important: No inquiry submission until you implement a protected server function with abuse prevention, rate limiting and consent. Do not silently fake working uploads, payments, notifications, or data. Display optional integrations as inactive until configured.

Run the app and validate the flows against a disposable Supabase project. Include deploy instructions for Replit's currently supported runtime.

Security review: implement no untrusted media uploads by default, run `supabase/tests/verify_security.sql`, and document which host-specific TLS/CSP/abuse controls need configuration. Do not claim a production-ready security audit.
