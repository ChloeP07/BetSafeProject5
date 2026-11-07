/// Friendlier wording, with a next step, for the errors the server sends when
/// it rejects a pick. Keys match server/src/store.js exactly. Any other
/// message is shown as the server wrote it.
const _friendly = {
  'Game not found.':
      'This game is no longer on the schedule. Go back to the games list to '
      'choose another.',
  'Picks are closed for this game.':
      'Picks just closed for this game. Go back to the games list to choose '
      'another.',
  'Fresh NFL data is needed before accepting this pick. Try refreshing.':
      'The NFL schedule needs a refresh before this pick can be saved. Tap '
      'Try again, then lock in your pick.',
  'Picks close at kickoff.':
      'This game has kicked off, so picks are closed. Go back to the games '
      'list to choose another.',
  'Choose a team in this game.':
      'That team isn’t in this game. Choose one of the two teams above.',
  'Choose a stake of 50, 100, or 250 coins.':
      'That stake isn’t available. Choose 50, 100 or 250 coins.',
  'You already picked this game.':
      'You already picked this game. Tap Try again to see your pick.',
  'Not enough virtual coins.':
      'You don’t have enough virtual coins for that stake. Choose a smaller '
      'stake.',
  'Daily stake limit reached.':
      'That stake would go over today’s limit. Choose a smaller stake, or '
      'come back after the limit resets at midnight UTC.',
};

/// The friendly version of a pick error from the server, or [message]
/// unchanged when it is not one the app knows.
String friendlyPickError(String message) => _friendly[message] ?? message;
