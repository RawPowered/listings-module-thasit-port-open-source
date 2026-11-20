# Day-one security for the portable listings adapter

The reference listings adapter now has **two migrations**: \`001_listings.sql\` creates the schema and policies, and \`002_listings_security_baseline.sql\` tightens authentication, provenance, moderation, rate limits and browser upload permissions.

## Enforced in a Supabase instance *after* running both migrations

- Tenant-level ownership, RLS, and draft/publication review.
- AAL2 MFA is required for tenant owner/admin actions that invoke \`listings_can_moderate\`. Owner must enroll TOTP and refresh its session before attempting to publish.
- Server-created listing timestamps and non-bypassable pending-review publication.
- Owner cannot directly change immutable tenant/owner/slug/created_at attributes.
- Throttle successful new-workspace creation (3/24h/account) via database counters.
- No browser writes to arbitrary third-party image/media URLs.
- Anonymous users cannot enumerate categories without published listings.
- No direct anonymous or authenticated writes to inquiries.

## Deployment gates still required

Clone/fork alone does **not** run SQL or configure Supabase. Apply both migrations on a disposable development database, then verify actual logged-in roles before public launch. Enable Supabase Auth email confirmation and TOTP enrollment, deploy HTTPS and correct security headers, keep secrets out of frontend builds, verify backups, add abuse throttling at the network/API edge and configure an authorized image upload service.

PostgreSQL counters can roll back on failed requests, so they do not replace edge/IP throttling. The adapter has no payment processing, private file pipeline or audited production UI.

For the broader **marketplace** (proposals/workrooms/invites) use the hardened \`integrations/lovable-marketplace-starter\` branch with its **four** ordered migrations and full role matrix. Do not mix the two different \`002\` migrations.

No GitHub Actions workflow or security subscription is required to use these SQL controls.
