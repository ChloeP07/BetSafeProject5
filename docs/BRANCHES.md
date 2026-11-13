# Team branches and handoff

| Owner | Branch | Main files |
| --- | --- | --- |
| You | `setup-integration` | Navigation, theme/shared widgets, CI, setup and integration docs |
| Member 2 | `games-picks` | Games/pick screens |
| Member 3 | `server-nfl-data` | Server, database, sports provider, API contract |
| Member 4 | `game-results` | Game progress, results, score refresh; coordinate settlement with Member 3 |
| Member 5 | `collection-demo` | Collection, card details, reward presentation |

All five branches were created locally from the current main baseline. Your checkout is on setup-integration. Branch creation does not publish anything to GitHub. Existing work was already committed before these branches were created; new setup work belongs on setup-integration.

## Each teammate starts here

Clone the repository and install Flutter plus Node.js 24. Install Android Studio and an emulator. From the repository root:

```sh
npm run setup
```

In one terminal run `npm run server`. In another, run `flutter devices`, then `flutter run -d <device-id>`. The Android emulator uses the server at 10.0.2.2:3000 automatically.

If their role branch has not been pushed to GitHub, create it locally after cloning:

```sh
git switch main
git pull --ff-only
git switch -c games-picks
```

Replace games-picks with the teammate's assigned branch. If the branch already exists remotely, use `git fetch origin`, then `git switch --track origin/games-picks` instead. Do not run the create command again for an existing local branch: switch to it instead.

## Publishing branches (you handle this)

The branches here are local only. After reviewing and committing your changes, you can publish your branch:

```sh
git push -u origin setup-integration
```

Each teammate can publish their own branch using the same command with their branch name. No need to publish everyone else's branch yourself. Open a pull request into main, use the provided PR checklist, and have another teammate review it before merging.

## Keep integration manageable

- Run `npm run check` before handing work over.
- Coordinate changes to shared models, theme, navigation, API client, and API response fields.
- Do not keep separate coin balances in widgets; the server owns them.
- Keep the demo simulation available for the video when no NFL game is live.
- Commit only your reviewed files. Do not commit node_modules, build outputs, or .env.
- Once a foundation change is merged into main, commit your feature work and merge origin/main into your branch; resolve shared-file conflicts together.

## Your current setup responsibilities

- [x] Shared foundation, navigation, styling, server startup and API contract
- [x] Android APK build and emulator preview verified
- [x] Local branches and ownership defined
- [x] Root-level setup/check/server commands and PR handoff checklist
- [x] One-command Android launcher with emulator selection and server health check
- [x] Verify baseline main CI (server, Android, iOS all succeeded)
- [x] Publish NFL integration and verify all three CI jobs (also integrated into main)
- [ ] Commit/publish final launcher, CI and handoff changes; verify their new checks
- [ ] Confirm every teammate can run the app and server
- [ ] Integrate reviewed feature branches into main
- [ ] Verify iPhone later (Android is the current preview target)
- [ ] Confirm final due date and coordinate final acceptance with the chosen presenter

Baseline verification: [successful workflow run](https://github.com/ChloeP07/BetSafeProject5/actions/runs/41811150109) for commit b9bfbb1. This verifies the pushed foundation; new branch-only changes still need to be committed/pushed by you before remote CI can check them.

See SETUP_HANDOFF.md for the final setup checklist and remaining team coordination. Presentation is a shared assignment, separate from collectible development.
