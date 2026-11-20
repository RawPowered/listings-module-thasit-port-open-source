import type { SupabaseClient } from "@supabase/supabase-js";

export type ListingStatus = "draft" | "pending" | "published" | "archived";
export type ListingVisibility = "public" | "unlisted" | "private";
export type BudgetMode = "open" | "fixed" | "range";
export type Listing = {
  id: string; tenant_id: string; owner_id: string; category_id: string | null;
  title: string; slug: string; summary: string; description: string;
  listing_type: string; status: ListingStatus; visibility: ListingVisibility;
  price_minor: number | null; budget_mode: BudgetMode;
  budget_max_minor: number | null; proposal_deadline: string | null;
  currency: string; location_label: string;
  latitude: number | null; longitude: number | null;
  attributes: Record<string, string | number | boolean | null>;
  created_at: string; updated_at: string; published_at: string | null;
};
export type ListingInput = Pick<Listing, "title" | "summary" | "description" | "listing_type" | "visibility" | "price_minor" | "currency" | "location_label" | "latitude" | "longitude" | "attributes"> & {
  category_id?: string | null;
  budget_mode?: BudgetMode;
  budget_max_minor?: number | null;
  proposal_deadline?: string | null;
};
export type BrowseFilter = { q?: string; type?: string; categoryId?: string; minPriceMinor?: number; maxPriceMinor?: number; page?: number; perPage?: number };

export function listingsClient(db: SupabaseClient) {
  return {
    async createWorkspace(name: string, slug: string): Promise<string> {
      const { data, error } = await db.rpc("create_listings_workspace", { p_name: name, p_slug: slug });
      if (error) throw error;
      return data as string;
    },
    async myWorkspaces() {
      const { data, error } = await db.from("listing_memberships").select("tenant_id,role,listing_tenants(id,name,slug)").order("created_at");
      if (error) throw error;
      return data;
    },
    async browse(filters: BrowseFilter = {}) {
      const page = Math.max(1, Math.trunc(filters.page ?? 1));
      const perPage = Math.max(1, Math.min(50, Math.trunc(filters.perPage ?? 20)));
      let query = db.from("listings").select("*,listing_media(media_url,alt_text,sort_order)", { count: "exact" })
        .eq("status", "published").eq("visibility", "public");
      if (filters.q?.trim()) {
        const q = filters.q.trim().replace(/[,%()]/g, " ").slice(0, 100);
        query = query.or(`title.ilike.%${q}%,summary.ilike.%${q}%`);
      }
      if (filters.type) query = query.eq("listing_type", filters.type);
      if (filters.categoryId) query = query.eq("category_id", filters.categoryId);
      if (filters.minPriceMinor !== undefined) query = query.gte("price_minor", filters.minPriceMinor);
      if (filters.maxPriceMinor !== undefined) query = query.lte("price_minor", filters.maxPriceMinor);
      const { data, error, count } = await query.order("created_at", { ascending: false })
        .range((page - 1) * perPage, page * perPage - 1);
      if (error) throw error;
      return { items: (data ?? []) as Listing[], total: count ?? 0, page, perPage };
    },
    async published(slug: string, tenantId: string) {
      const { data, error } = await db.from("listings").select("*,listing_media(media_url,alt_text,sort_order)")
        .eq("tenant_id", tenantId).eq("slug", slug).eq("status", "published").eq("visibility", "public").maybeSingle();
      if (error) throw error;
      return data;
    },
    async mine(tenantId: string) {
      const { data: user, error: authError } = await db.auth.getUser();
      if (authError || !user.user) throw authError ?? new Error("Sign in required");
      const { data, error } = await db.from("listings").select("*").eq("tenant_id", tenantId).eq("owner_id", user.user.id).order("updated_at", { ascending: false });
      if (error) throw error;
      return data as Listing[];
    },
    async create(tenantId: string, input: ListingInput) {
      const { data: user, error: authError } = await db.auth.getUser();
      if (authError || !user.user) throw authError ?? new Error("Sign in required");
      const budgetMode: BudgetMode = input.budget_mode ??
        (input.price_minor === null ? "open" : input.budget_max_minor != null ? "range" : "fixed");
      const { data, error } = await db.from("listings").insert({
        ...input,
        budget_mode: budgetMode,
        budget_max_minor: input.budget_max_minor ?? null,
        proposal_deadline: input.proposal_deadline ?? null,
        tenant_id: tenantId,
        owner_id: user.user.id,
        status: "draft"
      }).select().single();
      if (error) throw error;
      return data as Listing;
    },
    async update(id: string, tenantId: string, patch: Partial<ListingInput>) {
      const { data, error } = await db.from("listings").update(patch).eq("id", id).eq("tenant_id", tenantId).select().single();
      if (error) throw error;
      return data as Listing;
    },
    async submit(id: string, tenantId: string) {
      const { data, error } = await db.from("listings").update({ status: "pending" }).eq("id", id).eq("tenant_id", tenantId).select().single();
      if (error) throw error;
      return data as Listing;
    },
    async moderate(id: string, tenantId: string, status: "published" | "archived") {
      const { data, error } = await db.from("listings").update({ status }).eq("id", id).eq("tenant_id", tenantId).select().single();
      if (error) throw error;
      return data as Listing;
    }
  };
}
