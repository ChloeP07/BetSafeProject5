import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  testWidgets('asks for a team under the disabled button', (tester) async {
    await pumpPick(tester, stateJson());
    expect(find.text('Choose a team to continue.'), findsOneWidget);
    final below =
        tester.getTopLeft(find.text('Choose a team to continue.')).dy >
        tester.getBottomLeft(find.text('Lock in pick')).dy;
    expect(below, isTrue);
  });

  testWidgets('the hint goes once a team is chosen', (tester) async {
    await pumpPick(tester, stateJson());
    await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a team to continue.'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Lock in pick'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('says no stake fits when the coins have run out', (tester) async {
    await pumpPick(tester, stateJson(coins: 20));
    expect(find.text('No stake fits right now.'), findsOneWidget);
    expect(find.text('Choose a team to continue.'), findsNothing);
  });
}
