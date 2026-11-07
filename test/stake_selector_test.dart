import 'package:betsafeproject5/theme.dart';
import 'package:betsafeproject5/widgets/stake_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _selector({
  int? selected = 100,
  ValueChanged<int>? onChanged,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: betSafeTheme(brightness),
  home: Scaffold(
    body: StakeSelector(selected: selected, onChanged: onChanged),
  ),
);

ChoiceChip _chip(WidgetTester tester, int value) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '$value coins'));

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
    expect(chosen, 250);
  });

  testWidgets('a null callback disables every chip', (tester) async {
    await tester.pumpWidget(_selector());
    for (final value in stakeOptions) {
      expect(_chip(tester, value).onSelected, isNull);
    }
  });

  testWidgets('disables stakes that are not allowed, with a caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
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
    expect(_chip(tester, 50).onSelected, isNotNull);
    expect(_chip(tester, 100).onSelected, isNotNull);
    expect(_chip(tester, 250).onSelected, isNull);
    expect(
      find.text('Stakes over your 120-coin balance are unavailable.'),
      findsOneWidget,
    );
  });

  testWidgets('shows no caption when none is given', (tester) async {
    await tester.pumpWidget(_selector(onChanged: (_) {}));
    expect(find.textContaining('unavailable'), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'the check mark stays green on mint in ${brightness.name} mode',
      (tester) async {
        await tester.pumpWidget(
          _selector(onChanged: (_) {}, brightness: brightness),
        );
        expect(_chip(tester, 100).checkmarkColor, BetSafeColors.green);
        expect(_chip(tester, 100).selectedColor, BetSafeColors.mint);
      },
    );
  }
}
