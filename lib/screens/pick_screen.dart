import 'package:flutter/material.dart';

import '../services/betsafe_api.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import '../widgets/sports_ui.dart';
import '../widgets/team_option_card.dart';
import 'game_screen.dart';

class PickScreen extends StatefulWidget {
  const PickScreen({super.key, required this.api, required this.gameId});
  final BetSafeApi api;
  final String gameId;
  @override
  State<PickScreen> createState() => _PickScreenState();
}

class _PickScreenState extends State<PickScreen> {
  String? team;
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
              MatchTicket(game: game, color: BetSafeColors.clay),
              const SizedBox(height: 28),
              Text(
                'Who takes the win?',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Choose your team. Keep it virtual.'),
              const SizedBox(height: 16),
              for (final option in [game.away, game.home])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TeamOptionCard(
                    team: option,
                    selected: team == option,
                    onTap: api.busy
                        ? null
                        : () => setState(() => team = option),
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
                        selectedColor: BetSafeColors.mint,
                        labelStyle: TextStyle(
                          color: stake == value
                              ? BetSafeColors.green
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              SportsPanel(
                color: BetSafeColors.mint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'If your team wins',
                      style: TextStyle(color: BetSafeColors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${stake * 2} coins returned',
                      style: text.headlineSmall?.copyWith(
                        color: BetSafeColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Includes your $stake-coin stake. Lose: your stake is spent. Demo payout: 2×, not real betting odds.',
                      style: const TextStyle(
                        color: BetSafeColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${state.dailyRemaining} coins left in today’s stake limit.',
                style: text.bodySmall,
              ),
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
                  onRetry: api.busy ? null : () => api.refresh(),
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
