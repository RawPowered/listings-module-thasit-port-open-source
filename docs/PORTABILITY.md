# Portable contract

## Fundamental rules

1. Every record belongs to one tenant, owner, and optionally a category.
2. Anonymous users see only `status=published` AND `visibility=public` records.
3. Listing owners may create drafts and submit them. A privileged reviewer publishes.
4. Ownership, tenant, status and creation timestamps are never blindly mass-assigned.
5. Media and categories are always tenant-scoped.
6. Price is stored as an integer of currency minor units.
7. Inquiries require consent, CAPTCHA/rate limiting, a protected server handler, and private retrieval.

## Adapter interface

- `browse(filters)` → public paginated listing feed
- `getPublic(tenantId,slug)` → published public listing or not found
- `categories(tenantId)` → available categories
- `create(tenantId,actorId,input)` → new draft
- `update(tenantId,actorId,id,patch)` → protected editing
- `submit(tenantId,actorId,id)` → pending review
- `publish(tenantId,actorId,id)` → reviewer-only publication
- `archive(tenantId,actorId,id)` → remove from public views
- `media(tenantId,id)` → ordered media references
- `inquire(tenantId,slug,input)` → protected backend only

See `contracts/listing.schema.json` for canonical field names. Implement the interface using the host's own database/auth mechanisms. A client-side TypeScript API is not authorization.

## Builder mapping

- **Lovable:** use the dedicated branch for Supabase schema, row-level security, and typed client.
- **Replit:** use the dedicated branch for Node-oriented setup.
- **Other builders:** map the same data contract to the builder's supported server runtime, database and auth. Do not expose database administrator credentials in generated frontend code.

## Out of scope

Payment processing, booking, escrow, legal compliance, file processing, seller verification, geocoding and inquiry email delivery. Before launch: test tenant isolation, moderation, content rendering, input validation and backup/recovery.