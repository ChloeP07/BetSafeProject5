import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/pick_rules.dart';
import 'shared.dart';

export '../models/pick_rules.dart' show stakeOptions;

/// One Forui button per stake. A null [onChanged] disables every one.
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

  bool _enabled(int value) =>
      onChanged != null && (isAllowed?.call(value) ?? true);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final value in stakeOptions)
              FButton(
                // The chosen stake takes the yellow accent, with a check so
                // the choice does not rely on color alone.
                variant: selected == value ? .secondary : .outline,
                size: .lg,
                mainAxisSize: .min,
                selected: selected == value,
                onPress: _enabled(value) ? () => onChanged!(value) : null,
                prefix: selected == value
                    ? const Icon(Icons.check, size: 16)
                    : null,
                child: ButtonLabel('$value coins'),
              ),
          ],
        ),
        if (caption case final text?) ...[
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}
