import 'dart:async';

import 'package:flutter/material.dart';

import '../services/betsafe_api.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'collection_screen.dart';
import 'games_screen.dart';
import 'picks_screen.dart';

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
      if (api.state?.nfl.configured ?? false) unawaited(api.refresh());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Not awaited on purpose: the screen updates when the reply arrives.
      unawaited(api.refresh());
      startRefreshTimer();
    } else {
      refreshTimer?.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    api = widget.api ?? BetSafeApi();
    unawaited(api.refresh());
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
      const destinations = [
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Games',
        ),
        NavigationDestination(
          icon: Icon(Icons.bookmark_border),
          selectedIcon: Icon(Icons.bookmark),
          label: 'My picks',
        ),
        NavigationDestination(
          icon: Icon(Icons.layers_outlined),
          selectedIcon: Icon(Icons.layers),
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
                  },
          ),
        ],
      );
      return Scaffold(
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
                  padding: const EdgeInsets.only(top: 8, bottom: 18),
                  child: Center(
                    heightFactor: 1,
                    child: Container(
                      width: 240,
                      height: 64,
                      decoration: BoxDecoration(
                        color: BetSafeColors.ink,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final (index, item) in destinations.indexed)
                            Semantics(
                              selected: destination == index,
                              child: IconButton(
                                tooltip: item.label,
                                onPressed: () =>
                                    setState(() => destination = index),
                                style: IconButton.styleFrom(
                                  fixedSize: const Size.square(48),
                                  backgroundColor: destination == index
                                      ? BetSafeColors.yellow
                                      : Colors.transparent,
                                  foregroundColor: destination == index
                                      ? BetSafeColors.ink
                                      : Colors.white,
                                ),
                                icon: Badge.count(
                                  count: api.state?.picks.length ?? 0,
                                  isLabelVisible:
                                      index == 1 &&
                                      (api.state?.picks.isNotEmpty ?? false),
                                  backgroundColor: BetSafeColors.yellow,
                                  textColor: BetSafeColors.ink,
                                  child: destination == index
                                      ? item.selectedIcon
                                      : item.icon,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      );
    },
  );
}
