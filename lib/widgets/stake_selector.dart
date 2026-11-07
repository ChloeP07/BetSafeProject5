import 'package:flutter/material.dart';

import '../theme.dart';

/// The stakes the server accepts, in coins.
const stakeOptions = [50, 100, 250];

/// One chip per stake. A null [onChanged] disables every chip.
class StakeSelector extends StatelessWidget {
  const StakeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// The chosen stake, or null when none is chosen.
  final int? selected;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final value in stakeOptions)
          ChoiceChip(
            label: Text('$value coins'),
            selected: selected == value,
            onSelected: onChanged == null ? null : (_) => onChanged!(value),
            selectedColor: BetSafeColors.mint,
            // The default check is light in dark mode and vanishes on mint.
            checkmarkColor: BetSafeColors.green,
            labelStyle: TextStyle(
              color: selected == value ? BetSafeColors.green : onSurface,
            ),
          ),
      ],
    );
  }
}
