import 'demo_state.dart';
import 'nfl_teams.dart';

/// The stakes the server accepts, in coins.
const stakeOptions = [50, 100, 250];

/// Why a pick cannot be locked in yet.
///
/// These explain the server's rules ahead of time so the screen can say what
/// to do next. The server still checks every pick and has the final word.
enum PickBlock {
  /// The game is not open for picks, for example because it kicked off.
  closed,

  /// A pick for this game already exists.
  alreadyPicked,

  /// The NFL data is stale or failed to load, so the server would turn down
  /// a pick for a real game until a refresh succeeds.
  staleData,

  /// No stake fits the balance and what is left of today's limit.
  noAffordableStake,

  /// No team is chosen yet.
  noTeam,

  /// No stake is chosen yet.
  noStake,

  /// The chosen stake is more than the balance.
  lowBalance,

  /// The chosen stake is more than what is left of today's limit.
  dailyLimit,
}

/// Whether [stake] fits both the balance and what is left of today's limit.
bool canAffordStake(
  int stake, {
  required int coins,
  required int dailyRemaining,
}) => stake <= coins && stake <= dailyRemaining;

/// The stake that fits when no other choice is made.
const defaultStake = 100;

/// The stake to use: [chosen] while it fits, otherwise [defaultStake] if it
/// fits, otherwise the largest stake that fits. Null when no stake fits.
///
/// Running this on every refresh keeps the choice valid when the balance or
/// today's limit changes.
int? validStake(
  int? chosen, {
  required int coins,
  required int dailyRemaining,
}) {
  bool fits(int value) =>
      canAffordStake(value, coins: coins, dailyRemaining: dailyRemaining);
  if (chosen != null && stakeOptions.contains(chosen) && fits(chosen)) {
    return chosen;
  }
  if (fits(defaultStake)) return defaultStake;
  final allowed = stakeOptions.where(fits);
  return allowed.isEmpty ? null : allowed.last;
}

/// Explains why some stakes are unavailable, or null when every stake fits.
/// Names whichever of the balance and today's limit is lower.
String? stakeCaption({required int coins, required int dailyRemaining}) {
  final allFit = stakeOptions.every(
    (value) =>
        canAffordStake(value, coins: coins, dailyRemaining: dailyRemaining),
  );
  if (allFit) return null;
  return coins <= dailyRemaining
      ? 'Stakes over your $coins-coin balance are unavailable.'
      : 'Stakes over the $dailyRemaining coins left in today’s limit are unavailable.';
}

/// Explains that no stake fits, naming the balance or today's limit, or null
/// when at least one stake fits.
String? noStakeMessage({required int coins, required int dailyRemaining}) {
  final smallest = stakeOptions.first;
  if (canAffordStake(smallest, coins: coins, dailyRemaining: dailyRemaining)) {
    return null;
  }
  if (coins < smallest && coins <= dailyRemaining) {
    return 'You have $coins virtual coins, less than the smallest '
        '$smallest-coin stake. Winning picks return coins when their games '
        'finish.';
  }
  final used = dailyRemaining <= 0
      ? 'You’ve used all of today’s stake limit.'
      : 'Only $dailyRemaining coins are left in today’s stake limit, less '
            'than the smallest $smallest-coin stake.';
  return '$used You can pick again after it resets at midnight UTC.';
}

/// A message for a stake problem, or null when [block] is not about the
/// stake.
String? stakeProblemMessage(
  PickBlock? block, {
  required int? stake,
  required int coins,
  required int dailyRemaining,
}) => switch (block) {
  PickBlock.lowBalance =>
    'A $stake-coin stake is more than your $coins-coin balance. '
        'Choose a smaller stake.',
  PickBlock.dailyLimit =>
    'A $stake-coin stake is more than the $dailyRemaining coins left in '
        'today’s limit. Choose a smaller stake.',
  PickBlock.noAffordableStake => noStakeMessage(
    coins: coins,
    dailyRemaining: dailyRemaining,
  ),
  _ => null,
};

/// A short line for under a disabled Lock in button, saying what to do next.
String? lockInHint(PickBlock? block) => switch (block) {
  null || PickBlock.alreadyPicked => null,
  PickBlock.closed => 'Picks are closed for this game.',
  PickBlock.staleData => 'Refresh the NFL data to continue.',
  PickBlock.noAffordableStake => 'No stake fits right now.',
  PickBlock.noTeam => 'Choose a team to continue.',
  PickBlock.noStake => 'Choose a stake to continue.',
  PickBlock.lowBalance ||
  PickBlock.dailyLimit => 'Choose a smaller stake to continue.',
};

/// The first reason a pick is blocked, or null when it can be sent.
PickBlock? pickBlock({
  required Game game,
  required bool picked,
  required String? team,
  required int? stake,
  required int coins,
  required int dailyRemaining,
  bool nflDataStale = false,
}) {
  if (picked) return PickBlock.alreadyPicked;
  if (!game.canPick) return PickBlock.closed;
  if (nflDataStale && !game.isSimulation) return PickBlock.staleData;
  final anyAffordable = stakeOptions.any(
    (value) =>
        canAffordStake(value, coins: coins, dailyRemaining: dailyRemaining),
  );
  if (!anyAffordable) return PickBlock.noAffordableStake;
  if (team == null) return PickBlock.noTeam;
  if (stake == null) return PickBlock.noStake;
  if (stake > coins) return PickBlock.lowBalance;
  if (stake > dailyRemaining) return PickBlock.dailyLimit;
  return null;
}

/// The confirmation shown once the server has accepted a pick.
String pickLockedMessage(String team, int stake) =>
    'Pick locked: ${teamShortName(team)} · $stake coins';
