# Acceptance and release gates

**Not yet executed.** Run migrations 001–004, then `supabase/tests/verify_security.sql` in an isolated Supabase project with at least two tenants, multiple members, a moderator at AAL1 and at AAL2. Structural SQL assertions are not a substitute for role tests.

| Test | Expected |
| --- | --- |
| Anonymous browse | Only published/public listings |
| Member drafts and updates | Own records only |
| Non-moderator publish | Denied |
| Owner/admin publish before MFA | Denied at AAL1 |
| Owner/admin publish after MFA enrollment and challenge | Allowed at AAL2, pending listing only |
| Owner/admin skip pending approval | Denied |
| Client tampers with created_at or published_at | Rejected or server-controlled |
| Provider changes accepted listing scope | Rejected |
| Client writes arbitrary listing-media URL | Denied |
| 31 messages from one sender inside a minute | Capped by DB counter |
| Repeated report creation by same account | Capped by DB counter |
| Self-enroll as tenant admin or owner | Denied |
| Single-use member invite redemption | First authorized account gets member role, replay fails |
| Expired token, wrong format | Invalid (null), no elevated role |
| Cross-tenant listing proposal | Denied |
| Proposal by listing owner | Denied |
| Proposal on draft or archived listing | Denied |
| Direct proposal acceptance UPDATE | Denied |
| Two simultaneous accept attempts | At most one engagement |
| Requester marks provider delivery | Denied |
| Provider marks requester's completion | Denied |
| Third party reads work messages | Denied |
| Third party reads deliverable metadata | Denied |
| Member self-elevates to moderator | Denied |
| Anonymous reports and messages | Denied |
| Arbitrary direct state edits | Denied |
| Dark/light/mobile rebranding | Correct tokens, labels, contrast, no hardcoded identity |
| Payments without provider | Disabled; no bogus successful statuses |

Before launch: add private bucket policies and upload/download handlers; test file scanning, retention, rate limits, abuse handling, accessibility, backups/restore, notifications, idempotency, payment webhooks/refunds (if enabled), and security monitoring. Have migrations and RLS reviewed independently.

**Run these tests on the *real deployed roles* via signed-in clients.** Also verify tenant removal immediately revokes private workroom access, a withdrawn proposal cannot be accepted, and independent browser sessions do not bypass rate caps. Test concurrent proposals and acceptances using separate connections. Configure per-IP/edge request throttling for failed attempts and unauthenticated surfaces; in-DB counters roll back with failed transactions.
