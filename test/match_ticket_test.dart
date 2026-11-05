import 'package:betsafeproject5/models/game_status.dart';
import 'package:betsafeproject5/widgets/sports_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

Future<void> pumpTicket(WidgetTester tester, Map<String, dynamic> json) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MatchTicket(game: gameFrom(json))),
      ),
    );

void main() {
  group('winner', () {
    testWidgets('marks the winning team on a final card', (tester) async {
      await pumpTicket(
        tester,
        nflGameJson(status: 'final', awayScore: 17, homeScore: 24),
      );
      expect(find.text('Winner'), findsOneWidget);
      expect(
        gameFrom(nflGameJson(status: 'final', awayScore: 17, homeScore: 24))
            .winner,
        'Buffalo Bills',
      );
    });

    test('can be the away team', () {
      expect(
        gameFrom(nflGameJson(status: 'final', awayScore: 30, homeScore: 24))
            .winner,
        'Kansas City Chiefs',
      );
    });

    testWidgets('is not shown while a game is still live', (tester) async {
      await pumpTicket(
        tester,
        nflGameJson(status: 'live', awayScore: 17, homeScore: 24),
      );
      expect(find.text('Winner'), findsNothing);
    });

    testWidgets('is not guessed when a final score is missing', (tester) async {
      await pumpTicket(tester, nflGameJson(status: 'final', awayScore: 17));
      expect(find.text('Winner'), findsNothing);
    });

    test('is read out for screen readers', () {
      expect(
        gameFrom(nflGameJson(status: 'final', awayScore: 17, homeScore: 24))
            .matchupDescription,
        contains('Bills won.'),
      );
    });
  });
}
