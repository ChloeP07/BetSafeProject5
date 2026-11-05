import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_status.dart';
import '../models/nfl_teams.dart';
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

  /// Keeps the kickoff countdown current between server refreshes.
  late final Timer _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _ticker;
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  /// Selects a team. A second tap on the chosen team clears the choice.
  void _choose(String option) {
    final selecting = team != option;
    if (selecting) HapticFeedback.selectionClick();
    setState(() => team = selecting ? option : null);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.api,
    builder: (context, _) {
      final api = widget.api;
      final state = api.state!;
      final game = state.gameById(widget.gameId);
      if (game == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Make your pick')),
          body: SafeArea(
            child: PageBody(
              children: [
                const EmptyMessage(
                  title: 'This game is no longer available',
                  message: 'It has dropped off the schedule, so there is nothing to pick here.',
                  icon: Icons.event_busy,
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to games'),
                ),
              ],
            ),
          ),
        );
      }
      final text = Theme.of(context).textTheme;
      final canAfford = stake <= state.coins && stake <= state.dailyRemaining;
      final locked = api.busy || !game.canPick;
      return Scaffold(
        appBar: AppBar(title: const Text('Make your pick')),
        body: SafeArea(
          child: PageBody(
            children: [
              MatchTicket(
                game: game,
                color: BetSafeColors.clay,
                selectedTeam: team,
                onTeamTap: locked ? null : _choose,
              ),
              if (game.closedReason case final reason?) ...[
                const SizedBox(height: 16),
                _ClosedNotice(
                  reason: reason,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'Who takes the win?',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Choose your team. Keep it virtual.'),
              if (!game.isSimulation) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Picks close at kickoff.',
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              for (final (option, side) in [
                (game.away, 'Away team'),
                (game.home, 'Home team'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TeamOptionCard(
                    team: option,
                    side: side,
                    selected: team == option,
                    onTap: locked ? null : () => _choose(option),
                  ),
                ),
              if (team case final chosen?)
                Semantics(
                  container: true,
                  liveRegion: true,
                  child: Text(
                    'You’re backing the ${teamShortName(chosen)}',
                    style: text.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
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
                        onSelected: locked
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
                onPressed: locked || team == null || !canAfford
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

/// Explains why a game closed while the player was choosing.
class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice({required this.reason, required this.onBack});
  final String reason;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: SportsPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(reason)),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: BetSafeColors.brown,
            ),
            child: const Text('Back to games'),
          ),
        ],
      ),
    ),
  );
}
