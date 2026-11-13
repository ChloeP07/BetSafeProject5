import 'package:betsafeproject5/theme.dart';
import 'package:betsafeproject5/widgets/stake_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'support/fixtures.dart';

Widget _selector({int? selected = 100, ValueChanged<int>? onChanged}) =>
    ForuiTestApp(
      theme: betSafeTheme(),
      home: Scaffold(
        body: StakeSelector(selected: selected, onChanged: onChanged),
      ),
    );

FButton _chip(WidgetTester tester, int value) =>
    tester.widget<FButton>(find.widgetWithText(FButton, '$value coins'));

void main() {
  testWidgets('offers the stakes the server accepts', (tester) async {
    await tester.pumpWidget(_selector(onChanged: (_) {}));
    expect(stakeOptions, [50, 100, 250]);
    for (final value in stakeOptions) {
      expect(find.text('$value coins'), findsOneWidget);
    }
  });

  testWidgets('marks only the chosen stake as selected', (tester) async {
    await tester.pumpWidget(_selector(onChanged: (_) {}));
    expect(_chip(tester, 50).selected, isFalse);
    expect(_chip(tester, 100).selected, isTrue);
    expect(_chip(tester, 250).selected, isFalse);
  });

  testWidgets('reports the stake that was tapped', (tester) async {
    int? chosen;
    await tester.pumpWidget(_selector(onChanged: (value) => chosen = value));
    await tester.tap(find.text('250 coins'));
    await tester.pumpAndSettle();
    expect(chosen, 250);
  });

  testWidgets('a null callback disables every chip', (tester) async {
    await tester.pumpWidget(_selector());
    for (final value in stakeOptions) {
      expect(_chip(tester, value).onPress, isNull);
    }
  });

  testWidgets('disables stakes that are not allowed, with a caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      ForuiTestApp(
        home: Scaffold(
          body: StakeSelector(
            selected: 100,
            onChanged: (_) {},
            isAllowed: (value) => value <= 100,
            caption: 'Stakes over your 120-coin balance are unavailable.',
          ),
        ),
      ),
    );
    expect(_chip(tester, 50).onPress, isNotNull);
    expect(_chip(tester, 100).onPress, isNotNull);
    expect(_chip(tester, 250).onPress, isNull);
    expect(
      find.text('Stakes over your 120-coin balance are unavailable.'),
      findsOneWidget,
    );
  });

  testWidgets('shows no caption when none is given', (tester) async {
    await tester.pumpWidget(_selector(onChanged: (_) {}));
    expect(find.textContaining('unavailable'), findsNothing);
  });

  testWidgets('the chosen stake takes the accent and a check', (tester) async {
    await tester.pumpWidget(_selector(onChanged: (_) {}));
    expect(_chip(tester, 100).variant, FButtonVariant.secondary);
    expect(_chip(tester, 50).variant, FButtonVariant.outline);
    // The check means the choice does not rely on color alone.
    expect(
      find.descendant(
        of: find.widgetWithText(FButton, '100 coins'),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
