# Brand and vocabulary configuration

The starter ships **without a logo, color identity, company name, proprietary illustrations or mandated component framework**. Edit `src/config/site-config.ts` when adopting it. Keep company names and page copy out of SQL, API policies and access-control checks.

1. Set your public product name, tagline, logo/favicons and support/legal pages. Brand assets are **public**; never put private documents in the public asset bucket.
2. Replace theme colors and font stacks. Map provided CSS variables into an existing design system rather than replacing existing host components.
3. Adjust radius and apply dark/light mode tokens. Test real contrast, touch targets, focus indicators and reduced motion against WCAG 2.2 AA.
4. Change vocabulary centrally: a listing can be a job, request, brief, gig or project; provider can mean editor, contractor or consultant. Authorization must depend on user IDs and record relationships, not display labels.
5. Customize navigation, metadata, social previews, onboarding and email templates. Use true empty/loading/error states and do not invent testimonials or balances.
6. Leave payments disabled until a trusted backend and reconciliation pipeline exist.

**Optional vocabulary presets**: (Request, Provider, Proposal); (Brief, Editor, Offer); (Job, Contractor, Bid); (Project, Specialist, Quote).

Brand configuration changes must not require database migrations or change protected business logic. Website theme flexibility does not override security, privacy or accessibility.
