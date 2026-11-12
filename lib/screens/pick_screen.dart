import 'package:flutter/material.dart';

import '../services/betsafe_api.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import '../widgets/sports_ui.dart';
import 'game_screen.dart';

class PickScreen extends StatefulWidget {
  const PickScreen({
    super.key,
    required this.api,
    required this.gameId,
    this.initialTeam,
  });
  final BetSafeApi api;
  final String gameId;
  final String? initialTeam;
  @override
  State<PickScreen> createState() => _PickScreenState();
}

class _PickScreenState extends State<PickScreen> {
  late String? team = widget.initialTeam;
  int stake = 100;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.api,
    builder: (context, _) {
      final api = widget.api;
      final state = api.state!;
      final game = state.games.firstWhere((item) => item.id == widget.gameId);
      final text = Theme.of(context).textTheme;
      final canAfford = stake <= state.coins && stake <= state.dailyRemaining;
      return Scaffold(
        appBar: AppBar(title: const Text('Make your pick')),
        body: SafeArea(
          child: PageBody(
            children: [
              MatchTicket(game: game),
              const SizedBox(height: 28),
              Text(
                'Who takes the win?',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              for (final option in [game.away, game.home])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: api.busy
                        ? null
                        : () => setState(
                            () => team = team == option ? null : option,
                          ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: team == option
                          ? BetSafeColors.yellow
                          : null,
                      foregroundColor: team == option
                          ? BetSafeColors.ink
                          : null,
                      side: BorderSide(
                        color: team == option
                            ? BetSafeColors.ink
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: Row(
                      children: [
                        TeamBadge.forGame(
                          game,
                          home: option == game.home,
                          size: 38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          team == option
                              ? Icons.check_circle
                              : Icons.radio_button_off,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Your stake',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [50, 100, 250]
                    .map(
                      (value) => ChoiceChip(
                        label: Text('$value coins'),
                        selected: stake == value,
                        onSelected: api.busy
                            ? null
                            : (_) => setState(() => stake = value),
                        selectedColor: BetSafeColors.yellow,
                        labelStyle: TextStyle(
                          color: stake == value
                              ? BetSafeColors.ink
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PickOutcome(
                      label: 'If your team wins',
                      amount: '+${stake * 2} coins',
                      background: BetSafeColors.mint,
                      foreground: BetSafeColors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickOutcome(
                      label: 'If your team loses',
                      amount: '−$stake coins',
                      background: BetSafeColors.loss,
                      foreground: BetSafeColors.lossInk,
                    ),
                  ),
                ],
              ),
              if (canAfford) ...[
                const SizedBox(height: 16),
                Text(
                  'Coins left after bet: ${MaterialLocalizations.of(context).formatDecimal(state.coins - stake)}',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
              if (!canAfford)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Choose a smaller stake. Your balance or daily limit is too low.',
                  ),
                ),
              if (api.error != null)
                ServerError(
                  message: api.error!,
                  onRetry: api.busy ? null : api.refresh,
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: api.busy || team == null || !canAfford
                    ? null
                    : () async {
                        final success = await api.placePick(
                          game.id,
                          team!,
                          stake,
                        );
                        if (!context.mounted || !success) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                GameScreen(api: api, gameId: game.id),
                          ),
                        );
                      },
                child: Text(api.busy ? 'Saving pick…' : 'Lock in pick'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PickOutcome extends StatelessWidget {
  const _PickOutcome({
    required this.label,
    required this.amount,
    required this.background,
    required this.foreground,
  });

  final String label, amount;
  final Color background, foreground;

  @override
  Widget build(BuildContext context) => SportsPanel(
    color: background,
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: foreground)),
        const SizedBox(height: 6),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: foreground, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
