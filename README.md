# White-label Marketplace Starter — Lovable

Brand-neutral marketplace architecture for requests, proposals, collaborations, and supervised completion. This branch derives from the portable listings Lovable adapter; it is not dedicated to any particular industry, product, company, theme, or payment service.

## Use it

1. Start with your own development Supabase project, with Auth and TOTP MFA enabled; keep email verification on.
2. Apply **all four ordered migrations** in `supabase/migrations/`: 001 listings, 002 marketplace, 003 security hardening, 004 invitation onboarding. **Do not apply blindly to an existing production database.**
3. Copy `src/lib/listings.ts`, `src/lib/marketplace.ts`, `src/config/site-config.ts`, and `src/styles/brand-tokens.css` into your Lovable project.
4. Configure your product's **name, logo, colors, fonts, terminology, navigation and features** in `src/config/site-config.ts`; see `docs/BRANDING.md`.
5. Provide Lovable `LOVABLE_PROMPT.md` and this branch URL. Existing host design systems should be preserved; wire MFA and invitation onboarding before exposing moderator UI.
6. Run `node scripts/security-preflight.mjs`, then `supabase/tests/verify_security.sql` in your staging database and the user/role tests in `docs/ACCEPTANCE.md`. Configure HTTP headers and hosting protections from `docs/SECURITY_BASELINE.md`.

**Status: security-hardened architecture, SQL and adapter scaffold, not a running app or production security certification.** The consuming app must supply React views, Supabase client initialization, authenticated onboarding, notification delivery, private file storage policy, abuse/rate controls, and any real payment integration.

### Included

- Listings, categories, tenant memberships, moderation, and RLS from the Lovable adapter
- Fixed, range and open budget configuration
- Proposals, one accepted engagement per listing, guarded lifecycle RPCs
- Participant-only messaging, deliverable metadata and revision requests
- Mandatory MFA-gated moderation, server-enforced rate caps, scope integrity, least-privilege grants and one-use member invitations (see `docs/SECURITY_BASELINE.md`)
- Reports and server-written event records
- Plain visual tokens and configurable terminology for any industry

### Intentionally not included

No hardcoded brand, image assets, UI library, payment processor, wallet, escrow, public document uploads, provider verification, or claims of ready-to-launch security. Set the payments feature to disabled until a real trusted integration is implemented.

Docs: [Architecture](docs/ARCHITECTURE.md) · [Flows](docs/FLOWS.md) · [Branding](docs/BRANDING.md) · [Acceptance](docs/ACCEPTANCE.md).

Security: [Day-one baseline](docs/SECURITY_BASELINE.md) · [Read-only SQL assertions](supabase/tests/verify_security.sql) · [Hosting-header example](security/headers.template).

MIT. The branch is an independent generic starter, not a private code export.
