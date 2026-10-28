import test from 'node:test';
import assert from 'node:assert/strict';
import { createApp } from '../src/app.js';

async function withServer(options, run) {
  const server = createApp(options).listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  try { await run(`http://127.0.0.1:${server.address().port}`); }
  finally { await new Promise((resolve) => server.close(resolve)); }
}

test('HTTP API validates picks and returns server-owned state', async () => {
  await withServer({}, async (base) => {
    assert.equal((await fetch(`${base}/health`)).status, 200);
    const post = (body) => fetch(`${base}/api/picks`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
    });
    assert.equal((await post({ stake: -100 })).status, 404);
    const valid = await post({ gameId: 'demo-1', team: 'Buffalo Bills', stake: 100, payout: 99999 });
    assert.equal(valid.status, 201);
    assert.equal((await valid.json()).account.coins, 900);
    assert.equal((await post({ gameId: 'demo-1', team: 'Buffalo Bills', stake: 100 })).status, 409);
  });
});
test('demo mutation route can be disabled', async () => {
  await withServer({ demoEnabled: false }, async (base) => {
    assert.equal((await fetch(`${base}/api/demo/games/demo-1/advance`, { method: 'POST' })).status, 404);
  });
});
