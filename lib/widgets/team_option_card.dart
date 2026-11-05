import 'package:flutter/material.dart';

import '../theme.dart';
import 'sports_ui.dart';

/// One team to choose on the pick screen. A null [onTap] disables it.
class TeamOptionCard extends StatelessWidget {
  const TeamOptionCard({
    super.key,
    required this.team,
    required this.selected,
    required this.onTap,
  });
  final String team;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    // Reads like a radio button: the team, then selected or not selected.
    container: true,
    excludeSemantics: true,
    label: team,
    checked: selected,
    inMutuallyExclusiveGroup: true,
    enabled: onTap != null,
    onTap: onTap,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? BetSafeColors.mint : null,
        foregroundColor: selected ? BetSafeColors.green : null,
        side: BorderSide(
          color: selected
              ? BetSafeColors.green
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        padding: const EdgeInsets.all(14),
      ),
      child: Row(
        children: [
          TeamBadge(team: team, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              team,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_off,
            size: 22,
          ),
        ],
      ),
    ),
  );
}
