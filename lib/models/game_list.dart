import 'demo_state.dart';
import 'game_status.dart';

/// Live games come first, then upcoming games, then anything waiting on an
/// update, and finished games last.
int gameStatusRank(String status) => switch (status) {
  'live' => 0,
  'scheduled' => 1,
  'final' => 3,
  _ => 2,
};

/// Dart's sort is not stable, so the id breaks ties for games with no kickoff.
int compareGames(Game a, Game b) {
  final byStatus = gameStatusRank(a.status).compareTo(gameStatusRank(b.status));
  if (byStatus != 0) return byStatus;
  final byKickoff = (a.kickoff ?? DateTime(2000)).compareTo(
    b.kickoff ?? DateTime(2000),
  );
  return byKickoff != 0 ? byKickoff : a.id.compareTo(b.id);
}

/// The games for one side of the NFL/demo toggle, in display order.
List<Game> gamesForSource(Iterable<Game> games, {required bool simulation}) =>
    games.where((game) => game.isSimulation == simulation).toList()
      ..sort(compareGames);

class GameSection {
  const GameSection(this.title, this.games);
  final String title;
  final List<Game> games;
}

/// Splits games into list sections, leaving out any section with no games.
/// Finished games show the most recent first; the rest keep their given order.
List<GameSection> groupGames(Iterable<Game> games) {
  List<Game> withTone(GameTone tone) =>
      games.where((game) => game.tone == tone).toList();
  final finished = withTone(GameTone.finished)
    ..sort((a, b) {
      final byKickoff = (b.kickoff ?? DateTime(2000)).compareTo(
        a.kickoff ?? DateTime(2000),
      );
      return byKickoff != 0 ? byKickoff : a.id.compareTo(b.id);
    });
  return [
    GameSection('Live now', withTone(GameTone.live)),
    GameSection('Open for picks', withTone(GameTone.open)),
    GameSection('Waiting for an update', withTone(GameTone.waiting)),
    GameSection('Finished', finished),
  ].where((section) => section.games.isNotEmpty).toList();
}
