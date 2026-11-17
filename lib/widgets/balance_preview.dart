import 'package:flutter/material.dart';

import '../theme.dart';

/// The balance now and, once a stake is chosen, what it would be after the
/// pick. For a light panel. The server debits the stake and has the final word.
class BalancePreview extends StatelessWidget {
  const BalancePreview({super.key, required this.coins, required this.stake});
  final int coins;

  /// The chosen stake, or null when none fits.
  final int? stake;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Balance now', '$coins coins'),
      if (stake case final value?)
        ('After this pick', '${coins - value} coins'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (label, amount) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: MergeSemantics(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: BetSafeColors.muted),
                  ),
                  Text(
                    amount,
                    style: const TextStyle(
                      color: BetSafeColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
