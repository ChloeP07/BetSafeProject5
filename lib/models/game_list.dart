import 'demo_state.dart';
import 'game_status.dart';
import 'nfl_teams.dart';

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

String gameCountLabel(int count) => count == 1 ? '1 game' : '$count games';

/// What the button on a game card does for this game and pick.
String gameActionLabel(Game game, Pick? pick) {
  if (pick != null) {
    return pick.status == 'pending' ? 'View your pick' : 'View result';
  }
  if (game.canPick) return 'Make a pick';
  return game.status == 'final' ? 'View result' : 'View game';
}

/// One line about a list, such as "2 live · 5 open · 1 picked". Zero counts are
/// left out, so a list with nothing to report gives an empty string.
String gameSummary(Iterable<Game> games, Iterable<Pick> picks) {
  final ids = games.map((game) => game.id).toSet();
  final live = games.where((game) => game.tone == GameTone.live).length;
  final open = games.where((game) => game.tone == GameTone.open).length;
  final picked = picks.where((pick) => ids.contains(pick.gameId)).length;
  return [
    if (live > 0) '$live live',
    if (open > 0) '$open open',
    if (picked > 0) '$picked picked',
  ].join(' · ');
}

/// The status filter chips above the list.
enum GameFilter {
  all('All'),
  open('Open'),
  live('Live'),
  finished('Final');

  const GameFilter(this.label);
  final String label;

  bool matches(Game game) => switch (this) {
    GameFilter.all => true,
    GameFilter.open => game.tone == GameTone.open,
    GameFilter.live => game.tone == GameTone.live,
    GameFilter.finished => game.tone == GameTone.finished,
  };
}

/// True when either team's name or abbreviation contains [query]. A blank
/// query matches every game.
bool matchesTeamSearch(Game game, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return [
    game.away,
    game.home,
    teamCode(game.away),
    teamCode(game.home),
  ].any((value) => value.toLowerCase().contains(needle));
}

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
