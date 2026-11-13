import 'package:betsafeproject5/widgets/payout_figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

Widget figure(int coins, {bool reduceMotion = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion),
  child: ForuiTestApp(
    home: Scaffold(body: PayoutFigure(coins: coins)),
  ),
);

/// The figure currently painted, such as 340 from "340 coins returned".
int shownFigure(WidgetTester tester) {
  final text = tester.widget<Text>(find.textContaining('coins returned'));
  return int.parse(text.data!.split(' ').first);
}

void main() {
  testWidgets('counts up to the new figure when it changes', (tester) async {
    await tester.pumpWidget(figure(200));
    expect(find.text('200 coins returned'), findsOneWidget);
    await tester.pumpWidget(figure(500));
    await tester.pump(PayoutFigure.duration ~/ 3);
    final midway = shownFigure(tester);
    expect(midway, greaterThan(200));
    expect(midway, lessThan(500));
    await tester.pumpAndSettle();
    expect(find.text('500 coins returned'), findsOneWidget);
  });

  testWidgets('with reduced motion the new figure shows at once', (
    tester,
  ) async {
    await tester.pumpWidget(figure(200, reduceMotion: true));
    await tester.pumpWidget(figure(500, reduceMotion: true));
    expect(find.text('500 coins returned'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('screen readers hear only the final figure', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(figure(200));
    await tester.pumpWidget(figure(500));
    await tester.pump(PayoutFigure.duration ~/ 3);
    expect(find.bySemanticsLabel('500 coins returned'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the pick screen counts to the payout for a new stake', (
    tester,
  ) async {
    await pumpPick(tester, stateJson());
    expect(find.text('200 coins returned'), findsOneWidget);
    await tester.tap(find.text('250 coins'));
    await tester.pump();
    await tester.pump(PayoutFigure.duration ~/ 3);
    expect(find.text('500 coins returned'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('500 coins returned'), findsOneWidget);
  });
}
