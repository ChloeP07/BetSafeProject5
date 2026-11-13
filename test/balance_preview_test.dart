import 'package:betsafeproject5/widgets/balance_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  testWidgets('shows the balance before and after the stake', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BalancePreview(coins: 1000, stake: 250)),
      ),
    );
    expect(find.text('1000 coins'), findsOneWidget);
    expect(find.text('After this pick'), findsOneWidget);
    expect(find.text('750 coins'), findsOneWidget);
  });

  testWidgets('with no stake, shows only the balance now', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BalancePreview(coins: 30, stake: null)),
      ),
    );
    expect(find.text('30 coins'), findsOneWidget);
    expect(find.text('After this pick'), findsNothing);
  });

  testWidgets('the pick screen updates the preview with the stake', (
    tester,
  ) async {
    await pumpPick(tester, stateJson(coins: 600));
    expect(find.text('500 coins'), findsOneWidget);
    await tester.tap(find.text('250 coins'));
    await tester.pumpAndSettle();
    expect(find.text('350 coins'), findsOneWidget);
    expect(find.text('500 coins'), findsNothing);
  });
}
