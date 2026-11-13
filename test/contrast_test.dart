import 'dart:math' as math;

import 'package:betsafeproject5/theme.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

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

const limitUsed =
    'You’ve used all of today’s stake limit. '
    'You can pick again after it resets at midnight UTC.';

void main() {
  testWidgets('the pick screen text is readable on each surface', (
    tester,
  ) async {
    await pumpPick(tester, stateJson(coins: 120));
    await chooseBills(tester);
    // On the page itself.
    const page = BetSafeColors.paper;
    expectReadable(tester, 'Your stake', page);
    expectReadable(tester, '50 coins', page);
    expectReadable(
      tester,
      'Stakes over your 120-coin balance are unavailable.',
      page,
    );
    expectReadable(tester, 'You’re backing the Bills', page);
    // The selected stake on mint.
    expect(paintedColor(tester, '100 coins'), BetSafeColors.green);
    expectReadable(tester, '100 coins', BetSafeColors.mint);
    // The payout panel on mint.
    expectReadable(tester, 'If your team wins', BetSafeColors.mint);
    expectReadable(tester, '200 coins returned', BetSafeColors.mint);
    // The wallet panel on white.
    expectReadable(tester, 'Balance now', Colors.white);
    expectReadable(tester, '120 coins', Colors.white);
    expectReadable(tester, '20 coins', Colors.white);
    expectReadable(
      tester,
      '500 of 500 coins left to stake today',
      Colors.white,
    );
  });

  testWidgets('the selected stake keeps a green check on mint', (tester) async {
    await pumpPick(tester, stateJson());
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '100 coins'),
    );
    expect(chip.checkmarkColor, BetSafeColors.green);
  });

  testWidgets('a stake that cannot be chosen looks disabled', (tester) async {
    await pumpPick(tester, stateJson(coins: 120));
    expect(paintedColor(tester, '250 coins').a, lessThan(1));
    expect(paintedColor(tester, '50 coins').a, 1);
  });

  testWidgets('hints and stake messages are readable', (tester) async {
    await pumpPick(tester, stateJson(dailyStaked: 500));
    expectReadable(tester, 'No stake fits right now.', BetSafeColors.paper);
    expectReadable(tester, limitUsed, BetSafeColors.paper);
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
      BetSafeColors.soft,
    );
    expectReadable(tester, 'Refresh NFL data', BetSafeColors.soft);
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
      expectReadable(tester, text, BetSafeColors.paper);
    }
    final sheetTeam = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('Buffalo Bills'),
    );
    expect(
      tester.renderObject<RenderParagraph>(sheetTeam).text.style!.color,
      BetSafeColors.ink,
    );
    expectReadable(tester, 'Confirm pick', BetSafeColors.green);
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
    expectReadable(tester, limitUsed, Colors.white);
    expectReadable(tester, '1,000', BetSafeColors.ink);
  });
}
