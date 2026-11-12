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
      final feedNotice = api.state!.nfl.description;

      final finalGame =
          game.status == 'final' || (pick != null && pick.status != 'pending');

      return Scaffold(
        appBar: AppBar(title: Text(finalGame ? 'Result' : 'Game details')),
        body: SafeArea(
          child: PageBody(
            children: [
              MatchTicket(game: game),
              const SizedBox(height: 24),

              if (pick != null) ...[
                SportsPanel(
                  color: pick.status == 'lost'
                      ? BetSafeColors.loss
                      : pick.status == 'won'
                      ? BetSafeColors.mint
                      : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
                                      ? 'Won'
                                      : pick.status == 'lost'
                                      ? 'Lost'
                                      : pick.status == 'refunded'
                                      ? 'Refunded'
                                      : 'Pending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: pick.status == 'won'
                                        ? BetSafeColors.green
                                        : pick.status == 'lost'
                                        ? BetSafeColors.lossInk
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
                        style: const TextStyle(color: BetSafeColors.muted),
                      ),

                      if (finalGame) ...[
                        const SizedBox(height: 24),
                        Text(
                          pick.status == 'refunded'
                              ? 'Your stake was returned.'
                              : pick.status == 'won'
                              ? 'You won'
                              : 'You lost',
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

              if (api.error != null)
                ServerError(
                  message: api.error!,
                  onRetry: api.busy ? null : () => api.refresh(),
                ),

              const SizedBox(height: 24),

              if (!finalGame && pick != null && game.isSimulation) ...[
                const Text('Play through a simulated game to see your result.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: api.busy ? null : () => api.advance(gameId),
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
                if (feedNotice != null) ...[
                  Text(feedNotice, style: text.bodySmall),
                  const SizedBox(height: 12),
                ],
                OutlinedButton(
                  onPressed: api.busy ? null : () => api.refresh(),
                  child: const Text('Refresh scores'),
                ),
                const SizedBox(height: 16),
              ],

              if (finalGame)
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
            ],
          ),
        ),
      );
    },
  );
}
