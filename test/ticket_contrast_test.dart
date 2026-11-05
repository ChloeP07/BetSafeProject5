import 'package:betsafeproject5/theme.dart';
import 'package:betsafeproject5/widgets/sports_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

/// The color a piece of text actually paints with.
Color? paintedColor(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

Widget ticketIn(Brightness brightness, {String? selectedTeam}) => MaterialApp(
  theme: betSafeTheme(brightness),
  home: Scaffold(
    body: MatchTicket(
      game: gameFrom(demoGameJson()),
      selectedTeam: selectedTeam,
      onTeamTap: (_) {},
    ),
  ),
);

void main() {
  for (final brightness in Brightness.values) {
    group('on a light ticket in ${brightness.name} mode', () {
      testWidgets('team names stay dark enough to read', (tester) async {
        await tester.pumpWidget(ticketIn(brightness));
        expect(paintedColor(tester, 'Buffalo Bills'), BetSafeColors.ink);
        expect(paintedColor(tester, 'Kansas City Chiefs'), BetSafeColors.ink);
      });

      testWidgets('the chosen team is green', (tester) async {
        await tester.pumpWidget(
          ticketIn(brightness, selectedTeam: 'Buffalo Bills'),
        );
        expect(paintedColor(tester, 'Buffalo Bills'), BetSafeColors.green);
        expect(paintedColor(tester, 'Kansas City Chiefs'), BetSafeColors.ink);
      });
    });
  }
}
