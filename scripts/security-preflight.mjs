#!/usr/bin/env node
// Dependency-free source/release guard: no third-party scanner or GitHub Actions.
import { readFileSync, existsSync, readdirSync, lstatSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { join, relative } from "node:path";

const root = fileURLToPath(new URL("../", import.meta.url));
const required = [
  "LICENSE", ".gitignore", "SECURITY.md", "docs/SECURITY_BASELINE.md",
  "supabase/migrations/001_listings.sql", "supabase/migrations/002_marketplace_core.sql",
  "supabase/migrations/003_security_baseline.sql",
  "supabase/migrations/004_invitation_onboarding.sql",
  "supabase/tests/verify_security.sql", "security/headers.template"
];
const problems = [];
for (const path of required) {
  if (!existsSync(join(root, path))) problems.push("Missing required baseline: " + path);
}
const skipDirs = new Set([".git", "node_modules", "dist", "build", "coverage", ".supabase"]);
const suspiciousPaths = /(^|\/)(\.env(?:\.[^/]+)?|credentials(?:\/|$)|secrets(?:\/|$)|[^/]+\.(?:pem|p12|pfx|key|sqlite|dump|bak))$/i;
function walk(dir) {
  for (const entry of readdirSync(dir)) {
    if (skipDirs.has(entry)) continue;
    const full = join(dir, entry);
    const rel = relative(root, full).replaceAll("\\", "/");
    const stat = lstatSync(full);
    if (stat.isSymbolicLink()) continue;
    if (stat.isDirectory()) { walk(full); continue; }
    if (rel === ".env.example") continue;
    if (suspiciousPaths.test(rel)) problems.push("Potential sensitive file: " + rel);
    if (stat.size > 1024 * 1024) continue;
    if (!/\.(?:ts|tsx|js|mjs|json|md|sql|yml|yaml|txt|example)$/i.test(rel)) continue;
    const data = readFileSync(full, "utf8");
    if (/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/.test(data))
      problems.push("Private key material: " + rel);
    if (/\bservice_role\s*[:=]\s*['"]?eyJ[A-Za-z0-9._-]{40,}/.test(data))
      problems.push("Potential service-role credential: " + rel);
  }
}
walk(root);
const hardening = existsSync(join(root, "supabase/migrations/003_security_baseline.sql"))
  ? readFileSync(join(root, "supabase/migrations/003_security_baseline.sql"), "utf8") : "";
for (const token of ["'aal2'","marketplace_consume_limit","for update","drop policy if exists media_insert"])
  if (!hardening.includes(token)) problems.push("Hardening gate missing: " + token);
if (problems.length) {
  console.error("SECURITY PRE-FLIGHT FAILED\n" + problems.map(p => " - " + p).join("\n"));
  process.exitCode = 1;
} else {
  console.log("Static source preflight passed. SQL/runtime/auth/headers still require live testing.");
}
