# BetSafe interface foundation

## Approved direction

Native task-oriented phone app. Keep the original BetSafe brown identity and borrow the supplied IMG_3942.JPG / IMG_3943.JPG references' rounded matchup tickets, compact wallet area, prominent scoreboards and floating navigation. The user explicitly prefers brown with a little green; do not replace the brand with black/lime or yellow.

## Tokens

- Brown #57321F; deep brown #302016; cream surface #F7F2E9; ink #302419.
- Forest green #245B43 for primary actions and positive states; mint #DCEACD for selected controls and winning tickets.
- Clay #F0DCC9 for warm match details; secondary text #6B6055 on light ticket surfaces.
- System light/dark appearance; dark surface #241B16. Light ticket content keeps explicit dark foregrounds in both themes.
- Native Material text roles; bold title/headline weights. Controls and body follow system text scaling.
- Spacing 8, 12, 16, 20, 24, 28 logical pixels; body max width 640.
- Matchup panels use 24-pixel radii from the supplied references; action buttons use 16, floating navigation 32.

## Components and behavior

- Games / My picks / Collection are destinations. Focused pick and game views use pushed routes and system back.
- Cream base, brown feature panel and capsule navigation, forest-green actions. Green has meaning: selection and wins.
- Reuse SportsPanel, MatchTicket, TeamBadge and StatusPill in lib/widgets/sports_ui.dart.
- Team initials are placeholder badges, not official logos. Field yard markings are decorative football geometry, not live statistics.
- Show simulation labels on fixture games. Do not introduce deposits, withdrawals, real-money odds or fabricated sports statistics from the visual references.
- Preserve loading, retryable server errors, empty states, disabled submission and a scrollable layout at enlarged text sizes.
- Controls minimum 48 logical pixels; safe areas protect system bars. Phone navigation stays below scroll content so it never covers a matchup action.
