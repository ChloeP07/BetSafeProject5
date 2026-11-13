import 'package:flutter/material.dart';

import '../theme.dart';
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
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: BetSafeColors.paper,
    builder: (_) =>
        PickConfirmationSheet(team: team, stake: stake, coins: coins),
  );
  return confirmed ?? false;
}

/// The body of the confirmation sheet. A light surface in both themes.
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
    // The sheet is a Material, which would reset text to the theme's color.
    // It is cream in both themes, so its text is set dark here.
    return DefaultTextStyle.merge(
      style: const TextStyle(color: BetSafeColors.ink),
      child: IconTheme(
        data: const IconThemeData(color: BetSafeColors.ink),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drawn here because the theme's handle is light in dark mode
              // and fades into the cream sheet.
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
              for (final (label, value) in rows)
                Padding(
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
              const SizedBox(height: 4),
              const Text(
                'A locked pick can’t be changed. Virtual coins only, with a '
                '2× demo return, not real betting odds.',
                style: TextStyle(color: BetSafeColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _close(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: BetSafeColors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm pick'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _close(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BetSafeColors.ink,
                  side: const BorderSide(color: BetSafeColors.ink),
                ),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
