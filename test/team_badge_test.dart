import 'package:betsafeproject5/widgets/sports_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _badge(String team) => MaterialApp(
  home: Scaffold(body: TeamBadge(team: team)),
);

void main() {
  testWidgets('shows the abbreviation for any NFL team', (tester) async {
    await tester.pumpWidget(_badge('Seattle Seahawks'));
    expect(find.text('SEA'), findsOneWidget);
  });

  testWidgets('a blank team name shows a placeholder instead of crashing', (
    tester,
  ) async {
    await tester.pumpWidget(_badge(''));
    expect(find.text('?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
