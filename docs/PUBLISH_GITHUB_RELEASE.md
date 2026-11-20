# Publish the GitHub pre-release (manual GitHub UI)

This repository connection does not expose GitHub's create-release mutation. The public source is already frozen in `releases/marketplace-lovable-v0.1.0-beta.1`.

1. Open [New GitHub Release](https://github.com/RawPowered/listings-module-thasit-port-open-source/releases/new).
2. Select **Choose a tag → Create new tag**: `marketplace-lovable-v0.1.0-beta.1`.
3. Set **target** to `releases/marketplace-lovable-v0.1.0-beta.1`, **not** `main`.
4. Title: `White-label Marketplace Starter v0.1.0 Beta 1 (Lovable + Supabase)`.
5. Description: paste the entire `RELEASE_NOTES.md` from this same frozen branch.
6. Select **Set as a pre-release**. Do not promote as a production-ready stable release or claim runtime security certification.
7. Click **Publish release**.
8. Confirm its tag resolves to the frozen branch commit and GitHub offers source code ZIP/TAR. Verify the four migrations are present in the downloadable archive.

Release is a developer preview of source, architecture, schemas, and security defaults; SQL authorization integration tests and app deployment checks remain pending. The generated GitHub source archives are not compiled installers.
