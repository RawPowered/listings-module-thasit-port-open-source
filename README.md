# Portable Listings Module — Replit Adapter

Use **Replit Agent** to turn this repository into a full-stack listing management application. This branch contains a portable Supabase/PostgreSQL backend schema, a TypeScript client, and Replit-specific integration prompts.

## Start here

1. [REPLIT_SETUP.md](REPLIT_SETUP.md): Replit onboarding and environment variables.
2. [REPLIT_PROMPT.md](REPLIT_PROMPT.md): Copy/paste the implementation brief into Replit Agent.
3. Apply [001_listings.sql](supabase/migrations/001_listings.sql), then [002_listings_security_baseline.sql](supabase/migrations/002_listings_security_baseline.sql). They establish RLS, MFA-gated publishing, immutable provenance and secure media defaults.
4. [src/lib/listings.ts](src/lib/listings.ts): typed Supabase client operations.
5. [docs/SECURITY_BASELINE.md](docs/SECURITY_BASELINE.md) and [supabase/tests/verify_security.sql](supabase/tests/verify_security.sql): deployment and permission checks.

**No one-click installation is claimed.** A Replit Agent must generate the UI, wire authentication, configure environment variables, and validate the resulting application. The database migration must be run on a Supabase project. Do not expose the service-role key client-side.

Owners/admins must enroll and challenge TOTP MFA to reach AAL2 before moderation works. Unvetted media inserts remain disabled. An API-edge rate limiter and verified file service are still required for public launch.

## Related branches
- [main](https://github.com/RawPowered/listings-module-thasit-port-open-source/tree/main): common platform contract.
- [integrations/lovable-marketplace-starter](https://github.com/RawPowered/listings-module-thasit-port-open-source/tree/integrations/lovable-marketplace-starter): full white-label marketplace starter.
- [integrations/lovable](https://github.com/RawPowered/listings-module-thasit-port-open-source/tree/integrations/lovable): Lovable-oriented instruction set.

## Provenance
Independent reconstruction of a portable listings concept inspired by Thasit; not an extracted copy of inaccessible private source. License: MIT.
