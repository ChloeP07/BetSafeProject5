import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

/// Switches the decorative flutter_animate effects on or off.
///
/// Each effect starts with a zero-length timer, which a widget test that ends
/// on the same frame would leave pending. So test/flutter_test_config.dart
/// turns the effects off for widget tests, and test/motion_test.dart turns
/// them back on to check them.
abstract final class Motion {
  static bool effects = true;

  /// True when effects are on and the phone has not asked for reduced motion.
  static bool on(BuildContext context) =>
      effects && !MediaQuery.disableAnimationsOf(context);
}

/// Fades a widget in while it rises into place, with flutter_animate. [index]
/// staggers a list, so items arrive one after another. Holds still when the
/// phone asks for reduced motion.
///
/// The stagger is part of each effect, not a separate delay, so a whole list
/// shares one clock.
class Enter extends StatelessWidget {
  const Enter({
    super.key,
    required this.child,
    this.index = 0,
    this.rise = .08,
  });
  final Widget child;
  final int index;

  /// How far it rises, as a share of its own height.
  final double rise;

  @override
  Widget build(BuildContext context) {
    if (!Motion.on(context)) return child;
    final delay = Duration(milliseconds: 45 * index.clamp(0, 8));
    return child
        .animate()
        .fadeIn(delay: delay, duration: 320.ms, curve: Curves.easeOut)
        .slideY(
          begin: rise,
          end: 0,
          delay: delay,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

/// A light sweep across [child] when it first shows and whenever [trigger]
/// changes, with flutter_animate, to draw the eye to something that changed.
///
/// The child keeps its state through a sweep, so its own animations, such as
/// a figure counting up, carry on.
class Sweep extends StatefulWidget {
  const Sweep({
    super.key,
    required this.child,
    required this.trigger,
    this.color = const Color(0x55FFFFFF),
  });
  final Widget child;
  final Object? trigger;
  final Color color;

  @override
  State<Sweep> createState() => _SweepState();
}

class _SweepState extends State<Sweep> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: 900.ms,
  );

  @override
  void initState() {
    super.initState();
    if (Motion.effects) controller.forward();
  }

  @override
  void didUpdateWidget(Sweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (Motion.effects && widget.trigger != oldWidget.trigger) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Motion.on(context)) return widget.child;
    return widget.child
        .animate(controller: controller, autoPlay: false)
        .shimmer(color: widget.color, curve: Curves.easeInOut);
  }
}

/// One of the Lottie animations shared with project05: `loading`, `pulse` or
/// `success`. Plays [loops] times, or forever when null. With reduced motion
/// it shows one still frame.
class GlassLottie extends StatefulWidget {
  const GlassLottie(
    this.name, {
    super.key,
    this.size = 24,
    this.loops = 1,
    this.semanticsLabel,
  });
  final String name;
  final double size;
  final int? loops;
  final String? semanticsLabel;

  @override
  State<GlassLottie> createState() => _GlassLottieState();
}

class _GlassLottieState extends State<GlassLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _start(LottieComposition composition) {
    controller.duration = composition.duration;
    if (MediaQuery.disableAnimationsOf(context)) {
      // The finished check, or the middle of a loop.
      controller.value = widget.name == 'success' ? 1 : .5;
    } else if (widget.loops == null) {
      controller.repeat();
    } else if (widget.loops == 1) {
      controller.forward(from: 0);
    } else {
      controller.repeat(count: widget.loops);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animation = SizedBox.square(
      dimension: widget.size,
      child: Lottie.asset(
        'assets/lottie/${widget.name}.json',
        controller: controller,
        onLoaded: _start,
        // Until it loads, or if it never does, an empty box of the same size.
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
    return widget.semanticsLabel == null
        ? ExcludeSemantics(child: animation)
        : Semantics(
            label: widget.semanticsLabel,
            image: true,
            child: ExcludeSemantics(child: animation),
          );
  }
}
