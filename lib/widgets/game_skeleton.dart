import 'package:flutter/material.dart';

import '../theme.dart';
import 'motion.dart';
import 'shared.dart';
import 'sports_ui.dart';

/// Placeholder game cards for the first load. It pulses gently, and holds still
/// when the phone asks for reduced motion.
class GameListSkeleton extends StatefulWidget {
  const GameListSkeleton({super.key});
  @override
  State<GameListSkeleton> createState() => _GameListSkeletonState();
}

class _GameListSkeletonState extends State<GameListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: .55,
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      pulse.value = 1;
      pulse.stop();
    } else if (!pulse.isAnimating) {
      pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading games',
    liveRegion: true,
    child: ExcludeSemantics(
      child: FadeTransition(
        opacity: pulse,
        child: const PageBody(
          children: [
            // project05's loading animation over the placeholder cards.
            Center(child: GlassLottie('loading', size: 64, loops: null)),
            SizedBox(height: 12),
            _SkeletonCard(),
            _SkeletonCard(),
            _SkeletonCard(),
          ],
        ),
      ),
    ),
  );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: SportsPanel(
      child: Column(
        children: [
          Row(children: [_Bar(width: 48), Spacer(), _Bar(width: 88)]),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _SkeletonTeam()),
              SizedBox(width: 12),
              _Bar(width: 40, height: 24),
              SizedBox(width: 12),
              Expanded(child: _SkeletonTeam()),
            ],
          ),
          SizedBox(height: 24),
          _Bar(height: 52),
        ],
      ),
    ),
  );
}

class _SkeletonTeam extends StatelessWidget {
  const _SkeletonTeam();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: BetSafeColors.soft,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(height: 10),
      const _Bar(width: 72),
    ],
  );
}

class _Bar extends StatelessWidget {
  const _Bar({this.width, this.height = 12});
  final double? width;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: BetSafeColors.soft,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
