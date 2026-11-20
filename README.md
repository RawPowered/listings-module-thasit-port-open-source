# Portable Listings Module

**Open-source listing management foundation inspired by the Thasit Listings concept.** Bring listings, categories, images, moderation and inquiries into a custom platform without adopting the whole Thasit application.

> **Provenance:** This is an independent portable implementation, not an exact source-code extraction. The Thasit Listings implementation was not located in the currently accessible source trees. No private Thasit code, credentials or customer data has been published.

## Choose your integration

| Branch | Target | Integration |
| --- | --- | --- |
| `main` | Custom PHP platforms | PDO library + MySQL / SQLite DDL, host-provided authentication |
| `integrations/lovable` | Lovable + Supabase | PostgreSQL migration with RLS, React/TypeScript client and builder instructions |
| `integrations/replit` | Replit / Node | Standalone Express + SQLite starter and builder instructions |

### Scope

Listing lifecycle (draft → review → published → archived), multi-tenant IDs, categories, filtering, media references, configurable attributes, and guarded inquiries. **No payment processing, escrow, messaging service, image processing or hosting service is bundled.**

### Portability rules

- Authentication, authorization and tenant resolution belong to the host.
- Never trust tenant, owner, role, or publication state from public request bodies.
- Public views must only expose published, public records; inquiries require abuse controls.
- Use price in integer minor currency units. Render all user-provided text safely.
- The API contract in `contracts/` applies to other stacks; adapters are reference implementations, not guaranteed drop-ins.

See `docs/PORTABILITY.md` and the relevant integration branch for instructions. Contributions are welcome after security and compatibility review.

## License

MIT. © RawPowered.
