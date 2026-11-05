import 'package:betsafeproject5/models/game_time.dart';
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
}
