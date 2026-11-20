# Release verification record — marketplace-lovable-v0.1.0-beta.1

## Publication state

- Frozen versioned branch: `releases/marketplace-lovable-v0.1.0-beta.1`
- **Formal GitHub Release/tag: NOT YET CREATED.** This is a release candidate snapshot. Publish a GitHub pre-release from the frozen branch using `docs/PUBLISH_GITHUB_RELEASE.md`.
- Versioned branch is publicly browsable and downloadable as a ZIP through GitHub.

## Source-level evidence

| Gate | Result | Evidence |
| --- | --- | --- |
| Public repository | Confirmed | GitHub repository metadata |
| MIT root license | Confirmed | LICENSE file present |
| Correct marketplace source branch | Confirmed | integrations/lovable-marketplace-starter |
| Four migrations ordered | Confirmed by source inspection | 001–004 in supabase/migrations |
| Security migration and AAL2 authorization | Confirmed in source | 003_security_baseline.sql |
| One-time hashed invitations | Confirmed in source | 004_invitation_onboarding.sql |
| RLS/static SQL verification script present | Confirmed | supabase/tests/verify_security.sql |
| Typed listing/proposal adapters present | Confirmed | src/lib |
| Branding configuration present | Confirmed | src/config/site-config.ts |
| Sensitive upload/payment boundaries documented | Confirmed | docs/SECURITY_BASELINE.md |
| Dev database SQL execution | **Not run** | Requires Supabase project |
| Signed-in tenant/MFA and authorization tests | **Not run** | Requires test accounts |
| Concurrency, security-header and deployment tests | **Not run** | Requires runtime |
| Production readiness/penetration test | **Not certified** | Outside this release |

## Required before public deployment

- [ ] All four migrations apply without error to a disposable Supabase instance
- [ ] Read-only SQL security assertions pass
- [ ] Anonymous, member, owner AAL1, owner AAL2 and cross-tenant checks pass
- [ ] Concurrent proposal acceptance cannot create duplicate engagements
- [ ] Host applies tested TLS/CSP/security headers
- [ ] Automated backup and restore test completed
- [ ] External request-rate/abuse controls are in place
- [ ] Private file pipeline is secure before upload controls are enabled
- [ ] Payment provider, verified webhooks and reconciliation are complete before billing is enabled
- [ ] Accessibility, error handling and operational monitoring reviewed

**Release classification:** Public developer preview of a reusable architecture scaffold, not production-ready software.
