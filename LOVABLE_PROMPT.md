# Paste into Lovable: white-label marketplace foundation

Use this branch as the authoritative **generic** marketplace scaffold. It is not tied to any business or editorial industry. Work with a project-connected external Supabase database; use existing app auth/theme/components if present. Do not hardcode a brand. Read README.md, docs/ARCHITECTURE.md, docs/FLOWS.md, docs/BRANDING.md and docs/ACCEPTANCE.md.

## Database

Apply supplied SQL migrations in order (001, then 002) **only to a reviewed development project**. Use existing src/lib/listings.ts and new src/lib/marketplace.ts. Do not reinvent tables or disable RLS. Never use service_role in browser. Never expose private file URLs.

## UI routes

- /: configurable landing page using site-config name, logo, terminology and themes.
- /listings: published public listing catalog with filters, pagination, accessibly labeled cards.
- /listings/:slug: detail and proposal submission for eligible authenticated providers.
- /dashboard/listings: create/edit drafts, set fixed/range/open budget, submit for moderation, archive.
- /dashboard/proposals: provider offers, status, withdraw or update while submitted.
- /dashboard/work: requester and provider engagement list.
- /dashboard/work/:id: private messages, delivery submission, revision request and completion.
- /dashboard/moderation: tenant owner/admin listing review and report queue; do not invent fake case outcomes.
- /settings/branding: owner-facing form backed by a **separately implemented privileged and validated settings persistence layer** (until implemented, offer local preview and export only).

Use responsive layouts, semantic controls, keyboard flows, loading/empty/error states, dark/light/reduced-motion settings, and CSS tokens from src/styles/brand-tokens.css. Use src/config/site-config.ts for logo, colors, fonts and displayed terms. Do not create fake user data, reviews, balances, payouts or working integrations.

## Safety and integration boundaries

The SQL lifecycle RPCs are authoritative, not the visible buttons. Do not add a client query that modifies engagement status or payment state directly. Use private bucket and signed URL service with participant authorization for documents; until integrated, disable upload and show the reason. Rate limit proposals/messages server-side before launch. Payments are not built: do not show escrow, held balance, successful payment or payout without connected trusted provider APIs/webhooks. Reports need a real staff escalation procedure. Open-join workspaces are **not** supplied: use owner-controlled onboarding/invites implemented separately.

Return the generated React views, real Supabase wiring, a list of inactive integrations, and an executed verification checklist. Preserve existing app design system and current branding when integrating.
