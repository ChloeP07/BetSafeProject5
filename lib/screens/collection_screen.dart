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
          'Collection',
          style: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text('${api.state!.collection.length} cards earned'),
        const SizedBox(height: 24),
        if (api.state!.collection.isEmpty)
          const EmptyMessage(
            title: 'No cards yet',
            message: 'Win a pick to earn a team card.',
            icon: Icons.layers_outlined,
          ),
        const SizedBox(height: 20),
        for (final card in api.state!.collection) ...[
          SportsPanel(
            color: Colors.white,
            child: Row(
              children: [
                TeamBadge(team: card.team, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.team,
                        style: text.titleLarge?.copyWith(
                          color: BetSafeColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(card.name),
                      const SizedBox(height: 8),
                      Text(
                        card.rarity,
                        style: const TextStyle(color: BetSafeColors.muted),
                      ),
                    ],
                  ),
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
