import 'package:flutter/material.dart';

import '../models/pick_rules.dart';
import '../theme.dart';

export '../models/pick_rules.dart' show stakeOptions;

/// One chip per stake. A null [onChanged] disables every chip.
class StakeSelector extends StatelessWidget {
  const StakeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.isAllowed,
    this.caption,
  });

  /// The chosen stake, or null when none is chosen.
  final int? selected;
  final ValueChanged<int>? onChanged;

  /// Disables the stakes it returns false for. All are allowed when null.
  final bool Function(int stake)? isAllowed;

  /// Says why some stakes are disabled.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final value in stakeOptions)
              ChoiceChip(
                label: Text('$value coins'),
                selected: selected == value,
                onSelected:
                    onChanged == null || !(isAllowed?.call(value) ?? true)
                    ? null
                    : (_) => onChanged!(value),
                selectedColor: BetSafeColors.mint,
                // The default check is light in dark mode and vanishes on mint.
                checkmarkColor: BetSafeColors.green,
                labelStyle: TextStyle(
                  color: selected == value ? BetSafeColors.green : onSurface,
                ),
              ),
          ],
        ),
        if (caption case final text?) ...[
          const SizedBox(height: 8),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
