import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../theme.dart';
import 'motion.dart';
import 'shared.dart';
import 'sports_ui.dart';

/// Asks the player to confirm a pick before it is sent. Resolves to true only
/// when they tap Confirm pick.
///
/// The figures come from the latest server snapshot. The server still checks
/// the pick and debits the stake.
Future<bool> showPickConfirmation(
  BuildContext context, {
  required String team,
  required int stake,
  required int coins,
}) async {
  final confirmed = await showFSheet<bool>(
    context: context,
    side: .btt,
    useSafeArea: true,
    mainAxisMaxRatio: null,
    // A solid dark purple sheet with a bright glass edge, so its figures stay
    // readable over whatever is behind it.
    builder: (_) => DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [BetSafeColors.dusk, BetSafeColors.paper],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0x55FFFFFF))),
      ),
      child: PickConfirmationSheet(team: team, stake: stake, coins: coins),
    ),
  );
  return confirmed ?? false;
}

/// The body of the confirmation sheet, on a solid dark surface.
class PickConfirmationSheet extends StatelessWidget {
  const PickConfirmationSheet({
    super.key,
    required this.team,
    required this.stake,
    required this.coins,
  });
  final String team;
  final int stake, coins;

  /// Closes the sheet once. A quick second tap finds it already closing and
  /// does nothing, so it can never close the pick screen behind it.
  static void _close(BuildContext context, bool confirmed) {
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      Navigator.of(context).pop(confirmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows = [
      ('Stake', '$stake coins'),
      ('Balance now', '$coins coins'),
      ('After this pick', '${coins - stake} coins'),
      ('If your team wins', '${stake * 2} coins returned'),
    ];
    // The sheet is a Material, which would reset text to the theme's color,
    // so its text color is set here.
    return DefaultTextStyle.merge(
      style: const TextStyle(color: BetSafeColors.ink),
      child: IconTheme(
        data: const IconThemeData(color: BetSafeColors.ink),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drawn here so it keeps a 3:1 contrast with the sheet.
              Center(
                child: Container(
                  key: const ValueKey('sheet-handle'),
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    color: BetSafeColors.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  'Lock in this pick?',
                  style: text.headlineSmall?.copyWith(
                    color: BetSafeColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TeamBadge(team: team, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      team,
                      style: text.titleMedium?.copyWith(
                        color: BetSafeColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final (index, (label, value)) in rows.indexed)
                Enter(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                            value,
                            style: const TextStyle(
                              color: BetSafeColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              const Text(
                'A locked pick can’t be changed. Virtual coins only, with a '
                '2× demo return, not real betting odds.',
                style: TextStyle(color: BetSafeColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Enter(
                index: rows.length,
                child: FButton(
                  size: .lg,
                  onPress: () => _close(context, true),
                  child: const ButtonLabel('Confirm pick'),
                ),
              ),
              const SizedBox(height: 8),
              Enter(
                index: rows.length + 1,
                child: FButton(
                  variant: .outline,
                  size: .lg,
                  onPress: () => _close(context, false),
                  child: const ButtonLabel('Go back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
