import 'package:betsafeproject5/models/demo_state.dart';
import 'package:betsafeproject5/models/game_list.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  final soon = DateTime.now().add(const Duration(hours: 3));
  List<Pick> picks(List<Map<String, dynamic>> json) =>
      demoState(stateJson(picks: json)).picks;

  group('gameSummary', () {
    test('counts live, open and picked games', () {
      final games = [
        gameFrom(nflGameJson(id: 'a', status: 'live', kickoff: soon)),
        gameFrom(nflGameJson(id: 'b', status: 'live', kickoff: soon)),
        gameFrom(nflGameJson(id: 'c', kickoff: soon)),
        gameFrom(nflGameJson(id: 'd', status: 'final', kickoff: soon)),
      ];
      expect(
        gameSummary(games, picks([pickJson(gameId: 'c')])),
        '2 live · 1 open · 1 picked',
      );
    });

    test('leaves out counts of zero', () {
      expect(gameSummary([gameFrom(demoGameJson())], const []), '1 open');
    });

    test('is empty when there is nothing to report', () {
      expect(gameSummary(const [], const []), isEmpty);
      expect(
        gameSummary([gameFrom(demoGameJson(status: 'final'))], const []),
        isEmpty,
      );
    });

    test('ignores picks on games from the other list', () {
      expect(
        gameSummary([
          gameFrom(demoGameJson()),
        ], picks([pickJson(gameId: 'bdl-9')])),
        '1 open',
      );
    });
  });

  testWidgets('the Games screen shows the summary', (tester) async {
    await pumpApp(
      tester,
      stateJson(
        games: [
          demoGameJson(id: 'demo-1'),
          demoGameJson(id: 'demo-2'),
        ],
        picks: [pickJson(gameId: 'demo-1')],
      ),
    );
    expect(find.text('2 open · 1 picked'), findsOneWidget);
  });
}
