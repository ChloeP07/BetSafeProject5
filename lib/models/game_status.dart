import 'demo_state.dart';
import 'game_time.dart';
import 'nfl_teams.dart';

/// What a game's status means for the player, whatever the feed calls it.
enum GameTone { open, live, waiting, finished }

extension GameStatusText on Game {
  GameTone get tone => switch (status) {
    'live' => GameTone.live,
    'final' || 'canceled' || 'abandoned' => GameTone.finished,
    _ => canPick ? GameTone.open : GameTone.waiting,
  };

  /// Short text for the card's status pill. Simulations always say so.
  String get statusLabel => switch (status) {
    'scheduled' =>
      isSimulation
          ? 'Demo matchup'
          : canPick
          ? 'Scheduled'
          : 'Awaiting update',
    'live' => isSimulation ? 'Simulation · live' : 'In progress',
    'final' => isSimulation ? 'Simulation · final' : 'Final',
    'postponed' => 'Postponed',
    'canceled' => 'Canceled',
    'delayed' => 'Delayed',
    'suspended' => 'Suspended',
    'abandoned' => 'Abandoned',
    _ => 'Status unknown',
  };

  /// The winner of a finished game. Null if a score is missing or the game tied.
  String? get winner {
    final (awayPoints, homePoints) = (awayScore, homeScore);
    if (status != 'final' || awayPoints == null || homePoints == null) {
      return null;
    }
    if (awayPoints == homePoints) return null;
    return awayPoints > homePoints ? away : home;
  }

  /// One sentence-style summary of the card for screen readers.
  String get matchupDescription {
    final parts = [
      '$away at $home.',
      '${statusLabel.replaceAll(' · ', ', ')}.',
    ];
    if (status != 'scheduled' && (awayScore != null || homeScore != null)) {
      parts.add(
        '${teamShortName(away)} ${awayScore ?? 'no score'}, '
        '${teamShortName(home)} ${homeScore ?? 'no score'}.',
      );
    }
    if (winner case final team?) parts.add('${teamShortName(team)} won.');
    if (!isSimulation && kickoff != null) {
      parts.add(
        'Kickoff ${friendlyKickoff(kickoff!).replaceAll(' · ', ' at ')}.',
      );
    }
    return parts.join(' ');
  }
}
