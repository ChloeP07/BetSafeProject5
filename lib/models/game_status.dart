import 'demo_state.dart';

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
}
