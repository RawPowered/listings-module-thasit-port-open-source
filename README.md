# Portable Listings Module

Open-source, platform-neutral **listing management foundation** inspired by the Thasit Listings concept. This is an independent implementation, not an exact export of private Thasit code.

## Choose an integration

| Branch | Use |
| --- | --- |
| `main` | Portable listing schema and backend contract for custom platforms |
| [`integrations/lovable`](../../tree/integrations/lovable) | Supabase/Postgres RLS, typed Lovable client and build prompt |
| [`integrations/replit`](../../tree/integrations/replit) | Replit starter and integration instructions |
| [`integrations/lovable-marketplace-starter`](../../tree/integrations/lovable-marketplace-starter) | White-label request/offer marketplace with security-hardened workflows |

This repository defines tenants, categories, listings, image references, publication review, filters, and guarded inquiries. Host platforms must provide identity, permissions, upload validation, abuse prevention and deployment. **For Supabase-backed adapter builds, apply the branch-specific ordered SQL security migrations** before enabling user registration. Lovable and Replit listing adapters use migrations 001–002; the marketplace starter uses migrations 001–004. Their migration 002 files differ and must not be mixed.

See [Portability guide](docs/PORTABILITY.md), [JSON Schema](contracts/listing.schema.json), and the platform branch instructions. Never treat an adapter as a production-ready one-click installer.

Security instructions: see each adapter's `docs/SECURITY_BASELINE.md`. MFA enrollment, hosting HTTP headers, signed file access and operational abuse protections must still be configured at deployment. The repository does not contain a verified live application or complete penetration-test certificate.

MIT © RawPowered.