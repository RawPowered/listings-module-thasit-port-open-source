# Portable Listings Module

Open-source, platform-neutral **listing management foundation** inspired by the Thasit Listings concept. This is an independent implementation, not an exact export of private Thasit code.

## Choose an integration

| Branch | Use |
| --- | --- |
| `main` | Portable listing schema and backend contract for custom platforms |
| [`integrations/lovable`](../../tree/integrations/lovable) | Supabase/Postgres RLS, typed Lovable client and build prompt |
| [`integrations/replit`](../../tree/integrations/replit) | Replit starter and integration instructions |

This repository defines tenants, categories, listings, image references, publication review, filters, and guarded inquiries. Host platforms must provide identity, permissions, upload validation, abuse prevention and deployment.

See [Portability guide](docs/PORTABILITY.md), [JSON Schema](contracts/listing.schema.json), and the platform branch instructions. Never treat an adapter as a production-ready one-click installer.

MIT © RawPowered.