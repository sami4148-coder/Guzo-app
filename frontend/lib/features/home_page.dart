import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/brand.dart';
import '../../core/api.dart';
import '../../core/app_navigation.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_state.dart';
import 'first_login_guide.dart';
import 'notifications/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _guests = 2;
  final TextEditingController _searchController = TextEditingController();
  List<Hotel> _hotels = [];
  List<Hotel> _cheapStays = [];
  int _totalHotelsCount = 0;
  bool _loading = true;
  bool _guideScheduled = false;
  bool _guideShown = false;

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFeatured() async {
    try {
      final data =
          await ApiClient.instance.get('/hotels', query: {'limit': '24'});
      if (!mounted) return;
      final hotels = (data as List).map((j) => Hotel.fromJson(j)).toList();

      _hotels = hotels;
      _totalHotelsCount = hotels.length;

      final sorted = [...hotels]
        ..sort((a, b) => a.basePrice.compareTo(b.basePrice));
      _cheapStays = sorted.take(8).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _goExplore() {
    context.go('/explore?guests=$_guests');
  }

  void _searchStays() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.go('/explore?city=${Uri.encodeComponent(query)}&guests=$_guests');
    } else {
      context.go('/explore?guests=$_guests');
    }
  }

  @override
  Widget build(BuildContext context) {
    _maybeShowFirstLoginGuide();
    final auth = context.watch<AuthState>();
    final compactHeader = MediaQuery.sizeOf(context).width < 400;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GuzoColors.ink.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const GuzoLogo(),
                      const Spacer(),
                      if (!auth.isLoggedIn) ...[
                        if (MediaQuery.sizeOf(context).width >= 640) ...[
                          _TopBarAction(
                            label: 'Explore',
                            icon: Icons.explore_outlined,
                            onTap: () => context.go('/explore'),
                          ),
                          const SizedBox(width: 6),
                        ],
                        _TopBarAction(
                          label: 'Sign in',
                          icon: Icons.login_rounded,
                          onTap: () => context.go('/login'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => context.go('/register'),
                          style: FilledButton.styleFrom(
                            backgroundColor: GuzoColors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: compactHeader ? 12 : 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!compactHeader) ...[
                                const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                compactHeader ? 'Join' : 'Join GUZO',
                              ),
                            ],
                          ),
                        ),
                      ] else
                        Row(
                          children: [
                            if (auth.isTraveler)
                              const NotificationsBellButton(
                                backgroundColor: Color(0x99FFFFFF),
                              ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              tooltip: 'Account menu',
                              offset: const Offset(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onSelected: (v) {
                                if (v == 'logout') {
                                  auth.logout();
                                  context.go('/login');
                                }
                                if (v == 'profile') context.go('/user');
                                if (v == 'dash') context.go('/dashboard');
                                if (v == 'owner') context.go('/owner');
                                if (v == 'admin') context.go('/admin');
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  enabled: false,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        auth.user?.fullName ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: GuzoColors.ink,
                                        ),
                                      ),
                                      Text(
                                        auth.user?.email ?? '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: GuzoColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'profile',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_outline_rounded,
                                          size: 18),
                                      SizedBox(width: 10),
                                      Text('My Profile'),
                                    ],
                                  ),
                                ),
                                if (auth.isTraveler)
                                  const PopupMenuItem(
                                    value: 'dash',
                                    child: Row(
                                      children: [
                                        Icon(Icons.luggage_outlined, size: 18),
                                        SizedBox(width: 10),
                                        Text('My Stays & Bookings'),
                                      ],
                                    ),
                                  ),
                                if (auth.isOwner)
                                  const PopupMenuItem(
                                    value: 'owner',
                                    child: Row(
                                      children: [
                                        Icon(Icons.dashboard_outlined,
                                            size: 18),
                                        SizedBox(width: 10),
                                        Text('Host Dashboard'),
                                      ],
                                    ),
                                  ),
                                if (auth.isAdmin)
                                  const PopupMenuItem(
                                    value: 'admin',
                                    child: Row(
                                      children: [
                                        Icon(Icons.admin_panel_settings_outlined,
                                            size: 18),
                                        SizedBox(width: 10),
                                        Text('Admin Dashboard'),
                                      ],
                                    ),
                                  ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout_rounded,
                                          size: 18, color: Colors.red),
                                      SizedBox(width: 10),
                                      Text(
                                        'Sign out',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: GuzoColors.green
                                        .withValues(alpha: 0.35),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: GuzoColors.green,
                                  child: Text(
                                    _initials(auth.user?.fullName ?? ''),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackground()),
          RefreshIndicator(
            onRefresh: _loadFeatured,
            color: GuzoColors.green,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                _screenHero(),
                const SizedBox(height: 18),
                _quickSearchCard(),
                const SizedBox(height: 24),
                _trustBadges(),
                const SizedBox(height: 26),
                _section(
                  'Hotels posted by owners',
                  _hotelPostsSection(),
                  subtitle:
                      'Browse authentic stays posted directly by property owners',
                  trailing: TextButton.icon(
                    onPressed: () => context.go('/explore'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('See more'),
                    style: TextButton.styleFrom(
                      foregroundColor: GuzoColors.green,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                _section(
                  'Best prices',
                  _bestPriceSection(),
                  subtitle: 'Budget-friendly accommodations across Ethiopia',
                  trailing: TextButton.icon(
                    onPressed: () => context.go('/explore'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('See all'),
                    style: TextButton.styleFrom(
                      foregroundColor: GuzoColors.green,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                _section(
                  'Why book with GUZO',
                  _whyGuzoSection(),
                  subtitle:
                      'Your trusted Ethiopian travel & hospitality companion',
                ),
                const SizedBox(height: 26),
                _promoBanner(),
                const SizedBox(height: 32),
                const _HomeFooter(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentPath: '/'),
    );
  }

  void _maybeShowFirstLoginGuide() {
    if (_guideScheduled || _guideShown) return;
    _guideScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!context.read<AuthState>().walkthroughPending) {
        _guideScheduled = false;
        return;
      }
      _guideShown = true;
      await showFirstLoginGuide(context);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────────────────────────
  Widget _screenHero() {
    final auth = context.read<AuthState>();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = auth.user?.fullName.split(' ').first;

    return SizedBox(
      height: 440,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1400&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E7D6F), Color(0xFF1B4E46)],
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.80),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 40, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wb_sunny_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name == null ? greeting : '$greeting, $name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  'Escape the\nordinary.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.4,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Handpicked hotels, resorts and guesthouses\nposted by owners across Ethiopia — book in seconds.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _goExplore,
                          icon: const Icon(Icons.search_rounded, size: 20),
                          label: const Text(
                            'Explore stays',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: GuzoColors.ink,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 54,
                      width: 54,
                      child: OutlinedButton(
                        onPressed: () => context.go('/explore'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                        ),
                        child: const Icon(Icons.tune_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // QUICK SEARCH CARD
  // ─────────────────────────────────────────────────────────────
  Widget _quickSearchCard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE2EBE8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: GuzoColors.ink.withValues(alpha: 0.07),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F7F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchStays(),
                      decoration: InputDecoration(
                        hintText: 'Search hotels by name, location or city...',
                        hintStyle: const TextStyle(
                          color: GuzoColors.muted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: GuzoColors.green,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => _searchStays(),
                  icon: const Icon(Icons.travel_explore_rounded, size: 18),
                  label: const Text('Search'),
                  style: FilledButton.styleFrom(
                    backgroundColor: GuzoColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HOTELS POSTED BY OWNERS (Curated list with click-through to details)
  // ─────────────────────────────────────────────────────────────
  Widget _hotelPostsSection() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: GuzoColors.green),
        ),
      );
    }
    if (_hotels.isEmpty) {
      return const SizedBox.shrink();
    }

    // Display a curated selection of 4 hotel posts (not all of them)
    final displayedHotels = _hotels.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              if (isWide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedHotels.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (context, index) =>
                      _HotelPostCard(hotel: displayedHotels[index]),
                );
              }
              return Column(
                children: [
                  for (final hotel in displayedHotels) ...[
                    _HotelPostCard(hotel: hotel),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _seeMoreHotelsButton(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // "SEE MORE" OPTION DIRECTING TO FULL EXPLORE LIST
  // ─────────────────────────────────────────────────────────────
  Widget _seeMoreHotelsButton() {
    final remaining =
        (_totalHotelsCount > 4) ? _totalHotelsCount - 4 : 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/explore'),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: GuzoColors.green.withValues(alpha: 0.35),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: GuzoColors.green.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GuzoColors.green,
                      GuzoColors.green.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'See more hotels',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: GuzoColors.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remaining > 0
                          ? 'Browse all $remaining+ available stays across Ethiopia'
                          : 'Explore our complete list of hotels, resorts & guesthouses',
                      style: const TextStyle(
                        fontSize: 12,
                        color: GuzoColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3AAE9A), GuzoColors.green],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: GuzoColors.green.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // WHY BOOK WITH GUZO (Trust Grid)
  // ─────────────────────────────────────────────────────────────
  Widget _whyGuzoSection() {
    final perks = [
      (
        icon: Icons.verified_user_rounded,
        title: 'Direct from Owners',
        subtitle: 'Authentic photos, transparent prices and verified property owners',
      ),
      (
        icon: Icons.bolt_rounded,
        title: 'Instant Confirmation',
        subtitle: 'Direct confirmation sent to your phone with zero delay',
      ),
      (
        icon: Icons.credit_card_rounded,
        title: 'Flexible Local Payments',
        subtitle: 'Easily pay via Telebirr, CBE Birr or local cards',
      ),
      (
        icon: Icons.support_agent_rounded,
        title: '24/7 Local Concierge',
        subtitle: 'Dedicated Ethiopian travel support whenever needed',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: perks.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 1.4 : 1.15,
            ),
            itemBuilder: (context, index) {
              final perk = perks[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5ECEB)),
                  boxShadow: [
                    BoxShadow(
                      color: GuzoColors.ink.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: GuzoColors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        perk.icon,
                        color: GuzoColors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      perk.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: GuzoColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      perk.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: GuzoColors.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _trustBadges() {
    final badges = [
      (icon: Icons.verified_rounded, label: 'Verified owner stays'),
      (icon: Icons.support_agent_rounded, label: '24/7 support'),
      (icon: Icons.bolt_rounded, label: 'Instant booking'),
      (icon: Icons.lock_outline_rounded, label: 'Secure payment'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5ECEA)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badges[i].icon, size: 15, color: GuzoColors.green),
              const SizedBox(width: 6),
              Text(
                badges[i].label,
                style: const TextStyle(
                  color: GuzoColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(
    String title,
    Widget child, {
    String? subtitle,
    Widget? trailing,
  }) =>
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        color: GuzoColors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: GuzoColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: GuzoColors.muted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      );

  Widget _bestPriceSection() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_cheapStays.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _cheapStays.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _PriceCard(
          hotel: _cheapStays[i],
          rank: i + 1,
          isAd: i % 4 == 1,
        ),
      ),
    );
  }

  Widget _promoBanner() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GuzoColors.green,
                  GuzoColors.green.withValues(alpha: 0.78),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: GuzoColors.green.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get 15% off your first booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Use code GUZO15 at checkout',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => context.go('/explore'),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
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

// ─────────────────────────────────────────────────────────────
// TOP BAR HELPERS
// ─────────────────────────────────────────────────────────────
class _TopBarAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: GuzoColors.ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: GuzoColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();
  return parts.isEmpty ? '?' : parts;
}

// ─────────────────────────────────────────────────────────────
// BACKGROUND
// ─────────────────────────────────────────────────────────────
class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

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
              size: 260,
              color: GuzoColors.green.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            top: -60,
            right: -90,
            child: _Blob(
              size: 220,
              color: const Color(0xFF4FB3A3).withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 360,
            left: -120,
            child: _Blob(
              size: 240,
              color: const Color(0xFFD49B25).withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: _Blob(
              size: 300,
              color: GuzoColors.green.withValues(alpha: 0.14),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
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
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GuzoColors.ink.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    const spacing = 26.0;
    const radius = 1.1;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// BEAUTIFUL FOOTER
// ─────────────────────────────────────────────────────────────
class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1F1C),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            GuzoColors.green,
                            GuzoColors.green.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.travel_explore_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GUZO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Stay curious. Stay anywhere.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Wrap(
                  spacing: 32,
                  runSpacing: 18,
                  children: [
                    _FooterCol(
                      title: 'Discover',
                      links: ['Explore', 'Popular', 'Best prices', 'Blog'],
                    ),
                    _FooterCol(
                      title: 'Company',
                      links: ['About', 'Careers', 'Press', 'Partners'],
                    ),
                    _FooterCol(
                      title: 'Support',
                      links: ['Help center', 'Contact', 'Safety', 'Terms'],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '© 2025 GUZO. All rights reserved.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    _SocialIcon(icon: Icons.public_rounded, onTap: () {}),
                    const SizedBox(width: 8),
                    _SocialIcon(
                      icon: Icons.chat_bubble_outline,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _SocialIcon(
                      icon: Icons.camera_alt_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterCol extends StatelessWidget {
  final String title;
  final List<String> links;
  const _FooterCol({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          for (final l in links) ...[
            InkWell(
              onTap: l.toLowerCase() == 'help center'
                  ? () => context.push('/help')
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  l,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, size: 16, color: Colors.white70),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HOTEL POST CARD (Shows hotels posted by owners, opens full details on tap)
// ─────────────────────────────────────────────────────────────
class _HotelPostCard extends StatelessWidget {
  final Hotel hotel;
  const _HotelPostCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_ET',
      symbol: 'ETB ',
      decimalDigits: 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECE9)),
        boxShadow: [
          BoxShadow(
            color: GuzoColors.ink.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Navigates directly to the full details page for this hotel
          onTap: () => context.push('/hotels/${hotel.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image with badges
              SizedBox(
                height: 195,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hotel.coverImage != null &&
                        hotel.coverImage!.isNotEmpty)
                      Image.network(
                        hotel.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    else
                      _placeholder(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.40),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.50),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                    // Top-left: Owner Post badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: GuzoColors.ink.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 13,
                              color: Color(0xFF43B8AE),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'OWNER POST',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Top-right: Rating chip
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: Color(0xFFD49B25),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              hotel.rating > 0
                                  ? hotel.rating.toStringAsFixed(1)
                                  : '4.8',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: GuzoColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Bottom-right: Price tag on image
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: GuzoColors.green,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: GuzoColors.green.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currency.format(hotel.basePrice),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              ' / night',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotelDisplayName(hotel.name, hotel.city),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: GuzoColors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: GuzoColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hotel.city.isNotEmpty
                                ? '${hotel.city}, Ethiopia'
                                : 'Ethiopia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: GuzoColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hotel.amenities.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: hotel.amenities.take(3).map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F6F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              amenity,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: GuzoColors.muted,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3AAE9A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Rooms available',
                              style: TextStyle(
                                fontSize: 11,
                                color: GuzoColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: GuzoColors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View details',
                                style: TextStyle(
                                  color: GuzoColors.green,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: GuzoColors.green,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D6F), Color(0xFF1B4E46)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.hotel_rounded, size: 42, color: Colors.white60),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// PRICE CARD
// ─────────────────────────────────────────────────────────────
class _PriceCard extends StatelessWidget {
  final Hotel hotel;
  final int rank;
  final bool isAd;
  const _PriceCard({
    required this.hotel,
    required this.rank,
    this.isAd = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_ET',
      symbol: 'ETB ',
      decimalDigits: 0,
    );

    return SizedBox(
      width: 180,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => context.push('/hotels/${hotel.id}'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAd
                    ? GuzoColors.green.withValues(alpha: 0.45)
                    : const Color(0xFFE4EBE9),
                width: isAd ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: GuzoColors.ink.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hotel.coverImage != null &&
                            hotel.coverImage!.isNotEmpty)
                          Image.network(
                            hotel.coverImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        else
                          _imagePlaceholder(),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '#$rank',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: GuzoColors.ink,
                              ),
                            ),
                          ),
                        ),
                        if (isAd)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: GuzoColors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'AD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: GuzoColors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currency.format(hotel.basePrice),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Text(
                                    '/night',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hotelDisplayName(hotel.name, hotel.city),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: GuzoColors.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: GuzoColors.muted,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                hotel.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: GuzoColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE7EFED), Color(0xFFD8E5E2)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.hotel_rounded, size: 36, color: Color(0xFF9BAEAA)),
        ),
      );
}
