# Security baseline — what the starter enforces and what remains

**Audience:** anyone deploying this MIT-licensed, white-label, Lovable/Supabase starter.

## Deployment contract

1. Work in an isolated **development** Supabase project that you control. Review and apply migrations **001, 002, 003 and 004 in order**. Do not apply blindly to an existing production schema.
2. Run \`supabase/tests/verify_security.sql\` in the SQL editor. Stop for any failure; the results only verify static database gates.
3. In Supabase Auth configure email verification, email rate limits, allowed redirect URLs, secure session/recovery settings, and MFA (TOTP). **Workspace owners/admins must enroll and verify MFA to reach AAL2 before moderation, category edits or invitations work.** The starter does not enroll a user automatically.
4. Initialize the frontend with the Supabase **publishable** key only. Never ship a service-role key, database password, webhook signing key or private token to browser code or a public build.
5. Keep arbitrary media upload/URL insertion, protected-file delivery, public inquiry intake, and payments **disabled** until separately implemented with verified backend security and abuse safeguards. The absence of an upload button does not substitute for backend rules.
6. Configure hosting-side TLS, headers and CSP with \`security/headers.template\`; replace placeholders and verify against the actual generated Lovable build. File alone does not set HTTP headers in every hosting provider.
7. Configure error monitoring, backup restore drills, dependency updates, secret scanning and incident response before handling real accounts. No GitHub Actions workflows are required.

## Enforced **after running the migrations**

| Control | Enforced by | Limit |
| --- | --- | --- |
| Tenant ownership and protected publication | 001 and stricter 003 listing trigger/RLS | Assumes valid Supabase Auth sessions |
| AAL2 verified MFA for privileged moderator actions | 003 override of \`listings_can_moderate\` | Needs actual Auth MFA enrollment flow |
| Immutable listing identity/timestamps, pending-only publication | 003 listing trigger | Does not replace content safety review |
| No direct proposal/engagement/event state modification | 002 RLS + 003 explicit grants | Requires tests against actual deployed roles |
| Race-safe proposal acceptance and no late proposals | 003 listing lock and unique engagement constraint | Need live concurrency test |
| Membership-gated workroom and proposal reads | 003 RLS helper and policies | Membership revocation UX and legal retention still need design |
| Rate caps for successful proposals, messages, reports, workspace creation | 003 database counters/triggers/RPC | **Not** an IP firewall or failed-request rate limiter; aborted SQL transactions roll back counters |
| Default deny browser uploads/external media writes | 003 removed media mutation policies | Existing external media URLs must still be audited |
| One-use, hashed, short-lived membership invites | 004 RPCs + RLS | Invites must be distributed privately; cannot replace email verification |
| Disabled public inquiry and delivery RPC | 001/002/003 privilege boundaries | Dedicated server functions needed before enablement |

## Enrollment and invite user journey

A new account can create a workspace, but it **cannot moderate** until its session is upgraded to MFA AAL2. After MFA enrollment and challenge, create a single-use membership invitation with \`marketplace_issue_invitation\`. Share the opaque token privately, never log it or include it in analytics/query strings. The new authenticated user redeems with \`marketplace_redeem_invitation\`. That user gets the \`member\` role only. Neither self-join nor self-promotion exists.

**Important:** token validation and some rejected API requests raise an exception, which rolls back PostgreSQL transaction counters. Add external API/IP-level throttling (gateway/Edge Function/WAF) to resist brute-force and unauthenticated floods. 256-bit tokens are intentionally not guessable.

## Sensitive file workflows

Files are **not** enabled by the starter. Before enabling, use a private Supabase Storage bucket, enforce storage-object RLS tied to verified participant identity, verify upload ownership and object existence server-side, enforce MIME/extension/size limits, scan untrusted uploads, and serve short-lived authenticated downloads. Never trust client-supplied \`storage_key\`; deliverable registration RPC is intentionally not callable by \`authenticated\`.

## Payments and compliance

No financial controls are asserted here. If a payment processor is connected, implement verified webhooks, idempotency, a reconciliation ledger, disputes/refunds, webhook replay protection and role-separated financial operations. No escrow/held-funds claims without a permitted product and legal review.

## Residual risks and explicit nonclaims

This is **not** a penetration test, complete audit, secure Lovable deployment guarantee, automated CAPTCHA, device attestation, malware scanning, provider KYC or payment compliance. Database migrations enforce a strong baseline, but each deployment must verify its real auth, hosting and client generated code. Run \`node scripts/security-preflight.mjs\` before publishing code.
