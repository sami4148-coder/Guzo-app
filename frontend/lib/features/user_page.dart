import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/brand.dart';
import '../core/theme.dart';
import '../state/auth_state.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isOwner = user.role == 'OWNER';
    final isAdmin = user.role == 'ADMIN';
    final dashboardPath = isAdmin
        ? '/admin'
        : isOwner
            ? '/owner'
            : '/dashboard';
    final dashboardLabel = isAdmin
        ? 'Admin dashboard'
        : isOwner
            ? 'Owner dashboard'
            : 'My trips';
    final accountRole = isAdmin
        ? 'Administrator'
        : isOwner
            ? 'Hotel owner'
            : 'Traveler';
    final initials = user.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _UserBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
                  children: [
                    _topBar(context, auth),
                    const SizedBox(height: 24), // Adjusted spacing
                    _sectionLabel('Profile'),
                    const SizedBox(height: 12),
                    _profileCard(
                      name: user.fullName,
                      email: user.email,
                      role: accountRole,
                      initials: initials,
                      isDemo: auth.isDemoSession,
                      onEdit: () => _showEditProfileDialog(context, auth),
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('Account'),
                    const SizedBox(height: 12),
                    _settingsGroup([
                      _SettingItem(
                        icon: isAdmin
                            ? Icons.admin_panel_settings_rounded
                            : isOwner
                                ? Icons.apartment_rounded
                                : Icons.luggage_rounded,
                        title: dashboardLabel,
                        subtitle: isAdmin
                            ? 'Review platform activity and listings'
                            : isOwner
                                ? 'Manage your property and reservations'
                                : 'See and manage your reservations',
                        accent: GuzoColors.green,
                        onTap: () => context.go(dashboardPath),
                      ),
                      _SettingItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit profile',
                        subtitle: 'Name, photo, contact info',
                        accent: const Color(0xFF2E86AB),
                        onTap: () => _showEditProfileDialog(context, auth),
                      ),
                      _SettingItem(
                        icon: Icons.lock_outline_rounded,
                        title: 'Security & password',
                        subtitle: 'Password, 2FA, sessions',
                        accent: const Color(0xFF8E6BBF),
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Trips, offers, reminders',
                        accent: const Color(0xFFD49B25),
                        onTap: () {},
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _sectionLabel('Support'),
                    const SizedBox(height: 12),
                    _settingsGroup([
                      _SettingItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help center',
                        subtitle: 'FAQs and guides',
                        accent: const Color(0xFF2E86AB),
                        onTap: () => context.push('/help'),
                      ),
                      _SettingItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Contact support',
                        subtitle: 'We reply 24/7',
                        accent: GuzoColors.green,
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.info_outline_rounded,
                        title: 'About GUZO',
                        subtitle: 'Version, legal',
                        accent: GuzoColors.muted,
                        onTap: () {},
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _signOutButton(context, auth),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'GUZO · v1.0.0',
                        style: TextStyle(
                          color: GuzoColors.muted.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _UserBottomBar(currentPath: '/user'),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Top bar
  // ─────────────────────────────────────────────────────────────
  Widget _topBar(BuildContext context, AuthState auth) {
    return Row(
      children: [
        const GuzoLogo(),
        const Spacer(),
        Material(
          color: Colors.white.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5ECEA)),
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: GuzoColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Profile card
  // ─────────────────────────────────────────────────────────────
  Widget _profileCard({
    required String name,
    required String email,
    required String role,
    required String initials,
    required bool isDemo,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6ECEB)),
        boxShadow: [
          BoxShadow(
            color: GuzoColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GuzoColors.green,
                      GuzoColors.green.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: GuzoColors.green.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: -0.4,
                        color: GuzoColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: GuzoColors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              color: GuzoColors.green,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (isDemo) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF6E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DEMO',
                              style: TextStyle(
                                color: Color(0xFFD49B25),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: GuzoColors.green.withValues(alpha: 0.1),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEdit,
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 17,
                      color: GuzoColors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFEEF2F1)),
          ),
          _profileRow(Icons.mail_outline_rounded, 'Email', email),
          const SizedBox(height: 12),
          _profileRow(
            Icons.verified_user_outlined,
            'Account status',
            'Active · verified',
          ),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: GuzoColors.muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: GuzoColors.muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GuzoColors.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Settings group
  // ─────────────────────────────────────────────────────────────
  Widget _settingsGroup(List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6ECEB)),
        boxShadow: [
          BoxShadow(
            color: GuzoColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              items[i],
              if (i != items.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 68),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFEEF2F1),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: GuzoColors.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: GuzoColors.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOutButton(BuildContext context, AuthState auth) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () async {
          await auth.logout();
          if (context.mounted) context.go('/login');
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Sign out',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC05746),
          side: const BorderSide(color: Color(0xFFF5B5B5), width: 1.2),
          backgroundColor: const Color(0xFFFDECEC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Edit profile dialog (name only)
  // ─────────────────────────────────────────────────────────────
  Future<void> _showEditProfileDialog(
    BuildContext context,
    AuthState auth,
  ) async {
    final user = auth.user;
    if (user == null) return;

    final controller = TextEditingController(text: user.fullName);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Edit name',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Full name',
              hintText: 'Enter your full name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.isEmpty || newName == user.fullName) {
      return;
    }

    await auth.updateFullName(newName);
  }
}

// ─────────────────────────────────────────────────────────────
// Setting item
// ─────────────────────────────────────────────────────────────
class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: GuzoColors.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: GuzoColors.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: GuzoColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────
class _UserBackground extends StatelessWidget {
  const _UserBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF1F7F5),
                  Color(0xFFF6F9F8),
                  Color(0xFFEEF4F2),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -80,
            child: _Blob(
              size: 240,
              color: GuzoColors.green.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: -60,
            right: -90,
            child: _Blob(
              size: 200,
              color: const Color(0xFF4FB3A3).withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: _Blob(
              size: 280,
              color: GuzoColors.green.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom bar
// ─────────────────────────────────────────────────────────────
class _UserBottomBar extends StatelessWidget {
  final String currentPath;
  const _UserBottomBar({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset * 0.4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: GuzoColors.ink.withValues(alpha: 0.10),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavBtn(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  active: currentPath == '/',
                  onTap: () => context.go('/'),
                ),
                _NavBtn(
                  icon: Icons.explore_outlined,
                  label: 'Explore',
                  active: currentPath == '/explore',
                  onTap: () => context.go('/explore'),
                ),
                _CenterAction(onTap: () => context.go('/explore')),
                _NavBtn(
                  icon: Icons.receipt_long_outlined,
                  label: 'Trips',
                  active: currentPath == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                ),
                _NavBtn(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  active: currentPath == '/user',
                  onTap: () => context.go('/user'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: active
                  ? GuzoColors.green.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: active ? GuzoColors.green : GuzoColors.muted,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? GuzoColors.green : GuzoColors.muted,
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

class _CenterAction extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GuzoColors.green,
                  GuzoColors.green.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: GuzoColors.green.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
