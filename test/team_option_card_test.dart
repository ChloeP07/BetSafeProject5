import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'support/fixtures.dart';

Future<void> pumpOption(
  WidgetTester tester, {
  bool selected = false,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  ForuiTestApp(
    home: Scaffold(
      body: TeamOptionCard(
        team: 'Buffalo Bills',
        side: 'Home team',
        selected: selected,
        onTap: onTap,
      ),
    ),
  ),
);

void main() {
  testWidgets('shows the team and reports a tap', (tester) async {
    var taps = 0;
    await pumpOption(tester, onTap: () => taps++);
    expect(find.text('Buffalo Bills'), findsOneWidget);
    expect(find.text('BUF'), findsOneWidget);
    expect(find.text('Home team'), findsOneWidget);
    await tester.tap(find.byType(TeamOptionCard));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('an unselected option shows an empty circle', (tester) async {
    await pumpOption(tester, onTap: () {});
    expect(find.byIcon(Icons.radio_button_off), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('a selected option takes the accent, with a check', (
    tester,
  ) async {
    await pumpOption(tester, selected: true, onTap: () {});
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    final button = tester.widget<FButton>(find.byType(FButton));
    expect(button.variant, FButtonVariant.secondary);
    expect(button.selected, isTrue);
  });

  testWidgets('an unselected option is outlined', (tester) async {
    await pumpOption(tester, onTap: () {});
    expect(
      tester.widget<FButton>(find.byType(FButton)).variant,
      FButtonVariant.outline,
    );
  });

  testWidgets('with no callback it is disabled', (tester) async {
    await pumpOption(tester);
    expect(tester.widget<FButton>(find.byType(FButton)).onPress, isNull);
  });

  group('screen readers', () {
    testWidgets('hear a selected option as checked', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpOption(tester, selected: true, onTap: () {});
      expect(
        tester.getSemantics(find.bySemanticsLabel('Buffalo Bills, home team')),
        isSemantics(
          label: 'Buffalo Bills, home team',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('hear an unselected option as not checked', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpOption(tester, onTap: () {});
      expect(
        tester.getSemantics(find.bySemanticsLabel('Buffalo Bills, home team')),
        isSemantics(hasCheckedState: true, isChecked: false),
      );
      semantics.dispose();
    });

    testWidgets('hear a disabled option as disabled', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpOption(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Buffalo Bills, home team')),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      semantics.dispose();
    });

    testWidgets('can select through the screen reader tap', (tester) async {
      var taps = 0;
      final semantics = tester.ensureSemantics();
      await pumpOption(tester, onTap: () => taps++);
      tester
          .getSemantics(find.bySemanticsLabel('Buffalo Bills, home team'))
          .owner!
          .performAction(
            tester
                .getSemantics(find.bySemanticsLabel('Buffalo Bills, home team'))
                .id,
            SemanticsAction.tap,
          );
      expect(taps, 1);
      semantics.dispose();
    });
  });
}
