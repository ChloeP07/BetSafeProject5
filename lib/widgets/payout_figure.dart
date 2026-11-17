import 'package:flutter/material.dart';

/// "N coins returned", counting to the new figure when the stake changes.
/// With reduced motion turned on, the new figure shows at once.
class PayoutFigure extends StatelessWidget {
  const PayoutFigure({super.key, required this.coins, this.style});

  /// Total coins returned on a win, as the server's demo rule gives it.
  final int coins;
  final TextStyle? style;

  static const duration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) => Semantics(
    // Screen readers hear only the final figure, not every step.
    label: '$coins coins returned',
    excludeSemantics: true,
    child: TweenAnimationBuilder<int>(
      tween: IntTween(end: coins),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : duration,
      curve: Curves.easeOut,
      builder: (context, value, _) =>
          Text('$value coins returned', style: style),
    ),
  );
}
