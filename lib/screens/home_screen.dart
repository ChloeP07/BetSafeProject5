import 'dart:async';

import 'package:flutter/material.dart';

import '../services/betsafe_api.dart';
import '../widgets/shared.dart';
import '../theme.dart';
import 'games_screen.dart';
import 'picks_screen.dart';
import 'collection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.api});
  final BetSafeApi? api;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final BetSafeApi api;
  int destination = 0;
  Timer? refreshTimer;
  void startRefreshTimer() {
    refreshTimer?.cancel();
    refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (api.state?.nfl.configured ?? false) api.refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      api.refresh();
      startRefreshTimer();
    } else {
      refreshTimer?.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    api = widget.api ?? BetSafeApi();
    api.refresh();
    WidgetsBinding.instance.addObserver(this);
    startRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    refreshTimer?.cancel();
    if (widget.api == null) api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: api,
    builder: (context, _) {
      final destinations = const [
        NavigationDestination(
          icon: Icon(Icons.sports_football_outlined),
          selectedIcon: Icon(Icons.sports_football),
          label: 'Games',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'My picks',
        ),
        NavigationDestination(
          icon: Icon(Icons.collections_bookmark_outlined),
          selectedIcon: Icon(Icons.collections_bookmark),
          label: 'Collection',
        ),
      ];
      final content = Column(
        children: [
          if (api.busy) const LinearProgressIndicator(),
          if (api.error != null)
            ServerError(
              message: api.error!,
              onRetry: api.busy ? null : () => api.refresh(),
            ),
          Expanded(
            child: api.state == null
                ? (api.busy
                      ? const Center(child: CircularProgressIndicator())
                      : const PageBody(
                          children: [
                            EmptyMessage(
                              title: 'Start your demo server',
                              message: 'Run npm start in the server folder, then tap Try again.',
                              icon: Icons.cloud_off,
                            ),
                          ],
                        ))
                : switch (destination) {
                    0 => GamesScreen(api: api),
                    1 => PicksScreen(api: api),
                    _ => CollectionScreen(api: api),
                  },
          ),
        ],
      );
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'BETSAFE',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Theme.of(context).brightness == Brightness.light
                  ? BetSafeColors.brown
                  : BetSafeColors.cream,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh from server',
              onPressed: api.busy ? null : () => api.refresh(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) return content;
              return Row(
                children: [
                  NavigationRail(
                    selectedIndex: destination,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: (value) =>
                        setState(() => destination = value),
                    destinations: destinations
                        .map(
                          (item) => NavigationRailDestination(
                            icon: item.icon,
                            selectedIcon: item.selectedIcon,
                            label: Text(item.label),
                          ),
                        )
                        .toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: MediaQuery.sizeOf(context).width >= 720
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: NavigationBar(
                      height: 72,
                      elevation: 0,
                      selectedIndex: destination,
                      destinations: destinations,
                      onDestinationSelected: (value) =>
                          setState(() => destination = value),
                    ),
                  ),
                ),
              ),
      );
    },
  );
}
