# Security and acceptance

## Deployment boundary

- Apply migration with a privileged SQL editor; **never** from frontend code.
- Auth uses Supabase Auth. `tenant_id` is resolved by selected membership and independently checked by RLS.
- Workspace bootstrap creates its initial owner membership transactionally.
- Users cannot assign themselves moderator permissions through membership mutations.
- Members can edit their listings, but the DB trigger bars self-publishing and moving ownership/tenant.
- Public reads require both `status = 'published'` and `visibility = 'public'`.
- Anonymous inquiry INSERT is intentionally denied; add consent, rate limiting, CAPTCHA and server-side filtering first.
- HTTPS media URLs are references; host must implement validated uploads and storage policies separately.

## Verify before launch

1. An anonymous visitor can read published public listings, but not drafts or private listings.
2. An authenticated member can create, edit and submit their own drafts.
3. That member **cannot** directly publish via Supabase REST or SQL exposed to the client.
4. Workspace owner can publish submitted records through the moderation page.
5. A member of tenant A cannot read tenant B drafts or update tenant B records.
6. No anonymous or authenticated user can write directly to `listing_inquiries`.
7. UI uses plain text, not raw HTML, and fails closed when Supabase rejects an operation.
8. Inspect every table's RLS configuration after migration. Run on a disposable Supabase project first.

This reference does not replace a production penetration test or a legal/compliance review.


Apply the **listings-only** `002_listings_security_baseline.sql` after 001, then follow [security setup](SECURITY_BASELINE.md) and [structural SQL checks](../supabase/tests/verify_security.sql). Moderation requires TOTP MFA AAL2; arbitrary browser image URL uploads are disabled.
