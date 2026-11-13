import 'package:betsafeproject5/models/game_time.dart';
import 'package:betsafeproject5/widgets/sports_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  // A Thursday, in the phone's local time.
  final now = DateTime(2030, 1, 10, 9, 30);

  group('friendlyKickoff', () {
    test('names nearby days', () {
      expect(
        friendlyKickoff(DateTime(2030, 1, 10, 19, 20), now: now),
        'Today · 7:20 PM',
      );
      expect(
        friendlyKickoff(DateTime(2030, 1, 11, 0, 5), now: now),
        'Tomorrow · 12:05 AM',
      );
      expect(
        friendlyKickoff(DateTime(2030, 1, 9, 12, 0), now: now),
        'Yesterday · 12:00 PM',
      );
    });

    test('uses weekday and date further out', () {
      expect(
        friendlyKickoff(DateTime(2030, 1, 13, 13, 0), now: now),
        'Sun 1/13 · 1:00 PM',
      );
    });

    test('rolls over a month end correctly', () {
      expect(
        friendlyKickoff(
          DateTime(2030, 2, 1, 8, 0),
          now: DateTime(2030, 1, 31, 23, 0),
        ),
        'Tomorrow · 8:00 AM',
      );
    });
  });

  test('a card without a kickoff keeps the game label', () {
    expect(gameFrom(demoGameJson()).kickoffLabel, 'Demo matchup');
  });

  group('kickoffCountdown', () {
    String? left(Duration duration) =>
        kickoffCountdown(now.add(duration), now: now);

    test('counts hours and minutes', () {
      expect(
        left(const Duration(hours: 2, minutes: 15)),
        'Kicks off in 2h 15m',
      );
      expect(left(const Duration(minutes: 45)), 'Kicks off in 45m');
      expect(left(const Duration(seconds: 30)), 'Kicks off in under a minute');
    });

    test('stays quiet past kickoff or more than a day out', () {
      expect(left(const Duration(minutes: -1)), isNull);
      expect(left(const Duration(hours: 25)), isNull);
    });
  });

  group('card countdown', () {
    Future<void> pumpCard(WidgetTester tester, Map<String, dynamic> json) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MatchTicket(game: gameFrom(json))),
          ),
        );
    final soon = DateTime.now().add(const Duration(hours: 3));

    testWidgets('shows on an open NFL game starting soon', (tester) async {
      await pumpCard(tester, nflGameJson(kickoff: soon));
      expect(find.textContaining('Kicks off in'), findsOneWidget);
    });

    testWidgets('stays off a live game and a far-off game', (tester) async {
      await pumpCard(tester, nflGameJson(status: 'live', kickoff: soon));
      expect(find.textContaining('Kicks off in'), findsNothing);
      await pumpCard(
        tester,
        nflGameJson(kickoff: DateTime.now().add(const Duration(days: 3))),
      );
      expect(find.textContaining('Kicks off in'), findsNothing);
    });
  });
}
