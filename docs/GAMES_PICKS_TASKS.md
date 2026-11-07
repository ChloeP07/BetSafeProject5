# Games and picks task list

Owner: Games and picks. Branch: `games-picks`. Scope: the NFL game list, matchup cards, team selection, stake controls and validation feedback.

Rules for every task:

- The server owns coins, picks and results. Screens may explain a rule ahead of time, but the server still decides.
- Do not change `server/` or the API contract. Anything that needs a server change goes in the handoff notes for the server owner.
- Do not invent sports stats, odds or scores. Keep simulation labels on demo games. No real-money wording.
- Follow `DESIGN.md`: brown and cream base, green only for selection and wins, 48-pixel minimum controls, scrollable at large text sizes.
- Keep changes to shared files small, and list them in the handoff notes.
- Each task ends with `flutter analyze` and `flutter test` passing.

## Day 1: game list and card foundations

- [x] GP-01 Move game ordering and the NFL/demo split into a tested helper, with a stable order for games that have no kickoff time
- [x] GP-02 Read the player name and daily limit from the server instead of hard-coding "Demo player" and 500
- [x] GP-03 Add a directory of all 32 NFL teams with abbreviations and short names
- [x] GP-04 Use the directory for team badges, and stop badges crashing on an empty team name
- [x] GP-05 Give every game status readable text, including postponed, canceled, delayed, suspended, abandoned and unknown
- [x] GP-06 Color status pills by meaning: open, live, waiting or finished
- [x] GP-07 Stop alternating mint ticket colors, because green is reserved for selection and wins
- [x] GP-08 Show friendly kickoff times such as "Today · 7:20 PM" and "Sun 11/8 · 1:00 PM"
- [x] GP-09 Add a kickoff countdown to open NFL cards that start within 24 hours
- [x] GP-10 Group the list under Live now, Open for picks, Waiting for an update and Finished
- [x] GP-11 Add All, Open, Live and Final filter chips with counts
- [x] GP-12 Add team search that matches names and abbreviations
- [x] GP-13 Add a "no matches" state with a Clear filters action
- [x] GP-14 Show game counts on the NFL/demo chips, add a demo empty state and fix "1 games"
- [x] GP-15 Add pull to refresh on the Games list
- [x] GP-16 Show a banner with Try again when NFL data is stale or failed to load
- [x] GP-17 Replace the first-load spinner with placeholder game cards
- [x] GP-18 Show "Your pick" on cards where a pick already exists
- [x] GP-19 Match the card button to the game: Make a pick, View your pick, View result, View game
- [x] GP-20 Give each matchup card one clear screen-reader description

## Day 2: matchup cards and team selection

- [x] GP-21 Highlight the winning team on final cards, only when both scores are known
- [x] GP-22 Show "Tied" on tied final cards, with no winner highlighted
- [x] GP-23 Tag each team Away or Home on the card, replacing the shared "Away / Home" caption
- [x] GP-24 Make the whole game card tappable, going to the same place as its button
- [x] GP-25 Explain why a card cannot be picked: kickoff passed, postponed, canceled and so on
- [x] GP-26 Add a summary line above the list, such as "2 live · 5 open · 1 picked"
- [x] GP-27 Collapse the Finished section by default, with a show/hide control
- [x] GP-28 Show "Updated N min ago" on the NFL list
- [x] GP-29 Extract the pick screen's team button into a tested TeamOptionCard widget
- [x] GP-30 Announce team options to screen readers as selected or not selected
- [x] GP-31 Add an Away or Home tag to each team option
- [x] GP-32 Animate team selection, respecting the reduced-motion setting
- [x] GP-33 Add a light haptic when a team is selected
- [x] GP-34 Add a confirmation line such as "You're backing the Bills"
- [x] GP-35 Let a second tap on the selected team clear the choice
- [x] GP-36 Let a tap on a team in the pick screen's ticket select that team
- [x] GP-37 Show the kickoff countdown and "Picks close at kickoff" on the pick screen for NFL games
- [x] GP-38 If a game closes while someone is picking, disable the form and explain why
- [x] GP-39 If a game drops out of the server data, show a friendly message on the pick screen instead of crashing
- [x] GP-40 If a pick already exists for the game, go to the game view instead of allowing a duplicate

## Day 3: stake controls and validation feedback

- [x] GP-41 Extract the stake options and chips into a tested StakeSelector widget
- [x] GP-42 Add a tested pick-rules helper that returns the reason a pick is blocked
- [x] GP-43 Disable stake chips the player cannot afford, with a caption saying why
- [x] GP-44 Default to the largest allowed stake when 100 is not allowed, and keep a valid choice when data refreshes
- [ ] GP-45 Add a daily-limit progress bar to the pick screen
- [ ] GP-46 Add a daily-limit progress bar to the wallet panel on Games
- [ ] GP-47 Preview the balance after the pick
- [ ] GP-48 Animate the payout figure when the stake changes, respecting reduced motion
- [ ] GP-49 Separate validation messages for low balance, daily limit and no affordable stake
- [ ] GP-50 Add a helper line under the disabled Lock in button, such as "Choose a team to continue"
- [ ] GP-51 Add a confirmation sheet with team, stake and balance before locking in
- [ ] GP-52 Show progress inside the Lock in button and guard against double taps
- [ ] GP-53 Turn known server errors into friendly messages with a next step
- [ ] GP-54 Clear an old submission error when the player changes team or stake
- [ ] GP-55 Warn about stale NFL data and block NFL submissions until a refresh succeeds
- [ ] GP-56 Confirm a locked pick with a message such as "Pick locked: Bills · 100 coins"
- [ ] GP-57 Explain on the Games screen when the daily limit is reached or coins have run out
- [ ] GP-58 Test Games and Pick at 2× text size and 48-pixel targets, and fix what fails
- [ ] GP-59 Check dark mode contrast on Games and Pick, and fix what fails
- [ ] GP-60 Add a full pick-flow widget test and write the handoff notes and pull request draft
