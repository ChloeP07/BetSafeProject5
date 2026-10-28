# BetSafe API contract

Base URL: `http://127.0.0.1:3000` locally. JSON bodies. One shared demo account; no authentication. State is in memory and resets on server restart. Routes are for local development.

| Method | Route | Body | Response |
| --- | --- | --- | --- |
| GET | `/health` | — | `{status, service, mode}` |
| GET | `/api/state` | — | Full snapshot |
| POST | `/api/picks` | `{gameId, team, stake}` | 201, full snapshot |
| POST | `/api/demo/games/:id/advance` | `{}` | Full snapshot; scheduled → live → final |

Snapshot:

```json
{
  "mode": "simulation",
  "day": "2026-11-04",
  "account": {"id": "demo", "name": "Demo player", "coins": 1000, "dailyLimit": 500, "dailyStaked": 0},
  "games": [{"id": "demo-1", "away": "Kansas City Chiefs", "home": "Buffalo Bills", "label": "Demo matchup", "status": "scheduled", "awayScore": 0, "homeScore": 0}],
  "picks": [],
  "collection": []
}
```

A pick has `id`, `gameId`, `team`, `stake`, `status` (`pending`, `won`, `lost`) and `payout`. Payout is total coins returned, including stake. A collectible has `id`, `team`, `name`, `position`, `rarity`, `pickId`.

Pick validation: existing scheduled game, matching team, integer stake 50/100/250, one pick per game, enough balance, at most 500 coins staked per UTC day. Stake is debited immediately. Server-owned demo payout is 2× on wins; no client-supplied multiplier or payout is accepted. Home team wins fixtures; each final is settled once. Demo controls can be disabled using `DEMO_CONTROLS=false`.

Errors: JSON `{ "error": "Readable message" }`. 400 invalid input, 404 missing route/game, 409 duplicate/closed operation, 500 unexpected failure. Flutter displays server messages and allows recovery. GET state is the refresh operation.

## Real NFL provider handoff

Real schedules/scores are not connected yet. Evaluate TheSportsDB's documented NFL event endpoints on the server. Free API availability does not imply free live scores: check the provider's current documentation, quotas and terms before choosing. Keep provider keys in `server/.env`; never embed private keys in Flutter. Normalize provider records into the agreed game model, add actual kickoff timestamps and close picks at kickoff on the server. Preserve stable IDs and separate real games from demo fixtures. A tie/cancellation should refund the stake under an agreed server rule. Never route real games through demo advancement.

Provider documentation: https://www.thesportsdb.com/documentation
