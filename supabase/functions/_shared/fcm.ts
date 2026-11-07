// FCM HTTP v1 helpers: service-account JWT (RS256) -> OAuth2 token -> send.

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

export function parseServiceAccount(raw: string | undefined): ServiceAccount | null {
  if (!raw) return null;
  try {
    const sa = JSON.parse(raw) as ServiceAccount;
    return sa.project_id && sa.client_email && sa.private_key ? sa : null;
  } catch {
    return null;
  }
}

export function base64url(bytes: Uint8Array | string): string {
  const data = typeof bytes === "string" ? new TextEncoder().encode(bytes) : bytes;
  let binary = "";
  for (const b of data) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export function pemToDer(pem: string): Uint8Array<ArrayBuffer> {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const binary = atob(b64);
  const der = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) der[i] = binary.charCodeAt(i);
  return der;
}

/** Self-signed JWT that Google's token endpoint exchanges for an access token. */
export async function signServiceAccountJwt(sa: ServiceAccount, nowSeconds: number): Promise<string> {
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  }));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`)),
  );
  return `${header}.${claims}.${base64url(signature)}`;
}

let cachedToken: { value: string; expiresAt: number } | null = null;

/** OAuth2 access token for FCM, cached until shortly before it expires. */
export async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt - 60 > now) return cachedToken.value;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: await signServiceAccountJwt(sa, now),
    }),
  });
  if (!res.ok) throw new Error(`oauth token request failed: ${res.status}`);
  const body = await res.json() as { access_token: string; expires_in: number };
  cachedToken = { value: body.access_token, expiresAt: now + body.expires_in };
  return body.access_token;
}

/**
 * The only payload BVM ever sends: a data-only wake-up without content,
 * addressed to the app instance's Firebase Installation ID (FCM's FID-based
 * registration; `token` is deprecated).
 */
export function wakeMessage(fid: string): Record<string, unknown> {
  return {
    message: {
      fid,
      data: { t: "wake" },
      android: { priority: "HIGH", ttl: "3600s", collapse_key: "bvm-wake" },
    },
  };
}

/** Returns false when FCM reports the registration as no longer valid. */
export async function sendWake(sa: ServiceAccount, bearer: string, fid: string): Promise<boolean> {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
    method: "POST",
    headers: { "Authorization": `Bearer ${bearer}`, "Content-Type": "application/json" },
    body: JSON.stringify(wakeMessage(fid)),
  });
  if (res.ok) return true;
  const text = await res.text();
  if (res.status === 404 || text.includes("UNREGISTERED") || text.includes("INVALID_ARGUMENT")) {
    return false;
  }
  throw new Error(`fcm send failed: ${res.status}`);
}
