import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../services/betsafe_api.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import '../widgets/sports_ui.dart';
import 'game_screen.dart';

class PicksScreen extends StatelessWidget {
  const PicksScreen({super.key, required this.api});
  final BetSafeApi api;
  @override
  Widget build(BuildContext context) {
    final state = api.state!;
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Text(
          'My picks',
          style: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            StatusPill(
              '${state.picks.where((p) => p.status == 'pending').length} pending',
              background: BetSafeColors.yellow,
              color: BetSafeColors.ink,
            ),
            const SizedBox(width: 8),
            StatusPill(
              '${state.picks.where((p) => p.status == 'won').length} won',
              background: BetSafeColors.soft,
              color: BetSafeColors.ink,
            ),
          ],
        ),
        if (state.picks.isEmpty)
          const EmptyMessage(
            title: 'No picks yet',
            message: 'Open Games and choose a team to make your first pick.',
            icon: Icons.bookmark_border,
          ),
        const SizedBox(height: 20),
        for (final pick in state.picks.reversed) ...[
          MatchTicket(
            game: state.games.firstWhere((game) => game.id == pick.gameId),
            color: pick.status == 'won'
                ? BetSafeColors.mint
                : pick.status == 'lost'
                ? BetSafeColors.loss
                : Colors.white,
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your pick',
                            style: text.bodySmall?.copyWith(
                              color: BetSafeColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pick.team,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pick.stake} coins staked',
                            style: const TextStyle(
                              fontSize: 12,
                              color: BetSafeColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusPill(
                      pick.status == 'won'
                          ? 'Won'
                          : pick.status == 'lost'
                          ? 'Lost'
                          : pick.status == 'refunded'
                          ? 'Refunded'
                          : 'Pending',
                      background: pick.status == 'lost'
                          ? BetSafeColors.loss
                          : pick.status == 'won'
                          ? BetSafeColors.mint
                          : BetSafeColors.soft,
                      color: pick.status == 'lost'
                          ? BetSafeColors.lossInk
                          : pick.status == 'won'
                          ? BetSafeColors.green
                          : BetSafeColors.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FButton(
                  size: .lg,
                  onPress: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GameScreen(api: api, gameId: pick.gameId),
                    ),
                  ),
                  child: const ButtonLabel('View pick'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
