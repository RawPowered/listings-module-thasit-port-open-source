# Acceptance and release gates

**Not yet executed**. Test in an isolated Supabase project with at least two distinct tenants, two members per tenant and a tenant moderator.

| Test | Expected |
| --- | --- |
| Anonymous browse | Only published/public listings |
| Member drafts and updates | Own records only |
| Non-moderator publish | Denied |
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
