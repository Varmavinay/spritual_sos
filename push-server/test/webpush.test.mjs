import assert from 'node:assert/strict';
import { createECDH, createPublicKey, randomBytes, verify } from 'node:crypto';
import { test } from 'node:test';

import ece from 'http_ece';

import { encryptPayload, vapidAuthorization } from '../src/webpush.js';

function fakeBrowserSubscription() {
  const ecdh = createECDH('prime256v1');
  ecdh.generateKeys();
  const auth = randomBytes(16);
  return {
    ecdh,
    p256dh: ecdh.getPublicKey().toString('base64url'),
    auth: auth.toString('base64url'),
    authBuffer: auth,
  };
}

test('payload decrypts with an independent RFC 8291 implementation', async () => {
  const browser = fakeBrowserSubscription();
  const message = JSON.stringify({ title: '🕉️ Bhagavad Gita', body: '“Set thy heart upon thy work”' });

  const encrypted = await encryptPayload(message, browser.p256dh, browser.auth);
  const decrypted = ece.decrypt(Buffer.from(encrypted), {
    version: 'aes128gcm',
    privateKey: browser.ecdh,
    authSecret: browser.authBuffer,
  });

  assert.equal(decrypted.toString('utf8'), message);
});

test('VAPID header carries a valid ES256 JWT for the push origin', async () => {
  const { webcrypto } = await import('node:crypto');
  const keys = await webcrypto.subtle.generateKey(
    { name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify'],
  );
  const privateKeyJwk = await webcrypto.subtle.exportKey('jwk', keys.privateKey);
  const publicKey = Buffer.from(
    await webcrypto.subtle.exportKey('raw', keys.publicKey),
  ).toString('base64url');

  const header = await vapidAuthorization(
    'https://web.push.apple.com/QGuQyavXutnMHG7r/abc',
    { publicKey, privateKeyJwk, subject: 'https://example.github.io/app/' },
  );

  const match = header.match(/^vapid t=([^,]+), k=(.+)$/);
  assert.ok(match, header);
  const [, jwt, k] = match;
  assert.equal(k, publicKey);

  const [h, c, s] = jwt.split('.');
  const claims = JSON.parse(Buffer.from(c, 'base64url').toString());
  assert.equal(claims.aud, 'https://web.push.apple.com');
  assert.equal(claims.sub, 'https://example.github.io/app/');
  assert.ok(claims.exp > Date.now() / 1000);

  const jwk = await webcrypto.subtle.exportKey('jwk', keys.publicKey);
  const ok = verify(
    'sha256',
    Buffer.from(`${h}.${c}`),
    { key: createPublicKey({ key: jwk, format: 'jwk' }), dsaEncoding: 'ieee-p1363' },
    Buffer.from(s, 'base64url'),
  );
  assert.ok(ok, 'JWT signature should verify');
});
