import 'package:flutter/material.dart';

import '../services/betsafe_api.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import '../widgets/sports_ui.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, required this.api});
  final BetSafeApi api;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Text(
          'Your collection',
          style: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text('${api.state!.collection.length} team collectibles earned'),
        const SizedBox(height: 24),
        SportsPanel(
          color: BetSafeColors.brown,
          child: Row(
            children: [
              const Icon(
                Icons.collections_bookmark_outlined,
                color: BetSafeColors.mint,
                size: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good calls.\nGreat keepsakes.',
                      style: text.titleLarge?.copyWith(
                        color: BetSafeColors.cream,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'One winning pick. One new card.',
                      style: TextStyle(color: Color(0xFFE7D3C1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (api.state!.collection.isEmpty)
          const EmptyMessage(
            title: 'Make your first winning call.',
            message: 'Win a demo pick to earn a team collectible. Cards cannot be bought, sold, or cashed out.',
            icon: Icons.collections_bookmark_outlined,
          ),
        const SizedBox(height: 20),
        for (final card in api.state!.collection) ...[
          SportsPanel(
            color: BetSafeColors.mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(
                      card.rarity,
                      background: BetSafeColors.green,
                      color: Colors.white,
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.sports_football,
                      color: BetSafeColors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(child: TeamBadge(team: card.team, size: 88)),
                const SizedBox(height: 24),
                Text(
                  card.team,
                  style: text.headlineSmall?.copyWith(
                    color: BetSafeColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card.name,
                  style: text.titleMedium?.copyWith(color: BetSafeColors.green),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Demo team collectible · no cash value',
                  style: TextStyle(color: BetSafeColors.muted, fontSize: 12),
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
