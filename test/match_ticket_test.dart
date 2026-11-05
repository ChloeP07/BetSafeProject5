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
  testWidgets('a final card fits a narrow phone at large text', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpTicket(
      tester,
      demoGameJson(status: 'final', awayScore: 20, homeScore: 27),
    );
    expect(find.text('Winner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tags each team Away or Home', (tester) async {
    await pumpTicket(tester, demoGameJson());
    expect(find.text('Away'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Away / Home'), findsNothing);
    final chiefs = tester.getTopLeft(find.text('Kansas City Chiefs')).dx;
    final bills = tester.getTopLeft(find.text('Buffalo Bills')).dx;
    expect(tester.getCenter(find.text('Away')).dx, lessThan(bills));
    expect(tester.getCenter(find.text('Home')).dx, greaterThan(chiefs));
  });

  group('tied game', () {
    final tied = nflGameJson(status: 'final', awayScore: 20, homeScore: 20);

    testWidgets('says Tied and highlights nobody', (tester) async {
      await pumpTicket(tester, tied);
      expect(find.text('Tied'), findsOneWidget);
      expect(find.text('Final score'), findsNothing);
      expect(find.text('Winner'), findsNothing);
    });

    test('is read out for screen readers', () {
      expect(gameFrom(tied).matchupDescription, contains('Tied.'));
      expect(gameFrom(tied).winner, isNull);
    });

    test('a live game with level scores is not tied', () {
      expect(
        gameFrom(nflGameJson(status: 'live', awayScore: 7, homeScore: 7))
            .isTied,
        isFalse,
      );
    });

    testWidgets('a final with a missing score is not called tied', (
      tester,
    ) async {
      await pumpTicket(tester, nflGameJson(status: 'final'));
      expect(find.text('Tied'), findsNothing);
    });
  });

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
