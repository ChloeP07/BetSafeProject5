# BetSafe interface foundation

## Approved direction

Native task-oriented phone app. Use the approved bold yellow Games mockup as the shared visual foundation: an ink feature card, warm paper background, white tickets and a floating capsule navigation bar.

## Tokens

- Dark brown #302016; yellow #F7C948; paper #EFEDE8; soft button surface #F3F0EA; white cards; muted light-surface text #555049.
- Use yellow for selection and highlights. Forest green and mint indicate wins; muted red indicates losses.
- Inter throughout. Bold, readable headings and scores; controls and body follow system text scaling.
- Spacing 8, 12, 16, 20, 24, 28 logical pixels; body max width 640.
- Matchup panels use 24-pixel radii from the supplied references; action buttons use 16, floating navigation 32.

## Components and behavior

- Games / My picks / Collection are destinations. Focused pick and game views use pushed routes and system back.
- Paper base, ink feature panel and capsule navigation, ink primary actions. Use white tickets and reserve green for positive results.
- Reuse SportsPanel, MatchTicket, TeamBadge and StatusPill in lib/widgets/sports_ui.dart.
- Team badges prefer feed logos, then ESPN team images, with abbreviations as a fallback. Field yard markings are decorative football geometry, not live statistics.
- Show simulation labels on fixture games. Do not introduce deposits, withdrawals, real-money odds or fabricated sports statistics from the visual references.
- Preserve loading, retryable server errors, empty states, disabled submission and a scrollable layout at enlarged text sizes.
- Controls minimum 48 logical pixels; safe areas protect system bars. Phone navigation stays below scroll content so it never covers a matchup action.
