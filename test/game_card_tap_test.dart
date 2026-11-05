import 'package:betsafeproject5/screens/game_screen.dart';
import 'package:betsafeproject5/screens/pick_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  testWidgets('tapping an open card opens the pick screen', (tester) async {
    await pumpApp(tester, stateJson());
    await tester.tap(find.text('Buffalo Bills'));
    await tester.pumpAndSettle();
    expect(find.byType(PickScreen), findsOneWidget);
  });

  testWidgets('tapping a picked card opens the game view', (tester) async {
    await pumpApp(tester, stateJson(picks: [pickJson()]));
    await tester.tap(find.text('Buffalo Bills'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byType(PickScreen), findsNothing);
  });

  testWidgets('tapping a finished card opens the game view', (tester) async {
    await pumpApp(
      tester,
      stateJson(
        games: [demoGameJson(status: 'final', awayScore: 20, homeScore: 27)],
      ),
    );
    await tester.tap(find.text('Buffalo Bills'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('the button still works, and opens the same screen once', (
    tester,
  ) async {
    await pumpApp(tester, stateJson());
    await tester.tap(find.text('Make a pick'));
    await tester.pumpAndSettle();
    expect(find.byType(PickScreen), findsOneWidget);
  });

  testWidgets('screen readers hear one action for the card', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, stateJson());
    expect(find.bySemanticsLabel('Make a pick'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Kansas City Chiefs at Buffalo Bills. Demo matchup.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
