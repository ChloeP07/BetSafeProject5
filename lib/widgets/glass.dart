import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';

import '../theme.dart';
import 'motion.dart';

/// The glass style from project05: a dark purple gradient with two soft glows,
/// so the frosted panels on top have something to blur. BetSafe adds a faint
/// yellow glow for its accent.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [BetSafeColors.dusk, BetSafeColors.night],
      ),
    ),
    child: Stack(
      children: [
        // No glows in high contrast, so text sits on plain dark.
        if (!MediaQuery.highContrastOf(context)) ...const [
          Positioned(
            top: -80,
            left: -60,
            child: _Glow(size: 260, color: Color(0x667B4DFF)),
          ),
          Positioned(
            top: 260,
            right: -110,
            child: _Glow(size: 240, color: Color(0x26F7C948)),
          ),
          Positioned(
            bottom: 40,
            left: -90,
            child: _Glow(size: 300, color: Color(0x44C04DFF)),
          ),
        ],
        Positioned.fill(child: child),
      ],
    ),
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
      ),
    ),
  );
}

/// A page on the glass background, for the home screen and pushed pages.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({super.key, required this.body, this.bottomBar});
  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BetSafeColors.night,
    body: AppBackground(child: body),
    bottomNavigationBar: bottomBar,
  );
}

/// A frosted-glass card from project05, made with the glassmorphism package.
/// Sizes itself to its child. [tint] colors the glass, such as green for a
/// win. With [onTap] the whole panel is tappable; screen readers skip that, so
/// the panel needs its own button for the same action.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.tint,
    this.onTap,
    this.strong = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final VoidCallback? onTap;

  /// A brighter, more opaque glass, for the panel that should stand out.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    // Text and icons inside are light, whatever surrounds the panel.
    Widget content = DefaultTextStyle.merge(
      style: const TextStyle(color: BetSafeColors.ink),
      child: IconTheme.merge(
        data: const IconThemeData(color: BetSafeColors.ink),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          excludeFromSemantics: true,
          child: content,
        ),
      );
    }
    // A solid panel with a bright edge instead of see-through glass.
    if (MediaQuery.highContrastOf(context)) {
      return Container(
        decoration: BoxDecoration(
          color: BetSafeColors.paper,
          borderRadius: borderRadius,
          border: Border.all(color: const Color(0xCCFFFFFF), width: 1.5),
        ),
        child: content,
      );
    }
    final base = tint ?? Colors.white;
    final (top, bottom) = tint != null
        ? (.30, .10)
        : strong
        ? (.22, .08)
        : (.15, .05);
    return GlassmorphicContainer(
      borderRadius: radius,
      blur: 14,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          base.withValues(alpha: top),
          base.withValues(alpha: bottom),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (tint ?? Colors.white).withValues(alpha: strong ? .55 : .35),
          Colors.white.withValues(alpha: .08),
        ],
      ),
      child: content,
    );
  }
}

/// One tab of [GlassTabBar].
class GlassTab {
  const GlassTab(this.label, this.icon, this.selectedIcon, {this.badge = 0});
  final String label;
  final IconData icon, selectedIcon;

  /// A count shown on the icon, such as open picks. Zero shows nothing.
  final int badge;
}

/// project05's segmented tab bar on glass: the chosen tab slides in a purple
/// pill, and a count badge bounces when it changes.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });
  final List<GlassTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => GlassPanel(
    padding: const EdgeInsets.all(6),
    radius: 22,
    strong: true,
    child: Row(
      children: [
        for (final (index, tab) in tabs.indexed)
          Expanded(
            child: _TabButton(
              tab: tab,
              selected: index == selectedIndex,
              onTap: () => onSelected(index),
            ),
          ),
      ],
    ),
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });
  final GlassTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? BetSafeColors.ink : BetSafeColors.muted;
    final still = !Motion.on(context);
    Widget badge = _CountBadge(count: tab.badge);
    if (!still) {
      // Bounces each time the count changes.
      badge = badge
          .animate(key: ValueKey(tab.badge))
          .scaleXY(
            begin: .4,
            end: 1,
            duration: 450.ms,
            curve: Curves.elasticOut,
          );
    }
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      value: tab.badge > 0 ? '${tab.badge}' : null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: still ? Duration.zero : const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? BetSafeColors.purpleStrong.withValues(alpha: .9)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          // No alignment here: it would stretch the tab to the full height.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? tab.selectedIcon : tab.icon,
                    size: 21,
                    color: color,
                  ),
                  if (tab.badge > 0)
                    Positioned(top: -7, right: -15, child: badge),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small yellow pill with a count; "99+" past 99.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 18),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: BetSafeColors.yellow,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: BetSafeColors.dusk, width: 1.5),
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
      style: const TextStyle(
        color: BetSafeColors.onAccent,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
