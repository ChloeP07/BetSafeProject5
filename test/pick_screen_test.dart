import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  group('kickoff note', () {
    testWidgets('shows on an NFL pick with the countdown', (tester) async {
      await pumpPick(
        tester,
        stateJson(
          nfl: nflOk(),
          games: [
            nflGameJson(kickoff: DateTime.now().add(const Duration(hours: 3))),
          ],
        ),
      );
      expect(find.text('Picks close at kickoff.'), findsOneWidget);
      expect(find.textContaining('Kicks off in'), findsOneWidget);
    });

    testWidgets('stays off a demo pick, which has no kickoff', (tester) async {
      await pumpPick(tester, stateJson());
      expect(find.text('Picks close at kickoff.'), findsNothing);
      expect(find.textContaining('Kicks off in'), findsNothing);
    });

    testWidgets('the countdown timer stops when leaving the screen', (
      tester,
    ) async {
      await pumpPick(tester, stateJson());
      await tester.pageBack();
      await tester.pumpAndSettle();
      // A timer left running would fail this test when it ends.
      await tester.pump(const Duration(seconds: 31));
      expect(find.text('Make a pick'), findsOneWidget);
    });
  });
}
