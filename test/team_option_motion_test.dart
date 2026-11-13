import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

Widget _option({required bool selected, bool reduceMotion = false}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: ForuiTestApp(
        home: Scaffold(
          body: TeamOptionCard(
            team: 'Buffalo Bills',
            side: 'Home team',
            selected: selected,
            onTap: () {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('the check animates in when a team is selected', (tester) async {
    await tester.pumpWidget(_option(selected: false));
    await tester.pumpWidget(_option(selected: true));
    await tester.pump(const Duration(milliseconds: 60));
    // Part way through, the old and new icons are both on screen.
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_off), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_off), findsNothing);
  });

  testWidgets('with reduced motion the check appears at once', (tester) async {
    await tester.pumpWidget(_option(selected: false, reduceMotion: true));
    await tester.pumpWidget(_option(selected: true, reduceMotion: true));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_off), findsNothing);
  });
}
