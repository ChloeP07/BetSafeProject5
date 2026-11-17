import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';

import 'motion.dart';
import 'sports_ui.dart';

/// One team to choose on the pick screen, as a Forui button. A null [onTap]
/// disables it.
class TeamOptionCard extends StatelessWidget {
  const TeamOptionCard({
    super.key,
    required this.team,
    required this.side,
    required this.selected,
    required this.onTap,
  });
  final String team;

  /// "Away team" or "Home team".
  final String side;
  final bool selected;
  final VoidCallback? onTap;

  Duration _motion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final card = Semantics(
      // Reads like a radio button: the team, then selected or not selected.
      container: true,
      excludeSemantics: true,
      label: '$team, ${side.toLowerCase()}',
      checked: selected,
      inMutuallyExclusiveGroup: true,
      enabled: onTap != null,
      onTap: onTap,
      child: FButton(
        variant: selected ? .primary : .outline,
        size: .lg,
        selected: selected,
        onPress: onTap,
        mainAxisAlignment: .start,
        child: Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                TeamBadge(team: team, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        side,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: _motion(context),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    selected ? Icons.check_circle : Icons.radio_button_off,
                    key: ValueKey(selected),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!Motion.on(context)) return card;
    // The chosen team grows a little, with flutter_animate.
    return card
        .animate(target: selected ? 1 : 0)
        .scaleXY(end: 1.025, duration: 220.ms, curve: Curves.easeOutBack);
  }
}
