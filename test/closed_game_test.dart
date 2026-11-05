import 'package:betsafeproject5/models/game_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  final soon = DateTime.now().add(const Duration(hours: 3));
  final past = DateTime.now().subtract(const Duration(hours: 3));

  group('closedReason', () {
    test('is empty while picks are open', () {
      expect(gameFrom(demoGameJson()).closedReason, isNull);
      expect(gameFrom(nflGameJson(kickoff: soon)).closedReason, isNull);
    });

    test('explains each NFL status', () {
      const expected = {
        'live': 'Picks closed at kickoff.',
        'final': 'This game has finished.',
        'postponed': 'Picks are paused while this game is postponed.',
        'delayed': 'Picks are paused while this game is delayed.',
        'suspended': 'Picks are paused while this game is suspended.',
        'canceled': 'This game was canceled. Any stake on it is returned.',
        'abandoned': 'This game was abandoned. Any stake on it is returned.',
        'unknown':
            'Picks are paused until the feed reports this game’s status.',
      };
      expected.forEach((status, reason) {
        expect(gameFrom(nflGameJson(status: status)).closedReason, reason);
      });
    });

    test('explains a scheduled NFL game past kickoff', () {
      expect(
        gameFrom(nflGameJson(kickoff: past)).closedReason,
        'Kickoff has passed, so picks are closed for this game.',
      );
    });

    test('names simulations as simulations', () {
      expect(
        gameFrom(demoGameJson(status: 'live')).closedReason,
        'Picks closed when the simulation started.',
      );
      expect(
        gameFrom(demoGameJson(status: 'final')).closedReason,
        'This simulation has finished.',
      );
    });
  });

  group('game card', () {
    testWidgets('replaces the coin return line with the reason', (
      tester,
    ) async {
      await pumpApp(
        tester,
        stateJson(
          nfl: nflOk(),
          games: [nflGameJson(status: 'postponed', kickoff: soon)],
        ),
      );
      expect(
        find.text('Picks are paused while this game is postponed.'),
        findsOneWidget,
      );
      expect(find.textContaining('2×'), findsNothing);
    });

    testWidgets('keeps the coin return line while picks are open', (
      tester,
    ) async {
      await pumpApp(tester, stateJson());
      expect(find.text('2× demo return · virtual coins only'), findsOneWidget);
    });
  });

  group('score line', () {
    testWidgets('a game that never got a score stays VS', (tester) async {
      await pumpTicket(tester, nflGameJson(status: 'postponed'));
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('– : –'), findsNothing);
      expect(find.text('Score'), findsNothing);
    });

    testWidgets('a canceled game with a partial score shows it', (
      tester,
    ) async {
      await pumpTicket(
        tester,
        nflGameJson(status: 'canceled', awayScore: 3, homeScore: 0),
      );
      expect(find.text('3 : 0'), findsOneWidget);
    });

    testWidgets('a live game with no score yet keeps its score line', (
      tester,
    ) async {
      await pumpTicket(tester, nflGameJson(status: 'live'));
      expect(find.text('– : –'), findsOneWidget);
      expect(find.text('Live score'), findsOneWidget);
    });
  });
}
