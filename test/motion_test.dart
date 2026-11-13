import 'package:animations/animations.dart';
import 'package:betsafeproject5/theme.dart';
import 'package:betsafeproject5/widgets/glass.dart';
import 'package:betsafeproject5/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

/// The opacity [text] is drawn at, through every fade above it.
double opacityOf(WidgetTester tester, String text) => tester
    .widgetList<FadeTransition>(
      find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)),
    )
    .fold(1.0, (value, fade) => value * fade.opacity.value);

/// Counts its own taps, to show whether its state survives a rebuild.
class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => taps++),
    child: Text('taps $taps'),
  );
}

class _SweepHost extends StatefulWidget {
  const _SweepHost();
  @override
  State<_SweepHost> createState() => _SweepHostState();
}

class _SweepHostState extends State<_SweepHost> {
  int trigger = 0;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Sweep(trigger: trigger, child: const _Counter()),
      TextButton(
        onPressed: () => setState(() => trigger++),
        child: const Text('change'),
      ),
    ],
  );
}

void main() {
  // The rest of the suite runs with these effects off; see
  // flutter_test_config.dart.
  setUp(() => Motion.effects = true);
  tearDown(() => Motion.effects = false);

  testWidgets('Enter fades a widget in with flutter_animate', (tester) async {
    await tester.pumpWidget(
      const ForuiTestApp(
        home: Scaffold(body: Enter(child: Text('Hello'))),
      ),
    );
    expect(find.byType(Animate), findsOneWidget);
    expect(opacityOf(tester, 'Hello'), lessThan(.2));
    await tester.pumpAndSettle();
    expect(opacityOf(tester, 'Hello'), 1);
  });

  testWidgets('Enter holds still when the phone asks for reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ForuiTestApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: Enter(child: Text('Hello'))),
        ),
      ),
    );
    expect(find.byType(Animate), findsNothing);
    expect(opacityOf(tester, 'Hello'), 1);
  });

  testWidgets('a sweep keeps the state of what it sweeps', (tester) async {
    await tester.pumpWidget(
      const ForuiTestApp(home: Scaffold(body: _SweepHost())),
    );
    await tester.tap(find.text('taps 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('change'));
    await tester.pumpAndSettle();
    expect(find.text('taps 1'), findsOneWidget);
  });

  testWidgets('a card that a filter brings back rises in', (tester) async {
    await pumpApp(tester, stateJson());
    await tester.tap(find.textContaining('Live ·'));
    await tester.pumpAndSettle();
    expect(gameCard(), findsNothing);
    await tester.tap(find.textContaining('All ·'));
    await tester.pump();
    expect(
      find.ancestor(of: gameCard().first, matching: find.byType(Animate)),
      findsWidgets,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('the glass tab bar counts open picks', (tester) async {
    await pumpApp(tester, stateJson(picks: [pickJson()]));
    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(
      find.descendant(of: find.byType(GlassTabBar), matching: find.text('1')),
      findsOneWidget,
    );
  });

  testWidgets('live games are marked with the pulse animation', (tester) async {
    await pumpApp(
      tester,
      stateJson(
        nfl: nflOk(),
        games: [
          nflGameJson(status: 'live', awayScore: 7, homeScore: 3),
          nflGameJson(
            id: 'bdl-2',
            away: 'Detroit Lions',
            home: 'Chicago Bears',
          ),
        ],
      ),
    );
    final pulse = tester.widget<GlassLottie>(find.byType(GlassLottie));
    expect(pulse.name, 'pulse');
    await tester.pumpAndSettle();
  });

  test('pushed pages slide along a shared axis', () {
    final builders = betSafeTheme().pageTransitionsTheme.builders;
    for (final platform in TargetPlatform.values) {
      expect(builders[platform], isA<SharedAxisPageTransitionsBuilder>());
    }
  });
}
