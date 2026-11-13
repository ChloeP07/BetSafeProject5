import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'support/fixtures.dart';

FButton chip(WidgetTester tester, int value) =>
    tester.widget<FButton>(find.widgetWithText(FButton, '$value coins'));

void main() {
  testWidgets('a low balance disables the stakes it cannot cover', (
    tester,
  ) async {
    await pumpPick(tester, stateJson(coins: 120));
    expect(chip(tester, 50).onPress, isNotNull);
    expect(chip(tester, 100).onPress, isNotNull);
    expect(chip(tester, 250).onPress, isNull);
    expect(
      find.text('Stakes over your 120-coin balance are unavailable.'),
      findsOneWidget,
    );
  });

  testWidgets('a nearly used daily limit disables larger stakes', (
    tester,
  ) async {
    await pumpPick(tester, stateJson(dailyStaked: 400));
    expect(chip(tester, 50).onPress, isNotNull);
    expect(chip(tester, 100).onPress, isNotNull);
    expect(chip(tester, 250).onPress, isNull);
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
      expect(chip(tester, value).onPress, isNotNull);
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
      expect(chip(tester, value).onPress, isNull);
    }
    expect(find.textContaining('coins returned'), findsNothing);
  });

  testWidgets('out of coins explains the balance', (tester) async {
    await pumpPick(tester, stateJson(coins: 30));
    expect(find.textContaining('You have 30 virtual coins'), findsOneWidget);
    expect(find.textContaining('today’s stake limit'), findsNothing);
  });

  testWidgets('a used-up limit explains the limit', (tester) async {
    await pumpPick(tester, stateJson(dailyStaked: 500));
    expect(
      find.textContaining('You’ve used all of today’s stake limit.'),
      findsOneWidget,
    );
    expect(find.textContaining('virtual coins, less than'), findsNothing);
  });

  testWidgets('with a stake that fits there is no stake message', (
    tester,
  ) async {
    await pumpPick(tester, stateJson(coins: 120));
    expect(find.textContaining('Choose a smaller stake'), findsNothing);
    expect(find.textContaining('less than the smallest'), findsNothing);
  });
}
