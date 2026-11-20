# Portable Listings Module — Replit Adapter

Use **Replit Agent** to turn this repository into a full-stack listing management application. This branch contains a portable Supabase/PostgreSQL backend schema, a TypeScript client, and Replit-specific integration prompts.

## Start here

1. [REPLIT_SETUP.md](REPLIT_SETUP.md): Replit onboarding and environment variables.
2. [REPLIT_PROMPT.md](REPLIT_PROMPT.md): Copy/paste the implementation brief into Replit Agent.
3. [supabase/migrations/001_listings.sql](supabase/migrations/001_listings.sql): PostgreSQL tables, row-level access controls, publishing restrictions and workspace bootstrap.
4. [src/lib/listings.ts](src/lib/listings.ts): typed Supabase client operations.
5. [docs/SECURITY.md](docs/SECURITY.md): launch verification and abuse-prevention gates.

**No one-click installation is claimed.** A Replit Agent must generate the UI, wire authentication, configure environment variables, and validate the resulting application. The database migration must be run on a Supabase project. Do not expose the service-role key client-side.

## Related branches
- [main](https://github.com/RawPowered/listings-module-thasit-port-open-source/tree/main): common platform contract.
- [integrations/lovable](https://github.com/RawPowered/listings-module-thasit-port-open-source/tree/integrations/lovable): Lovable-oriented instruction set.

## Provenance
Independent reconstruction of a portable listings concept inspired by Thasit; not an extracted copy of inaccessible private source. License: MIT.
