import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    required this.currentPath,
    this.bookingsCount,
    this.onCenterActionTap,
    this.onTabReselected,
    super.key,
  });

  final String currentPath;
  final int? bookingsCount;
  final VoidCallback? onCenterActionTap;
  final void Function(String route)? onTabReselected;

  int get selectedIndex {
    if (currentPath == '/explore' || currentPath.startsWith('/hotels/')) {
      return 1;
    }
    if (currentPath == '/dashboard' || currentPath.startsWith('/book/')) {
      return 2;
    }
    if (currentPath == '/user' || currentPath.startsWith('/profile')) {
      return 3;
    }
    return 0;
  }

  void _handleTap(BuildContext context, String route, bool isActive) {
    if (isActive) {
      onTabReselected?.call(route);
    } else {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isHome = currentPath == '/';
    final isExplore =
        currentPath == '/explore' || currentPath.startsWith('/hotels/');
    final isTrips =
        currentPath == '/dashboard' || currentPath.startsWith('/book/');
    final isProfile =
        currentPath == '/user' || currentPath.startsWith('/profile');

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: false,
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset * 0.4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.88),
                        Colors.white.withValues(alpha: 0.68),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.92),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GuzoColors.ink.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: GuzoColors.green.withValues(alpha: 0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _NavBtn(
                        activeIcon: Icons.home_rounded,
                        inactiveIcon: Icons.home_outlined,
                        label: 'Home',
                        active: isHome,
                        onTap: () => _handleTap(context, '/', isHome),
                      ),
                      _NavBtn(
                        activeIcon: Icons.explore_rounded,
                        inactiveIcon: Icons.explore_outlined,
                        label: 'Explore',
                        active: isExplore,
                        onTap: () => _handleTap(context, '/explore', isExplore),
                      ),
                      _CenterAction(
                        onTap: onCenterActionTap ??
                            () => context.go('/explore'),
                      ),
                      _NavBtn(
                        activeIcon: Icons.receipt_long_rounded,
                        inactiveIcon: Icons.receipt_long_outlined,
                        label: 'Trips',
                        active: isTrips,
                        badgeCount: bookingsCount,
                        onTap: () =>
                            _handleTap(context, '/dashboard', isTrips),
                      ),
                      _NavBtn(
                        activeIcon: Icons.person_rounded,
                        inactiveIcon: Icons.person_outline_rounded,
                        label: 'Profile',
                        active: isProfile,
                        onTap: () => _handleTap(context, '/user', isProfile),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: Colors.white.withValues(alpha: 0.25),
          highlightColor: Colors.white.withValues(alpha: 0.15),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3AAE9A),
                  GuzoColors.green,
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.40),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: GuzoColors.green.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool active;
  final int? badgeCount;
  final VoidCallback onTap;

  const _NavBtn({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasBadge = badgeCount != null && badgeCount! > 0;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: GuzoColors.green.withValues(alpha: 0.12),
          highlightColor: GuzoColors.green.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        GuzoColors.green.withValues(alpha: 0.16),
                        GuzoColors.green.withValues(alpha: 0.05),
                      ],
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedScale(
                      scale: active ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        active ? activeIcon : inactiveIcon,
                        size: 22,
                        color: active ? GuzoColors.green : GuzoColors.muted,
                      ),
                    ),
                    if (hasBadge)
                      Positioned(
                        top: -4,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE05252),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE05252)
                                    .withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            badgeCount! > 99 ? '99+' : '$badgeCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? GuzoColors.green : GuzoColors.muted,
                    letterSpacing: -0.1,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  width: active ? 16 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: GuzoColors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

