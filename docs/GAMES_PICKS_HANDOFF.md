# Games and picks handoff

Branch: `games-picks`. Tasks GP-01 to GP-60 in `docs/GAMES_PICKS_TASKS.md`.

The server still owns coins, picks and results. Everything here explains the server's rules ahead of time or shows what the server sent. No API fields, routes or rules changed, and nothing under `server/` was touched.

## What changed

### Games list (GP-01 to GP-28)

- Game ordering, the NFL/demo split, status text, kickoff times, grouping and search live in tested helpers in `lib/models/` (`game_list.dart`, `game_status.dart`, `game_time.dart`, `nfl_teams.dart`).
- Cards are grouped under Live now, Open for picks, Waiting for an update and Finished. Finished is folded away by default.
- All, Open, Live and Final filter chips with counts, team search by name or abbreviation, and a "No games match" state with Clear filters.
- Pull to refresh, a banner with Try again when NFL data is stale or failed, "Updated N min ago", and placeholder cards on first load.
- Cards show "Your pick", a button that matches the game (Make a pick, View your pick, View result, View game), why a game cannot be picked, Away and Home tags, the winner or "Tied" on finals, and one screen-reader description per card. The whole card is tappable.
- The wallet panel reads the player name and daily limit from the server, shows a daily-limit bar (GP-46), and explains when today's limit is used up or coins have run out (GP-57).

### Pick screen (GP-29 to GP-59)

- Team options are a tested `TeamOptionCard`: announced as selected or not selected, tagged Away or Home, animated (off with reduced motion), a light haptic, a "You're backing the Bills" line, and a second tap clears the choice. Tapping a team on the ticket also selects it.
- NFL games show the kickoff countdown and "Picks close at kickoff." If a game closes, drops out of the data, or already has a pick, the screen explains and stops the form.
- Stakes are a tested `StakeSelector` using the server's stakes 50, 100 and 250. Stakes the player cannot afford are disabled with a caption. The default is 100, or the largest stake that fits, and the choice stays valid when data refreshes.
- `lib/models/pick_rules.dart` names the first reason a pick is blocked: closed, already picked, stale NFL data, no stake fits, no team, low balance or daily limit. The screen shows a separate message for each stake problem and a short hint under the disabled Lock in button.
- A wallet panel shows the balance now, the balance after the pick, and today's limit as a bar. The payout figure counts to its new value when the stake changes, and shows it at once with reduced motion.
- Lock in opens a confirmation sheet with the team, stake, balance and return. Only Confirm pick sends the pick. The button shows a spinner while saving, and double taps send one pick.
- Known server errors from `placePick` get friendlier wording with a next step (`lib/models/pick_errors.dart`). Unknown errors show as sent. A failed submission's error clears when the player changes team or stake.
- Stale or failed NFL data shows a warning with Refresh NFL data and blocks NFL picks until a refresh succeeds. Demo games are not affected.
- A locked pick is confirmed on the game view with "Pick locked: Bills · 250 coins".
- Tested at 2× text on a 390×844 screen with 48-pixel targets, and for painted colors in dark mode.

## Shared files touched

- `lib/models/demo_state.dart`: `playerName` and `dailyLimit` read from the account, `Game.kickoffLabel` uses the friendly kickoff format, `DemoState.gameById`, and `NflStatus.hasProblem`.
- `lib/widgets/sports_ui.dart`: `TeamBadge` uses the team directory and copes with an empty name, `GameStatusPill`, `MatchTicket` gains `onTap`, `onTeamTap`, `selectedTeam`, Away/Home tags, the winner, "Tied", the countdown and one screen-reader description. At large text sizes a wide score shrinks to fit (GP-58).
- `lib/screens/home_screen.dart`: the first-load spinner is replaced with `GameListSkeleton`.
- `lib/services/betsafe_api.dart`: new `clearError()` (GP-54). Nothing else in the client changed.
- `test/widget_test.dart`: the pick test now taps Confirm pick on the new sheet and checks that nothing is sent before it.
- `test/support/fixtures.dart` is new and shared by the Games and Pick tests (`pumpApp`, `pumpPick`, `pumpTicket`, `lockInPick`, `stateJson`, `nflGameJson`, `demoGameJson`, `pickJson`, `nflOk`).

`lib/screens/game_screen.dart`, `picks_screen.dart` and `collection_screen.dart` were not changed.

## Notes for the server owner

- The client mirrors these rules only to explain them early: stakes 50/100/250, balance, the daily limit, and fresh NFL data before a real-game pick. If any of them change in `server/src/store.js`, update `lib/models/pick_rules.dart` and the stakes in `stakeOptions`.
- `lib/models/pick_errors.dart` maps the exact `placePick` messages in `server/src/store.js`. `test/pick_errors_test.dart` reads `store.js` and fails if a mapped message no longer appears there, so a reworded server message is caught instead of silently showing the raw text.
- The client cannot see the server's 120-second freshness window, only `nfl.stale` and `nfl.error`. A pick can still be turned down for freshness just after a refresh; the screen then shows the friendly message and Try again.
- The wallet notice says the daily limit resets at midnight UTC and that winning picks return coins when their games finish. Both follow API.md. Please flag it if either rule changes.

## Notes for the game-results owner

- `lib/screens/game_screen.dart:16` and `lib/screens/picks_screen.dart:47` still call `firstWhere` on `state.games`. If a game drops out of the server data, both throw. `pick_screen.dart` now handles this with `state.gameById(id)`, which returns null, and shows "This game is no longer available" with a way back. The same approach would fit both screens.
- After a pick is locked in, the pick screen replaces itself with `GameScreen` and shows a snack bar from the app-wide `ScaffoldMessenger`, so the game view needs no change for it.

## Pull request draft

Title: Games and picks: game list, team selection, stakes and validation feedback

### What changed

Completes the Games and picks tasks GP-01 to GP-60 in `docs/GAMES_PICKS_TASKS.md`: a grouped, filterable NFL game list with clearer cards; a pick screen with accessible team options, stake controls that follow the server's rules, a balance preview, a confirmation sheet, friendly errors and stale-data protection. See `docs/GAMES_PICKS_HANDOFF.md` for the full list.

### Validation

- [ ] Ran `npm run check` from the repository root
- [ ] Checked affected screens in the Android emulator
- [ ] Added a screenshot for a visual change
- [x] Updated API.md if response fields or game rules changed (no changes needed: no fields or rules changed)
- [x] Kept API keys in ignored server/.env, never in Flutter or commits

`flutter analyze` and `flutter test` pass, and `npm --prefix server test` passes with `server/` unchanged.

### Integration notes

Shared files changed: `lib/models/demo_state.dart`, `lib/widgets/sports_ui.dart`, `lib/screens/home_screen.dart`, `lib/services/betsafe_api.dart` (new `clearError()`), and `test/widget_test.dart` (taps through the new confirmation sheet). No new setup steps. `game_screen.dart` and `picks_screen.dart` still use `firstWhere` on the games list and can throw if a game drops out of the server data; see the handoff notes.
