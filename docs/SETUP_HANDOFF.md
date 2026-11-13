# Setup and integration handoff

## Ready to build on

- Flutter app and Node server with a working virtual-coin demo loop.
- Brown/cream/green visual foundation and shared screen components.
- Separate real NFL schedule and simulated games. BALLDONTLIE credentials stay on the server.
- One-command setup, local checks, and Android development startup.
- Automated server tests, Flutter checks, Android APK and iPhone simulator builds.
- Per-role branch instructions, API contract, PR template and demo outline.

## Existing build evidence

The integrated foundation on main passed all three jobs: [Build and test](https://github.com/ChloeP07/BetSafeProject5/actions/runs/41814653526), commit 51f5665. Open the workflow's Artifacts section for the Android debug APK and iPhone simulator app.

The latest launcher, workflow improvements, handoff updates and HTTP demo-flow test are local changes on setup-integration. Commit and push those yourself, then review their new checks before merging; the existing successful run does not verify unpushed changes.

## Teammate startup check

After creating their branch from the current main and installing Flutter and Node.js 24:

```sh
npm run setup
npm run check
```

Start one emulator in Android Studio → Device Manager:

```sh
npm run android
```

With multiple devices: `npm run android -- emulator-5554`, substituting the actual Android device ID.

Ask each member to confirm:

- Their assigned branch is selected (`git branch --show-current`).
- Dependencies install and checks pass.
- The app opens and the server responds.
- They can use Demo games without an API key.
- They know their owned files and coordinate changes to shared files.

Do not check off another member's startup confirmation until they report it themselves.

## Acceptance check before recording

1. Use a clean local server session for a fresh 1,000-coin demo account. Restarting the server resets the shared in-memory account.
2. Open Demo games, select the first matchup's home team and stake 100 coins.
3. Confirm the balance becomes 900, the pick appears in My picks, and the limit has 400 coins remaining.
4. Start the simulation, then finish it. Confirm the winning result returns 200 coins (balance 1,100).
5. Open Collection and confirm one collectible is earned. Refresh without duplicating coins or rewards.
6. Check that NFL schedule shows a source/fetch time, while Demo games remains labeled simulation.
7. Record the running app with narration, export MP4 under 90 seconds, and play it back before submission.

The disposable HTTP demo-flow test automates the server-side part of this check inside npm run check. It does not mutate the running app's account or call BALLDONTLIE. Manual navigation/recording still needs the emulator.

## Coordination after handoff

The presenter is chosen from the whole group based on microphone quality and presentation confidence. Recording is not assigned to the collectible developer. Every developer supplies a short contribution explanation and helps test the complete flow.

Your continuing integration work begins when feature PRs arrive: review shared-file changes, confirm checks, merge reviewed work, and repeat the acceptance check. Do not implement every teammate's feature to finish the setup role.

## Known limits to communicate

- One shared in-memory demo account; restarts reset it. Persistence/separate users belong to the server owner.
- NFL scores refresh about once per minute; play-by-play is not connected. In-game freshness still needs a live-game check.
- Scores corrected after settlement and long-postponed games need further server work.
- iPhone simulator builds passed CI. Manual iPhone runtime verification is deferred while the current preview target is Android.
- Real-phone networking/signing and production HTTPS deployment remain separate final-project tasks.
- Confirm the current course submission deadline/time rather than relying on old dates in chat.
