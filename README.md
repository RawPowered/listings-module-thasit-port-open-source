# Portable Listings Module — Lovable Adapter

This branch is a **Lovable + Supabase/Postgres reference implementation** of the public-domain listing-management concept. It is independently authored and is not a byte-for-byte extraction from Thasit's private implementation.

## Quick adoption

1. Create or open a Lovable project. Connect Supabase or the database integration supported by your Lovable project.
2. Run [supabase/migrations/001_listings.sql](supabase/migrations/001_listings.sql) through the Supabase SQL editor, on a fresh project or after reviewing naming conflicts. It adds tables, RLS policies and a workspace-bootstrap RPC.
3. Open [LOVABLE_PROMPT.md](LOVABLE_PROMPT.md) and paste its content into Lovable. Provide Lovable this repo branch URL: https://github.com/RawPowered/listings-module-thasit-port-open-source/tree/integrations/lovable
4. Copy [src/lib/listings.ts](src/lib/listings.ts) into the Lovable project and reuse its typed methods. Configure the project's existing Supabase client and auth flow.
5. Sign in; the app calls `create_listings_workspace` one time for a workspace. Owners can submit listings for moderation. **Publishing requires a workspace admin/owner** via a privileged workflow (see notes below).

**Important:** Lovable may generate source from the branch URL and supplied files; do not assume it can import an arbitrary existing repository as a native project. Copy SQL and client code explicitly if the builder cannot fetch private/public repo content.

### Capabilities
- Public listing feed with search, category, type and price filtering
- Details and photo gallery using *stored HTTPS image URLs* (upload authorization is host-managed)
- Draft → pending → published → archived listing lifecycle
- Owner dashboard and admin moderation
- Workspace/tenant isolation via PostgreSQL RLS
- Public inquiry submission **not enabled by default** (requires spam protection and a server endpoint)

### Security model
Authentication comes from Supabase Auth. Workspace membership, owner identity and publication privileges are checked in the database. **Never put a Supabase service-role key in a client app.** Only publish after an admin-mediated review. For launch, implement the admin screen using the RLS-compatible owner account; the database trigger enforces publication privilege. Public inquiry intake must pass a rate-limited CAPTCHA-backed server function and consent requirements; do not create an anonymous INSERT policy.

### Related branches
- [main](../../tree/main): portable core and integration contract
- [integrations/replit](../../tree/integrations/replit): Replit / Node integration

### Provenance and scope
Portable independent reconstruction. Review before use in production. This is not a payment platform, and image uploads, payments, analytics and automated moderation are not supplied.

License: MIT.
