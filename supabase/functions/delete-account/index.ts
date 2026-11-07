// BVM: "Delete my account".
//
// POST { "device_key": "<Curve25519 identity key of the calling phone>" }
//
// Removes the caller's directory entry, identity keys, one-time keys, push
// token, encrypted phone number, undelivered envelopes addressed to them, and
// finally the Supabase Auth user (which holds the e-mail address).
//
// Only the account's current phone may delete it: a phone that was replaced
// by a newer one (one phone per account) gets 409, so an old phone that still
// holds a valid access token cannot delete the account now in use elsewhere.
//
// Envelopes the caller already sent and that are still waiting for an offline
// peer (for example wipe commands) are intentionally kept until they are
// delivered or their TTL passes, so a pending remote wipe still happens.
import { adminClient, callerId, corsHeaders, json } from "../_shared/supabase.ts";

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const admin = adminClient();
  const uid = await callerId(req, admin);
  if (!uid) return json({ error: "unauthorized" }, 401);

  let deviceKey = "";
  try {
    const body = await req.json() as { device_key?: unknown };
    if (typeof body.device_key === "string") deviceKey = body.device_key;
  } catch {
    return json({ error: "invalid body" }, 400);
  }

  const { data: entry, error: lookupError } = await admin
    .from("users")
    .select("identity_key")
    .eq("id", uid)
    .maybeSingle();
  if (lookupError) {
    console.error("delete-account: lookup failed", lookupError.code);
    return json({ error: "lookup failed" }, 500);
  }
  // No directory entry yet (registration never finished): nothing to protect.
  if (entry && entry.identity_key !== deviceKey) {
    return json({ error: "this account is now used on another phone" }, 409);
  }

  // public.users cascades to one_time_keys and relay rows addressed to the user.
  const { error: dirError } = await admin.from("users").delete().eq("id", uid);
  if (dirError) {
    console.error("delete-account: directory delete failed", dirError.code);
    return json({ error: "could not delete directory entry" }, 500);
  }

  // auth.users cascades to private.user_contact and private.push_tokens.
  const { error: authError } = await admin.auth.admin.deleteUser(uid);
  if (authError) {
    console.error("delete-account: auth delete failed", authError.status);
    return json({ error: "could not delete auth user" }, 500);
  }

  return json({ deleted: true });
});
