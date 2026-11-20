# White-label Marketplace Starter — v0.1.0 Beta 1

**First public preview | MIT licensed | Lovable + Supabase/PostgreSQL reference scaffold**

Start a brand-neutral two-sided marketplace for requests, offers, and managed engagements. This release deliberately supplies reusable architecture and security controls **without assuming a particular company, industry, visual brand, payment provider, or hosting tier**.

## Included

- Portable catalog: tenants, categories, listings, fixed/range/open budgets, searchable public discovery and draft-to-publication review
- Marketplace model: provider proposals, atomic acceptance into a single engagement, participant-scoped messages, revisions and deliverable metadata
- White-label setup: editable product name, logo URLs, terminology, CSS tokens, navigation, themes and feature switches
- Supabase baseline: PostgreSQL row-level security, ownership/tenant isolation, immutable listing provenance, AAL2 MFA-gated moderation, guarded state transitions and transaction-safe proposal acceptance
- Abuse controls: SQL-level per-account limits for selected successful actions, one-time short-lived hashed membership invitations and denied unvetted browser media mutations
- Adoption kit: `LOVABLE_PROMPT.md`, TypeScript clients, migration files, architecture/user-flow docs, security checklist, manual acceptance matrix and source preflight script

## Quick adoption

1. Create a **new development Supabase project** and enable Supabase Auth, email verification and TOTP MFA.
2. Apply exactly these migrations **in order**:
   - `supabase/migrations/001_listings.sql`
   - `supabase/migrations/002_marketplace_core.sql`
   - `supabase/migrations/003_security_baseline.sql`
   - `supabase/migrations/004_invitation_onboarding.sql`
3. Run `node scripts/security-preflight.mjs` locally and execute `supabase/tests/verify_security.sql` against that development database.
4. Give Lovable this tagged source and `LOVABLE_PROMPT.md`; integrate the client adapters and customize `src/config/site-config.ts`.
5. Complete real-user authorization/MFA, cross-tenant, concurrency and accessibility testing using `docs/ACCEPTANCE.md` before launch.

## Scope and safety

**Beta scaffold, not a ready-to-run application or security certification.** This release has not been validated against an actual Supabase tenant or deployed Lovable UI in this work session. The database tests, authenticated role testing, concurrency testing and runtime deployment checks are **pending**. There is no generated React application, installer, built distribution bundle or claim of successful third-party integrations.

Untrusted file uploads, public inquiry intake, document delivery and payments remain intentionally **disabled** pending trusted server functions, private storage policies, malware scanning, provider onboarding and financial reconciliation. An HTTP security-header **template** is included, but the host must apply and verify real headers; SQL rate caps do not replace an edge/WAF. No API keys or secrets are shipped.

## What to download

Use the auto-generated **Source code (zip)** archive attached to this GitHub release. It contains the complete white-label Lovable marketplace starter from this tag.

Do **not** substitute the repository's `main` branch or the plain `integrations/lovable` branch for this release, as their schemas and migration sequences differ.

License: MIT, © 2026 RawPowered. Retain the license notice when redistributing. See `docs/SECURITY_BASELINE.md` and `docs/RELEASE_CHECKLIST.md`.
