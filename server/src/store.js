import { randomUUID } from 'node:crypto';

// Deliberately fictional fixtures: no real schedule, odds, or results are claimed.
export function createStore() {
  return {
    day: new Date().toISOString().slice(0, 10),
    account: { id: 'demo', name: 'Demo player', coins: 1000, dailyLimit: 500, dailyStaked: 0 },
    games: [
      { id: 'demo-1', away: 'Kansas City Chiefs', home: 'Buffalo Bills', label: 'Demo matchup', status: 'scheduled', awayScore: 0, homeScore: 0 },
      { id: 'demo-2', away: 'Dallas Cowboys', home: 'Philadelphia Eagles', label: 'Demo matchup', status: 'scheduled', awayScore: 0, homeScore: 0 },
      { id: 'demo-3', away: 'Green Bay Packers', home: 'Chicago Bears', label: 'Demo matchup', status: 'scheduled', awayScore: 0, homeScore: 0 },
    ],
    picks: [],
    collection: [],
  };
}

function requireCondition(condition, message, status = 400) {
  if (!condition) throw Object.assign(new Error(message), { status });
}

export function snapshot(store) {
  const today = new Date().toISOString().slice(0, 10);
  if (store.day !== today) {
    store.day = today;
    store.account.dailyStaked = 0;
  }
  return { mode: 'simulation', ...store };
}

export function placePick(store, { gameId, team, stake } = {}) {
  snapshot(store);
  const game = store.games.find((item) => item.id === gameId);
  requireCondition(game, 'Game not found.', 404);
  requireCondition(game.status === 'scheduled', 'Picks are closed for this game.', 409);
  requireCondition(team === game.home || team === game.away, 'Choose a team in this game.');
  requireCondition(Number.isInteger(stake) && [50, 100, 250].includes(stake), 'Choose a stake of 50, 100, or 250 coins.');
  requireCondition(!store.picks.some((pick) => pick.gameId === gameId), 'You already picked this game.', 409);
  requireCondition(store.account.coins >= stake, 'Not enough virtual coins.');
  requireCondition(store.account.dailyStaked + stake <= store.account.dailyLimit, 'Daily stake limit reached.');
  const pick = { id: randomUUID(), gameId, team, stake, status: 'pending', payout: 0 };
  store.account.coins -= stake;
  store.account.dailyStaked += stake;
  store.picks.push(pick);
  return pick;
}

// Separate demo-only route drives a repeatable video; clients cannot choose a winner.
export function advanceDemo(store, gameId) {
  const game = store.games.find((item) => item.id === gameId);
  requireCondition(game, 'Game not found.', 404);
  requireCondition(game.status !== 'final', 'This game has already finished.', 409);
  requireCondition(store.picks.some((pick) => pick.gameId === gameId), 'Make a pick before starting the simulation.', 409);
  if (game.status === 'scheduled') {
    Object.assign(game, { status: 'live', awayScore: 20, homeScore: 24, label: 'Simulation · fourth quarter' });
    return;
  }
  Object.assign(game, { status: 'final', awayScore: 20, homeScore: 27, label: 'Simulation · final' });
  for (const pick of store.picks.filter((item) => item.gameId === gameId && item.status === 'pending')) {
    pick.status = pick.team === game.home ? 'won' : 'lost';
    if (pick.status === 'won') {
      // Flat demo multiplier, not sportsbook odds. Return includes the original stake.
      pick.payout = pick.stake * 2;
      store.account.coins += pick.payout;
      store.collection.push({ id: randomUUID(), team: game.home, name: 'Game Day', position: 'Team collectible', rarity: 'Starter', pickId: pick.id });
    }
  }
}
