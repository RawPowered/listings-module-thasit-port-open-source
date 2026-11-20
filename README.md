# White-label Marketplace Starter — Lovable

Brand-neutral marketplace architecture for requests, proposals, collaborations, and supervised completion. This branch derives from the portable listings Lovable adapter; it is not dedicated to any particular industry, product, company, theme, or payment service.

## Use it

1. Start with your own development Supabase project, with Auth enabled and an externally accessible SQL editor.
2. Apply `supabase/migrations/001_listings.sql` then `supabase/migrations/002_marketplace_core.sql` in order. **Do not apply to an unreviewed production database.**
3. Copy `src/lib/listings.ts`, `src/lib/marketplace.ts`, `src/config/site-config.ts`, and `src/styles/brand-tokens.css` into your Lovable project.
4. Configure your product's **name, logo, colors, fonts, terminology, navigation and features** in `src/config/site-config.ts`; see `docs/BRANDING.md`.
5. Provide Lovable `LOVABLE_PROMPT.md` and this branch URL. Existing host design systems should be preserved.
6. Run the negative and positive tests in `docs/ACCEPTANCE.md`, including multi-user, cross-tenant and concurrency scenarios.

**Status: architecture, SQL and adapter scaffold, not a running app or production security certification.** The consuming app must supply React views, Supabase client initialization, authenticated onboarding, notification delivery, private file storage policy, abuse/rate controls, and any real payment integration.

### Included

- Listings, categories, tenant memberships, moderation, and RLS from the Lovable adapter
- Fixed, range and open budget configuration
- Proposals, one accepted engagement per listing, guarded lifecycle RPCs
- Participant-only messaging, deliverable metadata and revision requests
- Reports and server-written event records
- Plain visual tokens and configurable terminology for any industry

### Intentionally not included

No hardcoded brand, image assets, UI library, payment processor, wallet, escrow, public document uploads, provider verification, or claims of ready-to-launch security. Set the payments feature to disabled until a real trusted integration is implemented.

Docs: [Architecture](docs/ARCHITECTURE.md) · [Flows](docs/FLOWS.md) · [Branding](docs/BRANDING.md) · [Acceptance](docs/ACCEPTANCE.md).

MIT. The branch is an independent generic starter, not a private code export.
