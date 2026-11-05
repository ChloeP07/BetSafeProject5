import 'package:betsafeproject5/theme.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpOption(
  WidgetTester tester, {
  bool selected = false,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: TeamOptionCard(
        team: 'Buffalo Bills',
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
    await tester.tap(find.byType(TeamOptionCard));
    expect(taps, 1);
  });

  testWidgets('an unselected option shows an empty circle', (tester) async {
    await pumpOption(tester, onTap: () {});
    expect(find.byIcon(Icons.radio_button_off), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('a selected option is green with a check', (tester) async {
    await pumpOption(tester, selected: true, onTap: () {});
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    final style = tester
        .widget<OutlinedButton>(find.byType(OutlinedButton))
        .style!;
    expect(style.backgroundColor!.resolve({}), BetSafeColors.mint);
  });

  testWidgets('with no callback it is disabled', (tester) async {
    await pumpOption(tester);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).enabled,
      isFalse,
    );
  });
}
