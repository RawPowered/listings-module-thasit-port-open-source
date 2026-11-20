/** Public white-label configuration; never put API credentials or private keys here. */
export type MarketplaceTerms = {
  listingSingular: string; listingPlural: string; requester: string;
  provider: string; proposal: string; engagement: string; delivery: string;
};
export type MarketplaceSiteConfig = {
  branding: {
    name: string; tagline: string; logoUrl: string | null; faviconUrl: string | null;
    primary: string; accent: string; background: string; surface: string; text: string;
    fontBody: string; fontHeading: string; radius: "sharp" | "soft" | "rounded";
  };
  terms: MarketplaceTerms;
  capabilities: {
    proposals: boolean; messaging: boolean; deliverables: boolean;
    reporting: boolean; reviews: boolean; payments: boolean;
  };
  navigation: Array<{ label: string; href: string; auth?: boolean }>;
};
export const siteConfig: MarketplaceSiteConfig = {
  branding: {
    name: "Your Marketplace", tagline: "Connect requests with people who can help",
    logoUrl: null, faviconUrl: null, primary: "#354054", accent: "#607087",
    background: "#F8F9FB", surface: "#FFFFFF", text: "#17202C",
    fontBody: "system-ui, sans-serif", fontHeading: "system-ui, sans-serif",
    radius: "soft"
  },
  terms: {
    listingSingular: "Request", listingPlural: "Requests",
    requester: "Requester", provider: "Provider",
    proposal: "Proposal", engagement: "Workroom", delivery: "Delivery"
  },
  capabilities: {
    proposals: true, messaging: true, deliverables: true, reporting: true,
    reviews: false, payments: false
  },
  navigation: [
    { label: "Explore", href: "/listings" },
    { label: "My requests", href: "/dashboard/listings", auth: true },
    { label: "My work", href: "/dashboard/work", auth: true }
  ]
};
const safeHex = (value: string) => /^#[0-9a-fA-F]{6}$/.test(value) ? value : "#354054";
export function brandVariables(config = siteConfig): Record<string, string> {
  const b = config.branding;
  return {
    "--brand-primary": safeHex(b.primary), "--brand-accent": safeHex(b.accent),
    "--brand-bg": safeHex(b.background), "--brand-surface": safeHex(b.surface),
    "--brand-text": safeHex(b.text),
    "--brand-radius": b.radius === "sharp" ? "0px" : b.radius === "rounded" ? "16px" : "8px"
  };
}
