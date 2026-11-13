import test from 'node:test';
import assert from 'node:assert/strict';
import { createApp } from '../src/app.js';

// A disposable server proves the recording path without a key or changing anyone's demo account.
test('complete demo over HTTP: pick, live game, final, reward, and repeat-settlement protection', async () => {
  const server = createApp().listen(0, '127.0.0.1');
  await new Promise((resolve, reject) => {
    server.once('listening', resolve);
    server.once('error', reject);
  });
  const base = `http://127.0.0.1:${server.address().port}`;
  async function request(path, body) {
    const response = await fetch(`${base}${path}`, body === undefined ? {} : {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
    });
    return { status: response.status, body: await response.json() };
  }
  try {
    const initial = await request('/api/state');
    assert.equal(initial.status, 200);
    assert.equal(initial.body.account.coins, 1000);
    const game = initial.body.games[0];
    const picked = await request('/api/picks', { gameId: game.id, team: game.home, stake: 100 });
    assert.equal(picked.status, 201);
    assert.equal(picked.body.account.coins, 900);
    assert.equal(picked.body.account.dailyStaked, 100);
    const progress = await request(`/api/demo/games/${game.id}/advance`, {});
    assert.equal(progress.body.games[0].status, 'live');
    assert.equal(progress.body.picks[0].status, 'pending');
    const final = await request(`/api/demo/games/${game.id}/advance`, {});
    assert.equal(final.body.games[0].status, 'final');
    assert.equal(final.body.picks[0].status, 'won');
    assert.equal(final.body.account.coins, 1100);
    assert.equal(final.body.collection.length, 1);
    assert.equal(final.body.collection[0].pickId, final.body.picks[0].id);
    assert.equal((await request(`/api/demo/games/${game.id}/advance`, {})).status, 409);
    const refreshed = await request('/api/state');
    assert.equal(refreshed.body.account.coins, 1100);
    assert.equal(refreshed.body.collection.length, 1);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});
