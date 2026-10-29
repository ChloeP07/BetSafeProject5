# Five-person task list

Replace Member 2–5 with names before sharing. Each member owns implementation, validation, and a short handoff for their area.

| Owner | Assigned area | Next concrete work |
| --- | --- | --- |
| You | Setup + integration | Run both phone targets, share setup instructions, review API changes, merge work, verify CI, assemble final demo |
| Member 2 | Games + picks | Improve matchup/pick screens, loading/empty states, stake feedback; work with Member 3 on real schedule fields |
| Member 3 | Server + NFL data + persistence | Choose/verify sports API, add server-side provider adapter and caching, persist account/picks/cards, preserve server validation |
| Member 4 | Game progress + results | Connect available real scores, add refresh and game status, settle real games once; keep clearly separate deterministic demo mode |
| Member 5 | Collection + video | Improve collectible presentation, add card detail/reward reveal, coordinate narrated MP4 under 90 seconds |

## Foundation already provided (review and run it)

- [x] Flutter app and Node/Express server structure
- [x] Shared light/dark theme, navigation and error recovery
- [x] Typed models and shared API client
- [x] Sample NFL games with explicit simulation labels
- [x] Server-authoritative picks, balance, daily limit and demo settlement
- [x] My picks, result view and earned team collectible
- [x] Automated checks/build workflow definition
- [x] API, startup and video documentation

## Before Friday's MVP recording

- [ ] Everyone can clone, install, start the server and launch the app
- [ ] Verify Android emulator and iPhone simulator manually
- [x] Confirm baseline GitHub Actions server, Android and iOS jobs pass
- [ ] Download a successful APK artifact from GitHub Actions
- [x] Connect real NFL schedules/scores and verify authenticated provider access
- [ ] Verify updates during an actual live NFL game
- [ ] Keep a labeled simulation path for the complete video loop
- [ ] Integrate all required features by Thursday evening; Friday is for fixes and recording
- [ ] Record narrated MP4, maximum 90 seconds; show running software
- [ ] Review the actual course deadline/time and upload the video

## Final project backlog

- [ ] Confirm the final deadline/rubric with instructor
- [ ] Persistent database and separate anonymous demo sessions
- [ ] Real sports provider credentials, refresh interval, quotas, and attribution confirmed
- [ ] Cache provider responses; handle timeout/rate-limit/outage without inventing scores
- [ ] Automatic once-only settlement, ties/cancellations/refunds, restart recovery
- [ ] Replace team collectibles with agreed player-card design; use licensed assets
- [ ] Optional leaderboard/streaks only after the core loop works
- [ ] Deploy HTTPS backend; disable demo controls; configure mobile release URLs
- [ ] Device accessibility, network failure and release build checks

## Branches and sports data

See BRANCHES.md for each member’s branch and startup commands. See NFL_DATA.md for the recommended free NFL Games API, request limits and server/results integration agreement.

## Handoff rule

Screens use `BetSafeApi`; do not add separate balances or award logic in widgets. Member 3 owns API changes and documents them in API.md. Member 4 coordinates settlement changes with Member 3. The current demo is intentionally in memory and not a multi-user production backend.
