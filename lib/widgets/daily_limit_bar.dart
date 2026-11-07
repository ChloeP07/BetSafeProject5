import 'package:flutter/material.dart';

import '../theme.dart';

/// How much of today's stake limit is used, for a light panel.
///
/// The numbers come from the server. This only draws them.
class DailyLimitBar extends StatelessWidget {
  const DailyLimitBar({
    super.key,
    required this.remaining,
    required this.limit,
  });

  /// Coins that can still be staked today.
  final int remaining;

  /// Today's full stake limit.
  final int limit;

  @override
  Widget build(BuildContext context) {
    final staked = (limit - remaining).clamp(0, limit);
    final used = limit <= 0 ? 1.0 : staked / limit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 16,
              color: BetSafeColors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$remaining of $limit coins left to stake today',
                style: const TextStyle(
                  fontSize: 12,
                  color: BetSafeColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // A progress bar's own semantics value must be a number, so the bar is
        // described in words here instead.
        Semantics(
          container: true,
          label: 'Today’s stake limit',
          value: '$staked of $limit coins staked',
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: used,
                minHeight: 8,
                color: BetSafeColors.brown,
                backgroundColor: BetSafeColors.clay,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
