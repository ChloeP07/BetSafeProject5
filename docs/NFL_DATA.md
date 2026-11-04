# NFL data decision and integration handoff

Checked November 4, 2026 against provider documentation. Recommendation for this class MVP: evaluate BALLDONTLIE's free NFL Games endpoint first.

## Free option: BALLDONTLIE

https://nfl.balldontlie.io/

The documented free tier includes Teams, Players and Games at 5 requests per minute. The Games section says in-progress game data is updated in real time. Play-by-play, betting odds and detailed stats require paid tiers. A free account/API key is required. Choose the free plan, rather than a paid trial, for this project.

Our recommendation is to poll the Games endpoint once every 30–60 seconds from the Node server while the app is being used, cache the response, and let all phones read that cache. That is near-real-time polling, not guaranteed instant updates. Do not make a separate provider request for every phone or every tap. Respect 429/Retry-After responses and avoid parallel cache refreshes. An authenticated request has been verified (28 games in the rolling window). Freshness during an actual in-progress game still needs a game-day check.

Store a private key as BALLDONTLIE_API_KEY in server/.env, never in Flutter, source control, screenshots, or task descriptions. server/.env.example documents the variable only; the server reads it at startup and connects through src/nfl-feed.js.

## Other options

- API-SPORTS API-NFL: documented free tier of 100 requests/day, 10/minute. Useful for a short demo, but a 30-second poll for three hours alone uses 360 requests. Verify current-season coverage before committing to it. https://www.api-football.com/news/post/how-to-get-started-with-api-nfl-the-complete-beginners-guide
- TheSportsDB: free event data exists, but two-minute live scores are listed as a premium feature. https://www.thesportsdb.com/documentation

## Member 3 + Member 4 integration agreement

1. Keep the current simulation path separate; never advance or settle real games using demo controls.
2. Member 3 implements server-only provider access and maps stable game IDs, kickoff timestamps, names, nullable scores and provider lifecycle state into the shared model. Update API.md before changing Flutter models.
3. Close picks at kickoff on the server even if an upstream status is delayed. Agree on handling postponed, suspended, canceled, tied and unknown games.
4. Member 4 renders actual statuses, refreshes the server on a bounded timer while the app is foregrounded, cancels the timer when disposed/backgrounded, and displays stale/error states honestly.
5. Persist picks and settle each once. Return a stake on a tie/cancellation under the agreed rules.
6. Display source, last successful fetch time and any stale-cache condition. A fetch timestamp is not proof that the provider's score is current.
7. Test normalization using recorded fixtures, plus one authenticated request and a live-game check when available. Keep a deterministic simulation for video recording.

## Setup lead's boundary

Provider research and the initial integration are ready. Server/results owners can extend the cached feed, persistence and real-game UI from this baseline. No API account, subscription, collaborator, or remote branch was created as part of this handoff.

## Implemented baseline

`src/nfl-feed.js` fetches once per minute on demand, merges concurrent requests, honors Retry-After on 429, and preserves cached results on outage. Unknown lifecycle states remain unknown. State exposes source, configured status, fetch time, staleness and a sanitized error; credentials never enter responses. The Flutter app has separate NFL schedule/Demo games choices and foreground-only refresh. Real picks close at kickoff, need fresh data, and settle once on refresh. Canceled/abandoned games and ties refund stakes.

Remaining: persistent storage, separate anonymous users, live-game freshness verification, handling long postponements beyond the query window and score corrections after settlement. Previous picks outside the query window stay visible but require a future individual-game lookup to keep updating.
