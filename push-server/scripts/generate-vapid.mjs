// Generates a VAPID key pair for the push server.
//
//   - Prints the public key: put it in wrangler.toml as VAPID_PUBLIC_KEY.
//   - Writes the private key to .vapid-private.json (git-ignored). Upload it with
//       npx wrangler secret put VAPID_PRIVATE_KEY < .vapid-private.json
//   - Writes .dev.vars (git-ignored) so `wrangler dev` can use the same key.
//
// Generate keys once: new keys invalidate every existing subscription.
import { existsSync, writeFileSync } from 'node:fs';
import { webcrypto as crypto } from 'node:crypto';

if (existsSync('.vapid-private.json') && !process.argv.includes('--force')) {
  console.error('.vapid-private.json already exists. Use --force to replace the keys.');
  process.exit(1);
}

const keys = await crypto.subtle.generateKey(
  { name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify'],
);
const publicKey = Buffer.from(
  new Uint8Array(await crypto.subtle.exportKey('raw', keys.publicKey)),
).toString('base64url');
const { kty, crv, x, y, d } = await crypto.subtle.exportKey('jwk', keys.privateKey);
const privateJwk = JSON.stringify({ kty, crv, x, y, d });

writeFileSync('.vapid-private.json', privateJwk);
writeFileSync(
  '.dev.vars',
  `VAPID_PRIVATE_KEY='${privateJwk}'\nALLOW_LOCAL_ENDPOINTS=true\n`,
);

console.log(`VAPID_PUBLIC_KEY = "${publicKey}"`);
console.log('Private key written to .vapid-private.json and .dev.vars (both git-ignored).');
