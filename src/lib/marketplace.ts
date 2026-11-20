import type { SupabaseClient } from "@supabase/supabase-js";
/** Typed, user-context operations. Protected state transitions are database RPCs. */
export type Proposal = {
  id: string; tenant_id: string; listing_id: string; provider_id: string;
  amount_minor: number | null; currency: string; message: string;
  estimated_days: number | null;
  status: "submitted" | "withdrawn" | "accepted" | "declined";
};
export type Engagement = {
  id: string; tenant_id: string; listing_id: string; proposal_id: string;
  requester_id: string; provider_id: string;
  status: "active" | "delivered" | "completed" | "cancelled" | "disputed";
};
export function marketplaceClient(db: SupabaseClient) {
  async function rpc<T>(name: string, args: Record<string, unknown>): Promise<T> {
    const { data, error } = await db.rpc(name, args);
    if (error) throw error;
    return data as T;
  }
  return {
    proposalsForListing: async (tenantId: string, listingId: string): Promise<Proposal[]> => {
      const { data, error } = await db.from("marketplace_proposals").select("*")
        .eq("tenant_id", tenantId).eq("listing_id", listingId).order("created_at", { ascending: false });
      if (error) throw error; return (data ?? []) as Proposal[];
    },
    submitProposal: (tenantId: string, listingId: string, amountMinor: number | null, message: string, estimatedDays: number | null = null) =>
      rpc<string>("marketplace_submit_proposal", { p_tenant: tenantId, p_listing: listingId, p_amount: amountMinor, p_message: message, p_days: estimatedDays }),
    withdrawProposal: (tenantId: string, proposalId: string) =>
      rpc<void>("marketplace_withdraw_proposal", { p_tenant: tenantId, p_proposal: proposalId }),
    acceptProposal: (tenantId: string, proposalId: string) =>
      rpc<string>("marketplace_accept_proposal", { p_tenant: tenantId, p_proposal: proposalId }),
    myEngagements: async (tenantId: string): Promise<Engagement[]> => {
      const { data, error } = await db.from("marketplace_engagements").select("*")
        .eq("tenant_id", tenantId).order("updated_at", { ascending: false });
      if (error) throw error; return (data ?? []) as Engagement[];
    },
    messages: async (tenantId: string, engagementId: string) => {
      const { data, error } = await db.from("marketplace_messages").select("id,sender_id,body,created_at")
        .eq("tenant_id", tenantId).eq("engagement_id", engagementId).order("created_at");
      if (error) throw error; return data ?? [];
    },
    sendMessage: async (tenantId: string, engagementId: string, body: string) => {
      const { data: auth, error: authError } = await db.auth.getUser();
      if (authError || !auth.user) throw authError ?? new Error("Authentication required");
      const { data, error } = await db.from("marketplace_messages").insert({
        tenant_id: tenantId, engagement_id: engagementId, sender_id: auth.user.id, body
      }).select("id").single();
      if (error) throw error; return data.id as string;
    },
    requestRevision: (tenantId: string, engagementId: string, reason: string) =>
      rpc<string>("marketplace_request_revision", { p_tenant: tenantId, p_engagement: engagementId, p_reason: reason }),
    complete: (tenantId: string, engagementId: string) =>
      rpc<void>("marketplace_complete_engagement", { p_tenant: tenantId, p_engagement: engagementId }),
    /* Delivery upload omitted until a trusted, verified private-file service exists. */
    report: async (tenantId: string, listingId: string | null, reason: string) => {
      const { data: auth, error: authError } = await db.auth.getUser();
      if (authError || !auth.user) throw authError ?? new Error("Authentication required");
      const { data, error } = await db.from("marketplace_reports").insert({
        tenant_id: tenantId, listing_id: listingId, reporter_id: auth.user.id, reason, status: "open"
      }).select("id").single();
      if (error) throw error; return data.id as string;
    }
  };
}
