import 'package:flutter/material.dart';

import '../services/betsafe_api.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import '../widgets/sports_ui.dart';
import 'pick_screen.dart';
import 'game_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key, required this.api});
  final BetSafeApi api;
  @override
  Widget build(BuildContext context) {
    final state = api.state!;
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hey, Demo player',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Ready to make your call?', style: text.bodySmall),
                ],
              ),
            ),
            const CircleAvatar(
              backgroundColor: BetSafeColors.mint,
              foregroundColor: BetSafeColors.green,
              child: Icon(Icons.person_outline),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SportsPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.toll, size: 18, color: BetSafeColors.green),
                  SizedBox(width: 8),
                  Text(
                    'Demo balance',
                    style: TextStyle(color: BetSafeColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${state.coins} virtual coins',
                style: text.headlineSmall?.copyWith(
                  color: BetSafeColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: BetSafeColors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${state.dailyRemaining} of 500 coins left to stake today',
                      style: const TextStyle(
                        fontSize: 12,
                        color: BetSafeColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BetSafeColors.brown,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Big calls.\nZero cash.',
                      style: text.headlineSmall?.copyWith(
                        color: BetSafeColors.cream,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'All the game-day feeling.\nOnly virtual coins.',
                      style: TextStyle(color: Color(0xFFE7D3C1), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const FieldArtwork(),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'NFL matchups',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text('${state.games.length} games', style: text.bodySmall),
          ],
        ),

        const SizedBox(height: 12),
        Text(
          'Simulation · sample games, scores and payouts.',
          style: text.bodySmall,
        ),
        const SizedBox(height: 16),
        for (final (index, game) in state.games.indexed) ...[
          MatchTicket(
            game: game,
            color: index.isEven ? Colors.white : BetSafeColors.mint,
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '2× demo return · virtual coins only',
                  style: TextStyle(fontSize: 12, color: BetSafeColors.muted),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: api.busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                state.pickFor(game.id) == null &&
                                    game.status == 'scheduled'
                                ? PickScreen(api: api, gameId: game.id)
                                : GameScreen(api: api, gameId: game.id),
                          ),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: BetSafeColors.darkBrown,
                    foregroundColor: BetSafeColors.cream,
                  ),
                  child: Text(
                    state.pickFor(game.id) == null && game.status == 'scheduled'
                        ? 'Make a pick'
                        : 'View game',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 8),
        Text(
          'No deposits. No cash-outs. Collectibles have no cash value.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}
