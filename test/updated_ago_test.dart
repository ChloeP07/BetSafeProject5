import 'package:betsafeproject5/models/game_time.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  final now = DateTime.utc(2030, 1, 10, 12);
  String ago(Duration age) => updatedAgo(now.subtract(age), now: now);

  group('updatedAgo', () {
    test('counts minutes, then hours', () {
      expect(ago(const Duration(seconds: 20)), 'Updated just now');
      expect(ago(const Duration(minutes: 1)), 'Updated 1 min ago');
      expect(ago(const Duration(minutes: 59)), 'Updated 59 min ago');
      expect(ago(const Duration(minutes: 60)), 'Updated 1 hr ago');
      expect(ago(const Duration(hours: 5)), 'Updated 5 hr ago');
    });

    test('a phone clock behind the server reads as just now', () {
      expect(ago(const Duration(minutes: -3)), 'Updated just now');
    });
  });

  group('NFL list', () {
    Map<String, dynamic> fetched(Duration age) => {
      ...nflOk(),
      'fetchedAt': DateTime.now().subtract(age).toUtc().toIso8601String(),
    };

    testWidgets('shows when the schedule was last updated', (tester) async {
      await pumpApp(
        tester,
        stateJson(
          nfl: fetched(const Duration(minutes: 3)),
          games: [nflGameJson()],
        ),
      );
      expect(find.text('Updated 3 min ago'), findsOneWidget);
    });

    testWidgets('still shows it when the feed has a problem', (tester) async {
      await pumpApp(
        tester,
        stateJson(
          nfl: {
            ...fetched(const Duration(minutes: 12)),
            'stale': true,
            'error': 'NFL provider is unavailable. Try again shortly.',
          },
          games: [nflGameJson()],
        ),
      );
      expect(find.text('Updated 12 min ago'), findsOneWidget);
    });

    testWidgets('stays away when nothing has been fetched', (tester) async {
      await pumpApp(
        tester,
        stateJson(
          nfl: {'configured': true, 'stale': true},
          games: [nflGameJson()],
        ),
      );
      expect(find.textContaining('Updated'), findsNothing);
    });

    testWidgets('stays away on the demo list', (tester) async {
      await pumpApp(tester, stateJson());
      expect(find.textContaining('Updated'), findsNothing);
    });
  });
}
