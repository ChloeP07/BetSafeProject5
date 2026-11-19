import 'package:betsafeproject5/screens/game_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

/// A live game, which opens the game view rather than the pick screen.
Map<String, dynamic> liveState() => stateJson(
  nfl: nflOk(),
  games: [nflGameJson(status: 'live', awayScore: 14, homeScore: 10)],
);

void main() {
  group('the game view, when its game leaves the server data', () {
    testWidgets('says so instead of crashing', (tester) async {
      final json = liveState();
      final api = await pumpApp(tester, json);
      await openGame(tester);
      expect(find.byType(GameScreen), findsOneWidget);
      json['games'] = <Map<String, dynamic>>[];
      await tester.tap(find.text('Refresh scores'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('This game is no longer available'), findsOneWidget);
      expect(find.text('Refresh scores'), findsNothing);
      expect(api.error, isNull);
    });

    testWidgets('Back to games returns to the list', (tester) async {
      final json = liveState();
      await pumpApp(tester, json);
      await openGame(tester);
      json['games'] = <Map<String, dynamic>>[];
      await tester.tap(find.text('Refresh scores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to games'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsNothing);
      expect(find.text('Hey,'), findsOneWidget);
    });
  });

  testWidgets('My picks keeps a pick whose game is gone, without crashing', (
    tester,
  ) async {
    await pumpApp(
      tester,
      stateJson(
        games: [],
        picks: [pickJson(gameId: 'gone-1', team: 'Detroit Lions', stake: 50)],
      ),
    );
    await tester.tap(find.text('My picks'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.text('This game is no longer in the schedule.'),
      findsOneWidget,
    );
    expect(find.text('Detroit Lions'), findsOneWidget);
    expect(find.text('50 coins staked'), findsOneWidget);
  });
}
