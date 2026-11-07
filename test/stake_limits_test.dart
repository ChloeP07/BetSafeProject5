import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

ChoiceChip chip(WidgetTester tester, int value) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '$value coins'));

void main() {
  testWidgets('a low balance disables the stakes it cannot cover', (
    tester,
  ) async {
    await pumpPick(tester, stateJson(coins: 120));
    expect(chip(tester, 50).onSelected, isNotNull);
    expect(chip(tester, 100).onSelected, isNotNull);
    expect(chip(tester, 250).onSelected, isNull);
    expect(
      find.text('Stakes over your 120-coin balance are unavailable.'),
      findsOneWidget,
    );
  });

  testWidgets('a nearly used daily limit disables larger stakes', (
    tester,
  ) async {
    await pumpPick(tester, stateJson(dailyStaked: 400));
    expect(chip(tester, 50).onSelected, isNotNull);
    expect(chip(tester, 100).onSelected, isNotNull);
    expect(chip(tester, 250).onSelected, isNull);
    expect(
      find.text(
        'Stakes over the 100 coins left in today’s limit are unavailable.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('with room for every stake, all are enabled and no caption', (
    tester,
  ) async {
    await pumpPick(tester, stateJson());
    for (final value in [50, 100, 250]) {
      expect(chip(tester, value).onSelected, isNotNull);
    }
    expect(find.textContaining('unavailable'), findsNothing);
  });
}
