# Five-person task list

Replace Member 2–5 with names before sharing. Each member owns implementation, validation, and a short handoff for their area.

| Owner | Assigned area | Next concrete work |
| --- | --- | --- |
| You | Setup + integration | Run both phone targets, share setup instructions, review API changes, merge work, verify CI, coordinate final integration |
| Member 2 | Games + picks | Improve matchup/pick screens, loading/empty states, stake feedback; work with Member 3 on real schedule fields |
| Member 3 | Server + NFL data + persistence | Extend the connected NFL feed, persist account/picks/cards, and maintain server validation |
| Member 4 | Game progress + results | Improve connected score/detail and pick-history screens; coordinate settlement/refund behavior with the server owner |
| Member 5 | Collectibles + rewards | Improve collectible presentation, card details, reward reveal and collection empty states |

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
- [x] Verify Android emulator manually
- [ ] Verify iPhone simulator manually (deferred; build passed CI)
- [x] Confirm integrated main GitHub Actions server, Android and iOS jobs pass
- [ ] Download a successful APK artifact from GitHub Actions
- [x] Connect real NFL schedules/scores and verify authenticated provider access
- [ ] Verify updates during an actual live NFL game
- [x] Keep a labeled simulation path for the complete video loop
- [ ] Integrate all required features by Thursday evening; Friday is for fixes and recording
- [ ] Record narrated MP4, maximum 90 seconds; show running software
- [ ] Review the actual course deadline/time and upload the video

## Demo presentation

Choose the presenter from any role based on microphone quality and confidence. Everyone provides their contribution notes and helps test the full flow. Recording is separate from the five development roles.

## Final project backlog

- [ ] Confirm the final deadline/rubric with instructor
- [ ] Persistent database and separate anonymous demo sessions
- [ ] Real sports provider credentials, refresh interval, quotas, and attribution confirmed
- [x] Cache provider responses; handle timeout/rate-limit/outage without inventing scores
- [ ] Automatic once-only settlement, ties/cancellations/refunds, restart recovery
- [ ] Replace team collectibles with agreed player-card design; use licensed assets
- [ ] Optional leaderboard/streaks only after the core loop works
- [ ] Deploy HTTPS backend; disable demo controls; configure mobile release URLs
- [ ] Device accessibility, network failure and release build checks

## Branches and sports data

See BRANCHES.md for each member’s branch and startup commands. See NFL_DATA.md for the recommended free NFL Games API, request limits and server/results integration agreement.

## Handoff rule

Screens use `BetSafeApi`; do not add separate balances or award logic in widgets. Member 3 owns API changes and documents them in API.md. Member 4 coordinates settlement changes with Member 3. The current demo is intentionally in memory and not a multi-user production backend.

Setup completion and acceptance checklist: SETUP_HANDOFF.md.
