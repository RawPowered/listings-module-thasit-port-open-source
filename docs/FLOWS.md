# User, provider and admin journeys

```mermaid
flowchart TD
  A[Sign in and join authorized workspace] --> B[Create draft request]
  B --> C[Define scope and budget]
  C --> D[Submit for review]
  D --> E{Moderator approves?}
  E -->|No| B
  E -->|Yes| F[Published request]
  F --> G[Receive proposals]
  G --> H{Requester accepts one?}
  H -->|Not yet| G
  H -->|Yes| I[Atomic acceptance and private workroom]
  I --> J[Provider sends delivery]
  J --> K{Requester decision}
  K -->|Revision| I
  K -->|Approve| L[Complete work]
  L --> M[Payment integration if separately enabled]
```

```mermaid
flowchart TD
  A[Provider registers and joins] --> B[Browse published opportunities]
  B --> C[Send price and schedule proposal]
  C --> D{Selected?}
  D -->|No| E[Edit or withdraw proposal]
  D -->|Yes| F[Private collaboration]
  F --> G[Messages and private files with external storage]
  G --> H[Deliver work]
  H --> I{Revision requested?}
  I -->|Yes| G
  I -->|No| J[Requester completes]
```

```mermaid
flowchart TD
  A[Moderator signs in] --> B[Review pending listings]
  B --> C{Approve?}
  C -->|Yes| D[Publish]
  C -->|No| E[Archive or return to owner]
  D --> F[Review reports]
  F --> G[Escalate case via independently implemented review tools]
```

## Failure branches to implement and verify

- Unauthorized publication or membership -> reject server-side.
- Proposal on own listing, closed listing or across tenants -> reject.
- Concurrent accepts -> row locking and unique engagement constraint prevent double acceptance.
- Direct updates to protected engagement states -> deny; use guarded RPCs.
- Private file upload/download -> require authenticated, tenant-scoped storage policies, validation and scanning.
- Disputes/refunds -> preserve records; use verified payment provider reconciliation, not work status as proof of payment.
- Abusive messages/reports -> rate controls, moderation and support workflows still required.
