# Replit quick adoption

This branch shares the **same Supabase/PostgreSQL backend and RLS model** as the Lovable adapter. Replit is suitable for an integrated app build via Replit Agent; no PHP runtime is required.

1. In Replit, use **Import from GitHub** (supported by Replit's official Git integration) or create an app and supply the repository URL to Agent. When importing, select the `integrations/replit` branch, not the default `main` branch.
2. Point Replit Agent to `REPLIT_PROMPT.md` and `LOVABLE_PROMPT.md`; have it generate the React UI and data wiring using `src/lib/listings.ts`.
3. Connect Supabase and apply `supabase/migrations/001_listings.sql` and then `supabase/migrations/002_listings_security_baseline.sql` in a reviewed development Supabase SQL editor.
4. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` for client code using the environment UI. A public anon/publishable key is acceptable in client apps **only with RLS enabled**; never add a service-role key to client code.
5. Sign in, create a workspace with `create_listings_workspace`, enroll and challenge TOTP MFA to obtain AAL2, create/submit a draft, then publish as the MFA-verified owner.
6. Verify cross-tenant data access is rejected. Only deploy after testing all permissions and media/inquiry integration boundaries.

This is an agent-ready scaffold and data adapter, **not** a verified one-click Replit deployment. The app's actual runtime, auth UI, and domain hosting are created by Replit Agent using the prompt.

For arbitrary Node/Express backends, implement the operations in `docs/PORTABILITY.md` with server-side access checks.

**Security gate:** apply both migrations, check [docs/SECURITY_BASELINE.md](docs/SECURITY_BASELINE.md), run [SQL assertions](supabase/tests/verify_security.sql), and verify in real authenticated sessions. Do not enable arbitrary image URL insertion, public inquiries or file uploads by default.
