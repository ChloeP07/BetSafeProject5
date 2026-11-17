import 'package:betsafeproject5/models/demo_state.dart';
import 'package:betsafeproject5/models/game_list.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  group('gamesForSource', () {
    test('keeps NFL and demo games apart', () {
      final games = [
        gameFrom(demoGameJson(id: 'demo-1')),
        gameFrom(nflGameJson(id: 'bdl-1')),
      ];
      expect(gamesForSource(games, simulation: true).map((g) => g.id), [
        'demo-1',
      ]);
      expect(gamesForSource(games, simulation: false).map((g) => g.id), [
        'bdl-1',
      ]);
    });

    test('orders live, then scheduled, then waiting, then final', () {
      final kickoff = DateTime.utc(2030, 1, 1);
      final games = [
        gameFrom(nflGameJson(id: 'f', status: 'final', kickoff: kickoff)),
        gameFrom(nflGameJson(id: 'p', status: 'postponed', kickoff: kickoff)),
        gameFrom(nflGameJson(id: 's', kickoff: kickoff)),
        gameFrom(nflGameJson(id: 'l', status: 'live', kickoff: kickoff)),
      ];
      expect(gamesForSource(games, simulation: false).map((g) => g.id), [
        'l',
        's',
        'p',
        'f',
      ]);
    });

    test('orders by kickoff within a status', () {
      final games = [
        gameFrom(nflGameJson(id: 'later', kickoff: DateTime.utc(2030, 1, 2))),
        gameFrom(nflGameJson(id: 'soon', kickoff: DateTime.utc(2030, 1, 1))),
      ];
      expect(gamesForSource(games, simulation: false).map((g) => g.id), [
        'soon',
        'later',
      ]);
    });

    test('keeps a stable order for games with no kickoff', () {
      final games = [
        gameFrom(demoGameJson(id: 'demo-3')),
        gameFrom(demoGameJson(id: 'demo-1')),
        gameFrom(demoGameJson(id: 'demo-2')),
      ];
      expect(gamesForSource(games, simulation: true).map((g) => g.id), [
        'demo-1',
        'demo-2',
        'demo-3',
      ]);
    });
  });

  test('GameFilter sorts statuses into the matching chip', () {
    final soon = DateTime.now().add(const Duration(hours: 3));
    final open = gameFrom(nflGameJson(kickoff: soon));
    final live = gameFrom(nflGameJson(status: 'live', kickoff: soon));
    final done = gameFrom(nflGameJson(status: 'final', kickoff: soon));
    final off = gameFrom(nflGameJson(status: 'canceled', kickoff: soon));
    final wait = gameFrom(nflGameJson(status: 'delayed', kickoff: soon));
    final all = [open, live, done, off, wait];
    expect(all.where(GameFilter.all.matches), hasLength(5));
    expect(all.where(GameFilter.open.matches), [open]);
    expect(all.where(GameFilter.live.matches), [live]);
    expect(all.where(GameFilter.finished.matches), [done, off]);
  });

  group('gameActionLabel', () {
    final soon = DateTime.now().add(const Duration(hours: 3));
    final open = gameFrom(nflGameJson(kickoff: soon));
    Pick pick(String status) =>
        demoState(stateJson(picks: [pickJson(status: status)])).picks.single;

    test('an open game with no pick invites one', () {
      expect(gameActionLabel(open, null), 'Make a pick');
    });

    test('a pending pick can be viewed', () {
      expect(gameActionLabel(open, pick('pending')), 'View your pick');
    });

    test('a settled pick shows its result', () {
      for (final status in ['won', 'lost', 'refunded']) {
        expect(gameActionLabel(open, pick(status)), 'View result');
      }
    });

    test('a game with no pick follows its status', () {
      expect(
        gameActionLabel(gameFrom(nflGameJson(status: 'final')), null),
        'View result',
      );
      expect(
        gameActionLabel(gameFrom(nflGameJson(status: 'live')), null),
        'View game',
      );
      expect(
        gameActionLabel(gameFrom(nflGameJson(status: 'postponed')), null),
        'View game',
      );
    });
  });

  group('matchesTeamSearch', () {
    final game = gameFrom(
      demoGameJson(away: 'Kansas City Chiefs', home: 'Buffalo Bills'),
    );

    test('matches either team by part of its name, in any case', () {
      expect(matchesTeamSearch(game, 'chiefs'), isTrue);
      expect(matchesTeamSearch(game, 'BUFF'), isTrue);
      expect(matchesTeamSearch(game, 'kansas city'), isTrue);
    });

    test('matches abbreviations', () {
      expect(matchesTeamSearch(game, 'kc'), isTrue);
      expect(matchesTeamSearch(game, 'buf'), isTrue);
    });

    test('a blank query matches, and an unrelated one does not', () {
      expect(matchesTeamSearch(game, '   '), isTrue);
      expect(matchesTeamSearch(game, 'packers'), isFalse);
    });
  });

  group('groupGames', () {
    final soon = DateTime.now().add(const Duration(hours: 3));
    final past = DateTime.now().subtract(const Duration(hours: 3));

    test('sorts each status into its section, in a fixed order', () {
      final sections = groupGames([
        gameFrom(nflGameJson(id: 'done', status: 'final', kickoff: past)),
        gameFrom(nflGameJson(id: 'off', status: 'canceled', kickoff: past)),
        gameFrom(nflGameJson(id: 'wait', status: 'postponed', kickoff: soon)),
        gameFrom(nflGameJson(id: 'late', kickoff: past)),
        gameFrom(nflGameJson(id: 'open', kickoff: soon)),
        gameFrom(nflGameJson(id: 'live', status: 'live', kickoff: past)),
      ]);
      expect(sections.map((section) => section.title), [
        'Live now',
        'Open for picks',
        'Waiting for an update',
        'Finished',
      ]);
      expect(sections[0].games.map((g) => g.id), ['live']);
      expect(sections[1].games.map((g) => g.id), ['open']);
      expect(sections[2].games.map((g) => g.id), containsAll(['wait', 'late']));
      expect(sections[3].games.map((g) => g.id), containsAll(['done', 'off']));
    });

    test('leaves out empty sections', () {
      final sections = groupGames([gameFrom(demoGameJson())]);
      expect(sections.map((section) => section.title), ['Open for picks']);
    });

    test('shows the most recent finished game first', () {
      final sections = groupGames([
        gameFrom(
          nflGameJson(
            id: 'old',
            status: 'final',
            kickoff: DateTime.utc(2030, 1, 1),
          ),
        ),
        gameFrom(
          nflGameJson(
            id: 'new',
            status: 'final',
            kickoff: DateTime.utc(2030, 1, 8),
          ),
        ),
      ]);
      expect(sections.single.games.map((g) => g.id), ['new', 'old']);
    });

    test('an empty list has no sections', () {
      expect(groupGames(const []), isEmpty);
    });
  });
}
