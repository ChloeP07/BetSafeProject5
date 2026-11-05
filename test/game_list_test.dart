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
}
