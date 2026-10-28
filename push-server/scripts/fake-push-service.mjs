// Local stand-in for a browser push service, for end-to-end testing with
// `wrangler dev`. It owns a fake browser key pair, registers a subscription
// with the local Worker, then decrypts and prints every push it receives.
//
//   node scripts/fake-push-service.mjs [workerUrl]
import { createECDH, randomBytes } from 'node:crypto';
import { createServer } from 'node:http';

import ece from 'http_ece';

const workerUrl = process.argv[2] ?? 'http://127.0.0.1:8787';
const port = 9999;

const ecdh = createECDH('prime256v1');
ecdh.generateKeys();
const auth = randomBytes(16);

createServer((req, res) => {
  const chunks = [];
  req.on('data', (c) => chunks.push(c));
  req.on('end', () => {
    try {
      const payload = ece.decrypt(Buffer.concat(chunks), {
        version: 'aes128gcm', privateKey: ecdh, authSecret: auth,
      });
      console.log('PUSH RECEIVED', {
        encoding: req.headers['content-encoding'],
        ttl: req.headers.ttl,
        vapid: /^vapid t=[\w-]+\.[\w-]+\.[\w-]+, k=[\w-]+$/.test(req.headers.authorization),
        payload: JSON.parse(payload.toString('utf8')),
      });
      res.writeHead(201).end();
    } catch (error) {
      console.log('PUSH DECRYPT FAILED', error.message);
      res.writeHead(400).end();
    }
  });
}).listen(port, '127.0.0.1', async () => {
  const response = await fetch(`${workerUrl}/subscribe`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Origin: 'http://localhost:8765' },
    body: JSON.stringify({
      subscription: {
        endpoint: `http://127.0.0.1:${port}/push`,
        keys: { p256dh: ecdh.getPublicKey().toString('base64url'), auth: auth.toString('base64url') },
      },
      hour: 8,
      minute: 0,
      timeZone: 'Australia/Sydney',
    }),
  });
  console.log('SUBSCRIBE', response.status, await response.text());
});
