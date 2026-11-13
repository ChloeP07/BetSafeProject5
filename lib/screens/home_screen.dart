import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../services/betsafe_api.dart';
import '../widgets/game_skeleton.dart';
import '../widgets/glass.dart';
import '../widgets/shared.dart';
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
      final picks = api.state?.picks.length ?? 0;
      final tabs = [
        const GlassTab(
          'Games',
          Icons.calendar_today_outlined,
          Icons.calendar_today,
        ),
        GlassTab(
          'My picks',
          Icons.bookmark_border,
          Icons.bookmark,
          badge: picks,
        ),
        const GlassTab('Collection', Icons.layers_outlined, Icons.layers),
      ];
      final page = api.state == null
          ? (api.busy
                ? const GameListSkeleton()
                : const PageBody(
                    children: [
                      EmptyMessage(
                        title: 'Can’t connect',
                        message: 'Try again in a moment.',
                        icon: Icons.cloud_off,
                      ),
                    ],
                  ))
          : switch (destination) {
              0 => GamesScreen(api: api),
              1 => PicksScreen(api: api),
              _ => CollectionScreen(api: api),
            };
      final content = Column(
        children: [
          if (api.busy) const FProgress(semanticsLabel: 'Loading'),
          if (api.error != null)
            ServerError(
              message: api.error!,
              onRetry: api.busy ? null : () => api.refresh(),
            ),
          Expanded(
            // Tabs fade through each other, from the animations package.
            child: PageTransitionSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 320),
              transitionBuilder: (child, animation, secondaryAnimation) =>
                  FadeThroughTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    fillColor: Colors.transparent,
                    child: child,
                  ),
              child: KeyedSubtree(
                key: ValueKey(api.state == null ? -1 : destination),
                child: page,
              ),
            ),
          ),
        ],
      );
      final wide = MediaQuery.sizeOf(context).width >= 720;
      return GlassScaffold(
        // The tab bar sits below the list, on the gradient, so it never
        // covers a card the player is trying to tap.
        body: SafeArea(
          bottom: wide,
          child: !wide
              ? content
              : Row(
                  children: [
                    NavigationRail(
                      selectedIndex: destination,
                      labelType: NavigationRailLabelType.all,
                      onDestinationSelected: (value) =>
                          setState(() => destination = value),
                      destinations: [
                        for (final tab in tabs)
                          NavigationRailDestination(
                            icon: Badge.count(
                              count: tab.badge,
                              isLabelVisible: tab.badge > 0,
                              child: Icon(tab.icon),
                            ),
                            selectedIcon: Icon(tab.selectedIcon),
                            label: Text(tab.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                ),
        ),
        bottomBar: wide
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: GlassTabBar(
                    tabs: tabs,
                    selectedIndex: destination,
                    onSelected: (value) => setState(() => destination = value),
                  ),
                ),
              ),
      );
    },
  );
}
