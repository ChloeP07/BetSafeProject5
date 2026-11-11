
import 'package:flutter/material.dart';

import '../services/betsafe_api.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import '../widgets/sports_ui.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.api, required this.gameId});

  final BetSafeApi api;
  final String gameId;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: api,
    builder: (context, _) {
      final game = api.state!.games.firstWhere((item) => item.id == gameId);
      final pick = api.state!.pickFor(gameId);
      final text = Theme.of(context).textTheme;

      final finalGame =
          game.status == 'final' || (pick != null && pick.status != 'pending');

      return Scaffold(
        appBar: AppBar(
          title: Text(finalGame ? 'Final whistle' : 'Game progress'),
        ),
        body: SafeArea(
          child: PageBody(
            children: [
              MatchTicket(game: game, color: BetSafeColors.clay),
              const SizedBox(height: 24),

              if (pick != null) ...[
                SportsPanel(
                  color: pick.status == 'lost'
                      ? BetSafeColors.clay
                      : BetSafeColors.mint,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            pick.status == 'won'
                                ? Icons.emoji_events_outlined
                                : pick.status == 'lost'
                                    ? Icons.cancel_outlined
                                    : pick.status == 'refunded'
                                        ? Icons.currency_exchange
                                        : Icons.schedule,
                            color: pick.status == 'won'
                                ? BetSafeColors.green
                                : pick.status == 'lost'
                                    ? BetSafeColors.clay
                                    : BetSafeColors.ink,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your pick: ${pick.team}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pick.status == 'won'
                                      ? 'WINNING PICK'
                                      : pick.status == 'lost'
                                          ? 'LOSING PICK'
                                          : pick.status == 'refunded'
                                              ? 'STAKE REFUNDED'
                                              : 'PICK PENDING',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: pick.status == 'won'
                                        ? BetSafeColors.green
                                        : pick.status == 'lost'
                                            ? BetSafeColors.clay
                                            : BetSafeColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        '${pick.stake} virtual coins staked',
                        style: const TextStyle(
                          color: BetSafeColors.muted,
                        ),
                      ),

                      if (finalGame) ...[
                        const SizedBox(height: 24),
                        Text(
                          pick.status == 'refunded'
                              ? 'Your stake was returned.'
                              : pick.status == 'won'
                                  ? 'You called it!'
                                  : 'Next game, new call.',
                          style: text.headlineSmall?.copyWith(
                            color: BetSafeColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pick.status == 'refunded'
                              ? '${pick.payout} coins refunded for a tie or canceled game.'
                              : pick.status == 'won'
                                  ? '${pick.payout} coins returned. You earned a team collectible—find it in Collection.'
                                  : 'Your stake was spent. Only virtual coins were at play.',
                          style: const TextStyle(height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              Text(
                finalGame
                    ? 'Every game is a new call.'
                    : 'Your game-day view',
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),
              Text(game.label),

              if (api.error != null)
                ServerError(
                  message: api.error!,
                  onRetry: api.busy ? null : () => api.refresh(),
                ),

              const SizedBox(height: 24),

              if (!finalGame && pick != null && game.isSimulation) ...[
                const Text(
                  'Demo controls advance a fictional game. These are not live NFL scores.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: api.busy
                      ? null
                      : () => api.advance(gameId),
                  child: Text(
                    api.busy
                        ? 'Updating…'
                        : game.status == 'scheduled'
                            ? 'Start simulation'
                            : 'Finish simulation',
                  ),
                ),
              ],

              if (!game.isSimulation) ...[
                Text(
                  api.state!.nfl.description,
                  style: text.bodySmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Scores update from the NFL feed. Play-by-play is not included.',
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: api.busy
                      ? null
                      : () => api.refresh(),
                  child: const Text('Refresh scores'),
                ),
                const SizedBox(height: 16),
              ],

              if (finalGame)
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to app'),
                ),
            ],
          ),
        ),
      );
    },
  );
}

