import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/app_navigation.dart';
import '../../core/theme.dart';
import '../../state/auth_state.dart';
import '../../state/favorite_hotels_state.dart';
import '../hotel/favorite_hotel_button.dart';
import '../notifications/notifications_page.dart';

enum _StaysTab { bookings, favorites }

class TravelerDashboard extends StatefulWidget {
  const TravelerDashboard({super.key});

  @override
  State<TravelerDashboard> createState() => _TravelerDashboardState();
}

class _TravelerDashboardState extends State<TravelerDashboard> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _hotels = [];
  bool _loadingBookings = true;
  bool _loadingHotels = true;
  String? _bookingError;
  String? _hotelError;
  String? _favoriteError;
  _StaysTab _selectedTab = _StaysTab.bookings;

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthState>().user?.id;
    if (userId != null) unawaited(_loadFavorites(userId));
    unawaited(_loadData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites(String userId) async {
    try {
      await context.read<FavoriteHotelsState>().loadForUser(userId);
      if (mounted) setState(() => _favoriteError = null);
    } catch (error) {
      if (mounted) setState(() => _favoriteError = error.toString());
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingBookings = true;
      _loadingHotels = true;
      _bookingError = null;
      _hotelError = null;
    });

    try {
      final response = await ApiClient.instance.getList('/bookings/my');
      if (mounted) {
        setState(() {
          _bookings = response
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
      }
    } catch (error) {
      if (mounted) setState(() => _bookingError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingBookings = false);
    }

    try {
      final response = await ApiClient.instance.getList('/hotels');
      if (mounted) {
        setState(() {
          _hotels = response
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
      }
    } catch (error) {
      if (mounted) setState(() => _hotelError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingHotels = false);
    }
  }

  Future<void> _refresh() async {
    final userId = context.read<AuthState>().user?.id;
    await Future.wait([
      _loadData(),
      if (userId != null) _loadFavorites(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteHotelsState>();
    final favoriteHotels =
        _hotels.where((hotel) => favorites.contains('${hotel['id']}')).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _DashboardBackground()),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: GuzoColors.green,
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    children: [
                      _topBar(context),
                      const SizedBox(height: 28),
                      const Text(
                        'Your stays',
                        style: TextStyle(
                          color: GuzoColors.ink,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Keep track of your bookings and saved hotels.',
                        style: TextStyle(
                          color: GuzoColors.muted,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _tabSelector(favoriteHotels.length),
                      const SizedBox(height: 20),
                      if (_selectedTab == _StaysTab.bookings)
                        _bookingsContent()
                      else
                        _favoritesContent(favorites, favoriteHotels),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentPath: '/dashboard',
        bookingsCount: _bookings.length,
        onTabReselected: (route) {
          if (route == '/dashboard' && _scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          }
        },
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GuzoColors.green,
                GuzoColors.green.withValues(alpha: 0.75)
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.travel_explore_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'GUZO',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: GuzoColors.ink,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        const NotificationsBellButton(backgroundColor: Color(0xE6FFFFFF)),
      ],
    );
  }

  Widget _tabSelector(int favoriteCount) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4ECE9)),
      ),
      child: Row(
        children: [
          _tabButton(
            label: 'Bookings',
            count: _bookings.length,
            selected: _selectedTab == _StaysTab.bookings,
            onTap: () => setState(() => _selectedTab = _StaysTab.bookings),
          ),
          _tabButton(
            label: 'Favorites',
            count: favoriteCount,
            selected: _selectedTab == _StaysTab.favorites,
            onTap: () => setState(() => _selectedTab = _StaysTab.favorites),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? GuzoColors.green : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : GuzoColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.2)
                        : const Color(0xFFF0F4F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? Colors.white : GuzoColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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

  Widget _bookingsContent() {
    if (_loadingBookings) return _loadingState('Loading your bookings...');
    if (_bookingError != null) {
      return _messageState(
        icon: Icons.cloud_off_outlined,
        title: 'Your bookings could not be loaded',
        message: _bookingError!,
        actionLabel: 'Try again',
        onAction: _loadData,
      );
    }
    if (_bookings.isEmpty) {
      return _messageState(
        icon: Icons.luggage_outlined,
        title: 'No bookings yet',
        message: 'When you book a hotel, the details will show up here.',
        actionLabel: 'Explore hotels',
        onAction: () => context.go('/explore'),
      );
    }
    return Column(
      children: [
        for (final booking in _bookings) ...[
          _bookingCard(booking),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _favoritesContent(
    FavoriteHotelsState favorites,
    List<Map<String, dynamic>> favoriteHotels,
  ) {
    if (_favoriteError != null) {
      return _messageState(
        icon: Icons.favorite_border_rounded,
        title: 'Favorites could not be loaded',
        message: _favoriteError!,
        actionLabel: 'Try again',
        onAction: () {
          final userId = context.read<AuthState>().user?.id;
          if (userId != null) unawaited(_loadFavorites(userId));
        },
      );
    }
    if (favorites.loading || _loadingHotels) {
      return _loadingState('Loading your favorite hotels...');
    }
    if (_hotelError != null) {
      return _messageState(
        icon: Icons.cloud_off_outlined,
        title: 'Favorite hotels could not be loaded',
        message: _hotelError!,
        actionLabel: 'Try again',
        onAction: _loadData,
      );
    }
    if (favoriteHotels.isEmpty) {
      return _messageState(
        icon: Icons.favorite_border_rounded,
        title: 'No favorites saved',
        message: 'Tap the heart on a hotel to keep it here for later.',
        actionLabel: 'Find a hotel',
        onAction: () => context.go('/explore'),
      );
    }
    return Column(
      children: [
        for (final hotel in favoriteHotels) ...[
          _hotelCard(hotel),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _bookingCard(Map<String, dynamic> booking) {
    final hotel = booking['hotel'] is Map
        ? Map<String, dynamic>.from(booking['hotel'] as Map)
        : <String, dynamic>{};
    final hotelId = hotel['id']?.toString();
    final hotelName = hotel['name']?.toString() ?? 'Your booked hotel';
    final city = hotel['city']?.toString() ?? '';
    final matchingHotel = _hotelById(hotelId);
    final checkIn = _formatDate(booking['checkIn']);
    final checkOut = _formatDate(booking['checkOut']);
    final status = booking['status']?.toString() ?? 'PENDING';
    final price = booking['totalPrice'];
    final currency = NumberFormat.currency(
      locale: 'en_ET',
      symbol: 'ETB ',
      decimalDigits: 0,
    );

    return _StayCard(
      hotelName: hotelName,
      city: city,
      imageUrl: matchingHotel?['coverImage']?.toString(),
      onTap: hotelId == null ? null : () => context.push('/hotels/$hotelId'),
      trailing: _statusChip(status),
      footer: Row(
        children: [
          Expanded(
            child: _bookingDetail(
              Icons.calendar_month_outlined,
              checkIn == null || checkOut == null
                  ? 'Dates unavailable'
                  : '$checkIn – $checkOut',
            ),
          ),
          if (price is num)
            Text(
              currency.format(price),
              style: const TextStyle(
                color: GuzoColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _hotelCard(Map<String, dynamic> hotel) {
    final hotelId = hotel['id']?.toString();
    return _StayCard(
      hotelName: hotel['name']?.toString() ?? 'Hotel',
      city: hotel['city']?.toString() ?? '',
      imageUrl: hotel['coverImage']?.toString(),
      onTap: hotelId == null ? null : () => context.push('/hotels/$hotelId'),
      trailing: hotelId == null
          ? const SizedBox.shrink()
          : FavoriteHotelButton(hotelId: hotelId, size: 38, iconSize: 18),
      footer: Row(
        children: [
          const Icon(
            Icons.payments_outlined,
            size: 16,
            color: GuzoColors.green,
          ),
          const SizedBox(width: 6),
          Text(
            '${NumberFormat.currency(locale: 'en_ET', symbol: 'ETB ', decimalDigits: 0).format((hotel['basePrice'] as num?)?.toInt() ?? 0)} / night',
            style: const TextStyle(
              color: GuzoColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingDetail(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: GuzoColors.green),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GuzoColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.toUpperCase();
    final color = switch (normalized) {
      'CONFIRMED' => GuzoColors.green,
      'CANCELLED' => const Color(0xFFB64E46),
      'COMPLETED' => const Color(0xFF2E86AB),
      _ => const Color(0xFFD49B25),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalized,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Map<String, dynamic>? _hotelById(String? id) {
    if (id == null) return null;
    for (final hotel in _hotels) {
      if ('${hotel['id']}' == id) return hotel;
    }
    return null;
  }

  String? _formatDate(Object? value) {
    if (value is! String) return null;
    final date = DateTime.tryParse(value);
    return date == null ? null : DateFormat('MMM d, yyyy').format(date);
  }

  Widget _loadingState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          const CircularProgressIndicator(color: GuzoColors.green),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(color: GuzoColors.muted)),
        ],
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4ECE9)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: GuzoColors.green),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GuzoColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GuzoColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: GuzoColors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _StayCard extends StatelessWidget {
  const _StayCard({
    required this.hotelName,
    required this.city,
    required this.imageUrl,
    required this.onTap,
    required this.trailing,
    required this.footer,
  });

  final String hotelName;
  final String city;
  final String? imageUrl;
  final VoidCallback? onTap;
  final Widget trailing;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE4ECE9)),
            boxShadow: [
              BoxShadow(
                color: GuzoColors.ink.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(
                      width: 90,
                      height: 86,
                      child: imageUrl == null || imageUrl!.isEmpty
                          ? _imagePlaceholder()
                          : Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hotelName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: GuzoColors.ink,
                              fontSize: 15,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (city.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: GuzoColors.muted,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    city,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: GuzoColors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing,
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: const Color(0xFFEAF0EE)),
              const SizedBox(height: 12),
              footer,
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFE7EFED),
        child: const Icon(
          Icons.hotel_rounded,
          color: Color(0xFF9BAEAA),
          size: 30,
        ),
      );
}

class _DashboardBackground extends StatelessWidget {
  const _DashboardBackground();

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
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: GuzoColors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
