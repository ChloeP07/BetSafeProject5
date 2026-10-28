import test from 'node:test';
import assert from 'node:assert/strict';
import { createStore, placePick, advanceDemo, snapshot } from '../src/store.js';

test('winning pick debits stake and pays once with one collectible', () => {
  const store = createStore();
  placePick(store, { gameId: 'demo-1', team: 'Buffalo Bills', stake: 100 });
  assert.equal(store.account.coins, 900);
  advanceDemo(store, 'demo-1');
  assert.equal(store.games[0].status, 'live');
  advanceDemo(store, 'demo-1');
  assert.equal(store.account.coins, 1100);
  assert.equal(store.collection.length, 1);
  assert.throws(() => advanceDemo(store, 'demo-1'));
  assert.equal(store.account.coins, 1100);
});
test('losing picks do not award coins or cards', () => {
  const store = createStore();
  placePick(store, { gameId: 'demo-1', team: 'Kansas City Chiefs', stake: 50 });
  advanceDemo(store, 'demo-1'); advanceDemo(store, 'demo-1');
  assert.equal(store.account.coins, 950);
  assert.equal(store.picks[0].status, 'lost');
  assert.equal(store.collection.length, 0);
});
test('invalid, duplicate, late and over-limit picks cannot change balance', () => {
  const store = createStore();
  for (const stake of [-100, 0, 1.5, '100', 300]) {
    assert.throws(() => placePick(store, { gameId: 'demo-1', team: 'Buffalo Bills', stake }));
  }
  assert.throws(() => placePick(store, { gameId: 'demo-1', team: 'Wrong team', stake: 100 }));
  assert.equal(store.account.coins, 1000);
  placePick(store, { gameId: 'demo-1', team: 'Buffalo Bills', stake: 250 });
  assert.throws(() => placePick(store, { gameId: 'demo-1', team: 'Buffalo Bills', stake: 250 }));
  placePick(store, { gameId: 'demo-2', team: 'Dallas Cowboys', stake: 250 });
  assert.throws(() => placePick(store, { gameId: 'demo-3', team: 'Chicago Bears', stake: 50 }));
  assert.equal(store.account.coins, 500);
  store.games[2].status = 'live';
  assert.throws(() => placePick(store, { gameId: 'demo-3', team: 'Chicago Bears', stake: 50 }));
});
test('insufficient balance and daily rollover', () => {
  const store = createStore();
  store.account.coins = 10;
  assert.throws(() => placePick(store, { gameId: 'demo-1', team: 'Buffalo Bills', stake: 50 }));
  store.day = '2000-01-01'; store.account.dailyStaked = 500;
  snapshot(store);
  assert.equal(store.account.dailyStaked, 0);
  assert.equal(store.account.coins, 10);
});
