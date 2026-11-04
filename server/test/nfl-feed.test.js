import test from 'node:test';
import assert from 'node:assert/strict';
import { createNflFeed, normalizeGame } from '../src/nfl-feed.js';
import { createStore, placePick, syncNfl, advanceDemo } from '../src/store.js';
const timestamp = Date.parse('2030-10-01T12:00:00Z');
const raw = { id: 10, home_team: { full_name: 'Buffalo Bills' }, visitor_team: { full_name: 'Kansas City Chiefs' },
  date: '2030-10-03T20:00:00Z', status_state: 'scheduled', home_team_score: null, visitor_team_score: null };
const response = () => Response.json({ data: [raw], meta: { next_cursor: null } });

test('one provider request serves simultaneous callers and the minute cache', async () => {
  let count = 0, now = timestamp;
  const feed = createNflFeed({ apiKey: 'fake-test-key', now: () => now, fetchImpl: async (url, options) => {
    count++; assert.equal(url.searchParams.getAll('dates[]').length, 11);
    assert.equal(options.headers.Authorization, 'fake-test-key'); return response();
  } });
  const results = await Promise.all([feed.get(), feed.get(), feed.get()]);
  assert.equal(count, 1);
  assert.equal(results[0].games[0].id, 'bdl-10');
  assert.equal(results[0].games[0].homeScore, null);
  await feed.get(); assert.equal(count, 1);
  now += 60_001; await feed.get(); assert.equal(count, 2);
  assert.ok(!JSON.stringify(results).includes('fake-test-key'));
});
test('outage preserves real cached records and 429 honors cooldown', async () => {
  let count = 0, now = timestamp;
  const feed = createNflFeed({ apiKey: 'test-key', now: () => now, fetchImpl: async () => {
    count++; return count === 1 ? response() : new Response('', { status: 429, headers: { 'Retry-After': '180' } });
  } });
  await feed.get(); now += 60_001;
  const stale = await feed.get();
  assert.equal(stale.stale, true); assert.equal(stale.games.length, 1);
  now += 120_000; await feed.get(); assert.equal(count, 2);
});
test('missing key does not send network requests; unknown lifecycle never becomes scheduled', async () => {
  const feed = createNflFeed({ fetchImpl: () => { throw new Error('must not call'); } });
  assert.equal((await feed.get()).configured, false);
  assert.equal(normalizeGame({ ...raw, status_state: 'surprise' }).status, 'unknown');
});
test('real games cannot be simulated; fresh future picks settle once or refund', () => {
  const store = createStore();
  const game = normalizeGame({ ...raw, date: new Date(Date.now() + 3600_000).toISOString() });
  const feed = { configured: true, fetchedAt: new Date().toISOString(), stale: false, games: [game] };
  syncNfl(store, feed);
  placePick(store, { gameId: game.id, team: game.home, stake: 100 });
  assert.throws(() => advanceDemo(store, game.id));
  const finalFeed = { ...feed, games: [{ ...game, status: 'final', homeScore: 20, awayScore: 10 }] };
  syncNfl(store, finalFeed); syncNfl(store, finalFeed);
  assert.equal(store.account.coins, 1100); assert.equal(store.collection.length, 1);
  assert.equal(store.picks[0].status, 'won');
  const otherGame = { ...game, id: 'bdl-11' };
  syncNfl(store, { ...feed, games: [otherGame] });
  placePick(store, { gameId: otherGame.id, team: otherGame.home, stake: 100 });
  syncNfl(store, { ...feed, games: [{ ...otherGame, status: 'canceled' }] });
  assert.equal(store.account.coins, 1100); assert.equal(store.picks[1].status, 'refunded');
});
test('past kickoff or stale provider state rejects real picks', () => {
  const store = createStore();
  const game = normalizeGame({ ...raw, date: new Date(Date.now() - 1000).toISOString() });
  syncNfl(store, { configured: true, fetchedAt: new Date().toISOString(), stale: false, games: [game] });
  assert.throws(() => placePick(store, { gameId: game.id, team: game.home, stake: 100 }));
  game.kickoff = new Date(Date.now() + 3600_000).toISOString();
  syncNfl(store, { configured: true, fetchedAt: new Date().toISOString(), stale: true, games: [game] });
  assert.throws(() => placePick(store, { gameId: game.id, team: game.home, stake: 100 }));
  assert.equal(store.account.coins, 1000);
});
