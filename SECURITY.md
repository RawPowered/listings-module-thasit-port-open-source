# Security disclosure and supported starter

For potential security vulnerabilities, use GitHub's private vulnerability reporting feature when available. Do not create a public issue with an exploit, credential or customer data. This repository is a **starter** and not an independently audited, hosted application.

The white-label Lovable marketplace starter's ordered security migrations live at:
\`integrations/lovable-marketplace-starter/supabase/migrations/001...004\`.

**Deployment security is not automatic merely by cloning.** Apply the migrations and execute their acceptance checks in a fresh controlled Supabase project. Also configure Auth, MFA enrollment, hosting headers, storage and operational controls. See \`docs/SECURITY_BASELINE.md\` in the branch.

Do not commit production keys, service-role credentials, personal files or private proprietary code. The MIT license does not grant rights to third-party libraries or assets.
