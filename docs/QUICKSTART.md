# Quickstart — White-label Lovable Marketplace Starter

This release is a **source-and-database starter**, not a one-click application installer. Use a dedicated, controlled Supabase development project.

## 1. Pick your branch/archive

Use the frozen source branch `releases/marketplace-lovable-v0.1.0-beta.1` (GitHub: Code → Download ZIP), or a GitHub Release created from that exact branch. The top-level `main` branch does not contain this schema. The GitHub Release/tag is not yet published.

## 2. Establish authentication

Create a Supabase project under your control. Configure allowed redirect URLs, email confirmation and TOTP MFA. Use only the public publishable/anon key in the browser; keep elevated credentials in server-side secrets. The initial workspace owner needs AAL2 before it can moderate.

## 3. Apply migrations to a new dev database

In the Supabase SQL editor, **review then run**:

1. `supabase/migrations/001_listings.sql`
2. `supabase/migrations/002_marketplace_core.sql`
3. `supabase/migrations/003_security_baseline.sql`
4. `supabase/migrations/004_invitation_onboarding.sql`

Stop on SQL errors; don't mix the listings-only adapter's different `002` migration with this branch.

## 4. Confirm the baseline

From the downloaded source directory run `node scripts/security-preflight.mjs`. Run `supabase/tests/verify_security.sql` in the SQL editor. Perform the cross-account scenarios in `docs/ACCEPTANCE.md` with *actual signed-in test accounts*. Keep proofs of any failures; do not bypass policies for testing.

## 5. Generate the Lovable frontend

In Lovable, supply `LOVABLE_PROMPT.md`, the tagged source URL and `src/lib/listings.ts`/`src/lib/marketplace.ts`. Preserve the existing host theme, if any. Keep unimplemented integrations visibly disabled.

## 6. Change the branding

Edit `src/config/site-config.ts` for product name, language, logo URLs, primary/accent colors, fonts and navigation. See `docs/BRANDING.md`. These edits must not change authorization or payment state logic.

## 7. Secure deployment before live users

Apply and verify your provider's TLS, CSP, security headers, domain settings, backups and edge rate limiting. **Never** turn on private manuscript uploads, payouts, or public contact forms before their trusted server protections and acceptance tests exist.

This starter does not include an operational site, generated UI, verified payment gateway or tenant deployment.
