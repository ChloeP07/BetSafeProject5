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

  testWidgets('starts at 50 when 100 does not fit', (tester) async {
    await pumpPick(tester, stateJson(coins: 80));
    expect(chip(tester, 50).selected, isTrue);
    expect(chip(tester, 100).selected, isFalse);
    expect(find.text('100 coins returned'), findsOneWidget);
  });

  testWidgets('a refresh that lowers the limit keeps a valid stake', (
    tester,
  ) async {
    final json = stateJson();
    final api = await pumpPick(tester, json);
    await tester.tap(find.text('250 coins'));
    await tester.pumpAndSettle();
    expect(chip(tester, 250).selected, isTrue);

    json['account'] = {
      'name': 'Demo player',
      'coins': 1000,
      'dailyLimit': 500,
      'dailyStaked': 350,
    };
    await api.refresh();
    await tester.pumpAndSettle();
    expect(chip(tester, 250).selected, isFalse);
    expect(chip(tester, 100).selected, isTrue);
    expect(find.text('200 coins returned'), findsOneWidget);
  });

  testWidgets('with no stake that fits, none is selected', (tester) async {
    await pumpPick(tester, stateJson(coins: 30));
    for (final value in [50, 100, 250]) {
      expect(chip(tester, value).selected, isFalse);
      expect(chip(tester, value).onSelected, isNull);
    }
    expect(find.textContaining('coins returned'), findsNothing);
  });
}
