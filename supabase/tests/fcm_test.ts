// deno test supabase/tests/fcm_test.ts
// (kept outside supabase/functions so `supabase functions deploy` ignores it)
import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  base64url,
  parseServiceAccount,
  pemToDer,
  signServiceAccountJwt,
  wakeMessage,
} from "../functions/_shared/fcm.ts";

function fromBase64url(s: string): Uint8Array<ArrayBuffer> {
  const b64 = s.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((s.length + 3) % 4);
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

async function testServiceAccount() {
  const pair = await crypto.subtle.generateKey(
    { name: "RSASSA-PKCS1-v1_5", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" },
    true,
    ["sign", "verify"],
  );
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const b64 = btoa(String.fromCharCode(...pkcs8)).replace(/(.{64})/g, "$1\n");
  const pem = `-----BEGIN PRIVATE KEY-----\n${b64}\n-----END PRIVATE KEY-----\n`;
  return {
    publicKey: pair.publicKey,
    sa: { project_id: "bvm-test", client_email: "push@bvm-test.iam.gserviceaccount.com", private_key: pem },
  };
}

Deno.test("service-account JWT is a valid RS256 token with the FCM scope", async () => {
  const { sa, publicKey } = await testServiceAccount();
  const jwt = await signServiceAccountJwt(sa, 1_800_000_000);
  const [h, c, s] = jwt.split(".");
  assertEquals(JSON.parse(new TextDecoder().decode(fromBase64url(h))), { alg: "RS256", typ: "JWT" });
  const claims = JSON.parse(new TextDecoder().decode(fromBase64url(c)));
  assertEquals(claims.iss, sa.client_email);
  assertEquals(claims.aud, "https://oauth2.googleapis.com/token");
  assertEquals(claims.scope, "https://www.googleapis.com/auth/firebase.messaging");
  assertEquals(claims.exp - claims.iat, 3600);
  const ok = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    publicKey,
    fromBase64url(s),
    new TextEncoder().encode(`${h}.${c}`),
  );
  assert(ok, "signature must verify with the service account's public key");
});

Deno.test("the wake-up push carries no content and targets the FID", () => {
  const msg = wakeMessage("fid-123") as { message: Record<string, unknown> };
  assertEquals(msg.message.fid, "fid-123");
  assertEquals(msg.message.data, { t: "wake" });
  assertEquals("notification" in msg.message, false);
  assertEquals("token" in msg.message, false);
});

Deno.test("helpers", () => {
  assertEquals(base64url("hi?"), "aGk_");
  assertEquals(pemToDer("-----BEGIN X-----\nAQID\n-----END X-----").length, 3);
  assertEquals(parseServiceAccount("{"), null);
  assertEquals(parseServiceAccount('{"project_id":"p"}'), null);
});
