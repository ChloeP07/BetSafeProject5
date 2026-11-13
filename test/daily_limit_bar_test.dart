import 'package:betsafeproject5/widgets/daily_limit_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

Future<void> pumpBar(WidgetTester tester, int remaining, int limit) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyLimitBar(remaining: remaining, limit: limit),
        ),
      ),
    );

double? barValue(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
    .value;

void main() {
  testWidgets('fills by the share of the limit already staked', (tester) async {
    await pumpBar(tester, 400, 500);
    expect(barValue(tester), closeTo(.2, .001));
    expect(find.text('400 of 500 coins left to stake today'), findsOneWidget);
  });

  testWidgets('is empty before any stake and full at the limit', (
    tester,
  ) async {
    await pumpBar(tester, 500, 500);
    expect(barValue(tester), 0);
    await pumpBar(tester, 0, 500);
    expect(barValue(tester), 1);
  });

  testWidgets('tells screen readers what is used', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpBar(tester, 400, 500);
    expect(find.bySemanticsLabel('Today’s stake limit'), findsOneWidget);
    final node = tester.getSemantics(
      find.bySemanticsLabel('Today’s stake limit'),
    );
    expect(node.value, '100 of 500 coins staked');
    semantics.dispose();
  });

  testWidgets('a zero limit draws as used up without dividing by zero', (
    tester,
  ) async {
    await pumpBar(tester, 0, 0);
    expect(barValue(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the pick screen shows the bar for today’s limit', (
    tester,
  ) async {
    await pumpPick(tester, stateJson(dailyStaked: 150));
    expect(find.byType(DailyLimitBar), findsOneWidget);
    expect(barValue(tester), closeTo(.3, .001));
    expect(find.text('350 of 500 coins left to stake today'), findsOneWidget);
  });

  testWidgets('the Games coin chip shows what is left of today’s limit', (
    tester,
  ) async {
    await pumpApp(tester, stateJson(dailyLimit: 800, dailyStaked: 200));
    expect(find.text('600 left today'), findsOneWidget);
    final ring = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(ring.value, closeTo(.75, .001));
  });
}
