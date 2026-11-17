import 'dart:math' as math;

import 'package:betsafeproject5/theme.dart';
import 'package:betsafeproject5/widgets/pick_confirmation_sheet.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'support/fixtures.dart';

/// The color a piece of text actually paints with. Looks inside the Text for
/// the painted paragraph, since a screen-reader label wraps it in Semantics.
Color paintedColor(WidgetTester tester, String text) => tester
    .renderObject<RenderParagraph>(
      find.descendant(
        of: find.text(text).first,
        matching: find.byType(RichText),
        matchRoot: true,
      ),
    )
    .text
    .style!
    .color!;

double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// The WCAG contrast ratio between two opaque colors.
double contrast(Color a, Color b) {
  final (first, second) = (_luminance(a), _luminance(b));
  return (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05);
}

/// Checks that [text] paints opaque, with at least 4.5:1 against [background].
void expectReadable(WidgetTester tester, String text, Color background) {
  final color = paintedColor(tester, text);
  expect(color.a, 1, reason: '"$text" should paint opaque');
  expect(
    contrast(color, background),
    greaterThanOrEqualTo(4.5),
    reason: '"$text" paints $color on $background',
  );
}

Future<void> chooseBills(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
  await tester.pumpAndSettle();
}

/// The green-tinted glass of the payout panel over the page, as one opaque
/// color: 30% of the green over the top of the gradient.
const winGlass = Color(0xFF48536D);

const limitUsed =
    'You’ve used all of today’s stake limit. '
    'You can pick again after it resets at midnight UTC.';

void main() {
  testWidgets('the pick screen text is readable on each surface', (
    tester,
  ) async {
    await pumpPick(tester, stateJson(coins: 120));
    await chooseBills(tester);
    // On the page itself, checked against glass, which is lighter than the
    // page and so the harder case.
    const page = BetSafeColors.glass;
    expectReadable(tester, 'Your stake', page);
    expectReadable(tester, '50 coins', page);
    expectReadable(
      tester,
      'Stakes over your 120-coin balance are unavailable.',
      page,
    );
    expectReadable(tester, 'You’re backing the Bills', page);
    // The selected stake on the yellow accent.
    expectReadable(tester, '100 coins', BetSafeColors.yellow);
    // The payout panel on green glass.
    expectReadable(tester, 'If your team wins', winGlass);
    expectReadable(tester, '200 coins returned', winGlass);
    expectReadable(
      tester,
      'Includes your 100-coin stake. Lose: your stake is spent. Demo payout: '
      '2×, not real betting odds.',
      winGlass,
    );
    // The wallet panel on glass.
    const glass = BetSafeColors.glass;
    expectReadable(tester, 'Balance now', glass);
    expectReadable(tester, '120 coins', glass);
    expectReadable(tester, '20 coins', glass);
    expectReadable(tester, '500 of 500 coins left to stake today', glass);
  });

  testWidgets('the selected stake shows a check, not just a color', (
    tester,
  ) async {
    await pumpPick(tester, stateJson());
    expect(
      find.descendant(
        of: find.widgetWithText(FButton, '100 coins'),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a stake that cannot be chosen looks disabled', (tester) async {
    await pumpPick(tester, stateJson(coins: 120));
    expect(paintedColor(tester, '250 coins').a, lessThan(1));
    expect(paintedColor(tester, '50 coins').a, 1);
  });

  testWidgets('hints and stake messages are readable', (tester) async {
    await pumpPick(tester, stateJson(dailyStaked: 500));
    expectReadable(tester, 'No stake fits right now.', BetSafeColors.glass);
    expectReadable(tester, limitUsed, BetSafeColors.glass);
  });

  testWidgets('the stale NFL notice is readable', (tester) async {
    await pumpPick(
      tester,
      stateJson(nfl: {...nflOk(), 'stale': true}, games: [nflGameJson()]),
    );
    expectReadable(
      tester,
      'The NFL data may be out of date, so NFL picks are paused until a '
      'refresh works.',
      BetSafeColors.glass,
    );
    expectReadable(tester, 'Refresh NFL data', BetSafeColors.glass);
  });

  testWidgets('the confirmation sheet is readable', (tester) async {
    await pumpPick(tester, stateJson());
    await chooseBills(tester);
    await tester.tap(find.text('Lock in pick'));
    await tester.pumpAndSettle();
    for (final text in [
      'Lock in this pick?',
      'Stake',
      '900 coins',
      '200 coins returned',
      'Go back',
    ]) {
      // The sheet fades from dusk at the top to paper; dusk is lighter.
      expectReadable(tester, text, BetSafeColors.dusk);
    }
    final sheetTeam = find.descendant(
      of: find.byType(PickConfirmationSheet),
      matching: find.text('Buffalo Bills'),
    );
    expect(
      tester.renderObject<RenderParagraph>(sheetTeam).text.style!.color,
      BetSafeColors.ink,
    );
    expectReadable(tester, 'Confirm pick', BetSafeColors.yellow);
    final handle = tester.widget<Container>(
      find.byKey(const ValueKey('sheet-handle')),
    );
    final handleColor = (handle.decoration! as BoxDecoration).color!;
    expect(contrast(handleColor, BetSafeColors.paper), greaterThanOrEqualTo(3));
  });

  testWidgets('the Games coin chip and limit notice are readable', (
    tester,
  ) async {
    await pumpApp(tester, stateJson(dailyStaked: 500));
    expectReadable(tester, limitUsed, BetSafeColors.glass);
    expectReadable(tester, '1,000', BetSafeColors.glass);
  });
}
