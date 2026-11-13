import 'package:betsafeproject5/screens/game_screen.dart';
import 'package:betsafeproject5/screens/pick_screen.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  testWidgets('tapping an open card opens the pick screen', (tester) async {
    await pumpApp(tester, stateJson());
    await tester.tap(find.text('Bills'));
    await tester.pumpAndSettle();
    expect(find.byType(PickScreen), findsOneWidget);
    // A tap on the card itself chooses no team yet.
    final options = tester.widgetList<TeamOptionCard>(
      find.byType(TeamOptionCard),
    );
    expect(options.any((option) => option.selected), isFalse);
  });

  testWidgets('tapping a picked card opens the game view', (tester) async {
    await pumpApp(tester, stateJson(picks: [pickJson()]));
    await tester.tap(find.text('Bills'));
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
    await tester.tap(find.text('Bills'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('a team button opens the pick with that team chosen', (
    tester,
  ) async {
    await pumpApp(tester, stateJson());
    await tester.tap(find.text('Pick BUF'));
    await tester.pumpAndSettle();
    expect(find.byType(PickScreen), findsOneWidget);
    expect(
      tester
          .widget<TeamOptionCard>(
            find.widgetWithText(TeamOptionCard, 'Buffalo Bills'),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('screen readers hear the matchup and both team buttons', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, stateJson());
    expect(
      find.bySemanticsLabel(
        'Kansas City Chiefs at Buffalo Bills. Demo matchup.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Pick KC'), findsOneWidget);
    expect(find.bySemanticsLabel('Pick BUF'), findsOneWidget);
    semantics.dispose();
  });
}
