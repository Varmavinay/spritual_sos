// Minimal Web Push sender using only WebCrypto (works on Cloudflare Workers).
//   - Payload encryption: RFC 8291 (aes128gcm content coding, RFC 8188).
//   - Sender identification: VAPID, RFC 8292.

const encoder = new TextEncoder();

export function base64UrlEncode(bytes) {
  let binary = '';
  for (const b of new Uint8Array(bytes)) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

export function base64UrlDecode(text) {
  const base64 = text.replace(/-/g, '+').replace(/_/g, '/');
  const binary = atob(base64 + '='.repeat((4 - (base64.length % 4)) % 4));
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

function concat(...arrays) {
  const out = new Uint8Array(arrays.reduce((n, a) => n + a.length, 0));
  let offset = 0;
  for (const a of arrays) {
    out.set(a, offset);
    offset += a.length;
  }
  return out;
}

async function hmacSha256(key, data) {
  const k = await crypto.subtle.importKey(
    'raw', key, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  );
  return new Uint8Array(await crypto.subtle.sign('HMAC', k, data));
}

/**
 * Encrypts `plaintext` for a browser subscription (RFC 8291).
 * `salt` and `senderKeys` can be injected for tests; normally random.
 */
export async function encryptPayload(plaintext, p256dh, auth, { salt, senderKeys } = {}) {
  const uaPublic = base64UrlDecode(p256dh);
  const authSecret = base64UrlDecode(auth);
  salt ??= crypto.getRandomValues(new Uint8Array(16));
  senderKeys ??= await crypto.subtle.generateKey(
    { name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveBits'],
  );
  const asPublic = new Uint8Array(
    await crypto.subtle.exportKey('raw', senderKeys.publicKey),
  );

  const uaKey = await crypto.subtle.importKey(
    'raw', uaPublic, { name: 'ECDH', namedCurve: 'P-256' }, false, [],
  );
  const ecdhSecret = new Uint8Array(
    await crypto.subtle.deriveBits(
      { name: 'ECDH', public: uaKey }, senderKeys.privateKey, 256,
    ),
  );

  // IKM = HKDF(auth_secret, ecdh_secret, "WebPush: info" || 0 || ua_public || as_public, 32)
  const prkKey = await hmacSha256(authSecret, ecdhSecret);
  const keyInfo = concat(encoder.encode('WebPush: info\0'), uaPublic, asPublic);
  const ikm = await hmacSha256(prkKey, concat(keyInfo, new Uint8Array([1])));

  // CEK and nonce per RFC 8188.
  const prk = await hmacSha256(salt, ikm);
  const cek = (await hmacSha256(
    prk, concat(encoder.encode('Content-Encoding: aes128gcm\0'), new Uint8Array([1])),
  )).slice(0, 16);
  const nonce = (await hmacSha256(
    prk, concat(encoder.encode('Content-Encoding: nonce\0'), new Uint8Array([1])),
  )).slice(0, 12);

  // Single record: plaintext followed by the 0x02 "last record" delimiter.
  const record = concat(encoder.encode(plaintext), new Uint8Array([2]));
  const aesKey = await crypto.subtle.importKey('raw', cek, 'AES-GCM', false, ['encrypt']);
  const ciphertext = new Uint8Array(
    await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, aesKey, record),
  );

  // Header: salt(16) | record size(4) | key id length(1) | key id (sender public key)
  const recordSize = new Uint8Array(4);
  new DataView(recordSize.buffer).setUint32(0, 4096);
  return concat(salt, recordSize, new Uint8Array([asPublic.length]), asPublic, ciphertext);
}

/** Builds the VAPID `Authorization` header value for `endpoint`. */
export async function vapidAuthorization(endpoint, { publicKey, privateKeyJwk, subject }) {
  const header = { typ: 'JWT', alg: 'ES256' };
  const claims = {
    aud: new URL(endpoint).origin,
    exp: Math.floor(Date.now() / 1000) + 12 * 60 * 60,
    sub: subject,
  };
  const unsigned = `${base64UrlEncode(encoder.encode(JSON.stringify(header)))}.${
    base64UrlEncode(encoder.encode(JSON.stringify(claims)))}`;
  const key = await crypto.subtle.importKey(
    'jwk', privateKeyJwk, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign'],
  );
  // WebCrypto returns the raw r||s signature, which is exactly what JWS ES256 wants.
  const signature = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' }, key, encoder.encode(unsigned),
  );
  return `vapid t=${unsigned}.${base64UrlEncode(signature)}, k=${publicKey}`;
}

/**
 * Sends one push message. Returns the push service's HTTP status
 * (201 = accepted; 404/410 = subscription is gone and should be deleted).
 */
export async function sendPush(subscription, payload, vapid, { ttl = 12 * 60 * 60 } = {}) {
  const body = await encryptPayload(
    JSON.stringify(payload), subscription.p256dh, subscription.auth,
  );
  const response = await fetch(subscription.endpoint, {
    method: 'POST',
    headers: {
      Authorization: await vapidAuthorization(subscription.endpoint, vapid),
      'Content-Encoding': 'aes128gcm',
      'Content-Type': 'application/octet-stream',
      TTL: String(ttl),
      Urgency: 'normal',
    },
    body,
  });
  return response.status;
}
