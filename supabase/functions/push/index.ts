// BVM: content-free wake-up push.
//
// The sender's app calls this right after inserting `message` envelopes into
// public.relay:  POST { "relay_ids": ["<uuid>", ...] }
//
// The function checks that the caller really sent those envelopes, asks the
// database which recipients are due a push (at most one every 5 seconds per
// recipient), and sends each one an FCM *data-only* message whose only field
// is {"t":"wake"}. No sender, no preview, no ciphertext ever goes to Google.
//
// Push is optional. Without the FCM_SERVICE_ACCOUNT secret the function
// answers 200 with {"pushed":0,"reason":"push-not-configured"} and recipients
// still receive messages over Realtime / on next launch.
import { accessToken, parseServiceAccount, sendWake } from "../_shared/fcm.ts";
import { adminClient, callerId, corsHeaders, json } from "../_shared/supabase.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const admin = adminClient();
  const uid = await callerId(req, admin);
  if (!uid) return json({ error: "unauthorized" }, 401);

  let ids: string[] = [];
  try {
    const body = await req.json() as { relay_ids?: unknown };
    if (Array.isArray(body.relay_ids)) {
      ids = body.relay_ids.filter((v): v is string => typeof v === "string" && UUID_RE.test(v)).slice(0, 100);
    }
  } catch {
    return json({ error: "invalid body" }, 400);
  }
  if (ids.length === 0) return json({ pushed: 0 });

  const sa = parseServiceAccount(Deno.env.get("FCM_SERVICE_ACCOUNT"));
  if (!sa) return json({ pushed: 0, reason: "push-not-configured" });

  const { data, error } = await admin.rpc("push_targets", { p_sender: uid, p_relay_ids: ids });
  if (error) {
    console.error("push: push_targets failed", error.code);
    return json({ error: "lookup failed" }, 500);
  }
  const targets = (data ?? []) as { recipient_id: string; fcm_token: string }[];
  if (targets.length === 0) return json({ pushed: 0 });

  const bearer = await accessToken(sa);
  let pushed = 0;
  for (const t of targets) {
    try {
      if (await sendWake(sa, bearer, t.fcm_token)) {
        pushed++;
      } else {
        await admin.rpc("drop_push_token", { p_user_id: t.recipient_id, p_token: t.fcm_token });
      }
    } catch (e) {
      console.error("push: send failed", (e as Error).message);
    }
  }
  return json({ pushed });
});
