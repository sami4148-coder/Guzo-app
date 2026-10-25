import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_state.dart';
import '../../state/favorite_hotels_state.dart';
import 'favorite_hotel_button.dart';

class HotelDetailsPage extends StatefulWidget {
  final String hotelId;
  const HotelDetailsPage({super.key, required this.hotelId});

  @override
  State<HotelDetailsPage> createState() => _HotelDetailsPageState();
}

class _HotelDetailsPageState extends State<HotelDetailsPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  int _selectedImage = 0;

  @override
  void initState() {
    super.initState();
    _load();
    unawaited(_loadFavorites());
  }

  Future<void> _loadFavorites() async {
    final user = context.read<AuthState>().user;
    if (user == null) return;
    try {
      await context.read<FavoriteHotelsState>().loadForUser(user.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load saved hotels: $error')),
      );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.get('/hotels/${widget.hotelId}');
      if (!mounted) return;
      setState(() => _data = Map<String, dynamic>.from(data as Map));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Material(
            color: Colors.white.withValues(alpha: 0.9),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.pop(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_rounded, size: 20),
              ),
            ),
          ),
        ),
        title: Text(
          _data == null
              ? 'Stay details'
              : hotelDisplayName(
                  _data!['name']?.toString() ?? 'Hotel',
                  _data!['city']?.toString() ?? '',
                ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _HotelBackground()),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: GuzoColors.green),
            )
          else if (_error != null)
            _errorView()
          else if (_data == null)
            _errorView(message: 'This stay could not be found.')
          else
            _details(_data!),
        ],
      ),
      bottomNavigationBar:
          const _HotelBottomBar(currentPath: '/hotels/details'),
    );
  }

  Widget _errorView({String? message}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: GuzoColors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  size: 34,
                  color: GuzoColors.green,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Stay details unavailable',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message ?? _error ?? 'Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GuzoColors.muted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(
                  backgroundColor: GuzoColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _details(Map<String, dynamic> hotel) {
    final images = ((hotel['images'] as List?) ?? const [])
        .map((image) => image is Map ? image['url']?.toString() : null)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
    final rooms = (hotel['roomTypes'] as List?) ?? const [];
    final amenities = (hotel['amenities'] as List?) ?? const [];
    final currency = NumberFormat.currency(
      locale: 'en_ET',
      symbol: 'ETB ',
      decimalDigits: 0,
    );
    final width = MediaQuery.sizeOf(context).width;
    final rating = (hotel['rating'] as num?)?.toDouble() ?? 0;
    final category = hotel['category']?.toString() ?? 'Stay';
    final city = hotel['city']?.toString() ?? '';
    final displayName = hotelDisplayName(
      hotel['name']?.toString() ?? 'Hotel',
      city,
    );
    final location = [
      hotel['address']?.toString(),
      hotel['city']?.toString(),
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                width >= 760 ? 30 : 16,
                8,
                width >= 760 ? 30 : 16,
                140,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _gallery(images, displayName),
                  const SizedBox(height: 24),
                  _overview(hotel, category, location, rating),
                  const SizedBox(height: 28),
                  _description(hotel['description']?.toString() ?? ''),
                  if (amenities.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _amenities(amenities),
                  ],
                  const SizedBox(height: 34),
                  _rooms(rooms, currency),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Gallery
  // ─────────────────────────────────────────────────────────────
  Widget _gallery(List<String> images, String name) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: isWide ? 400 : 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isEmpty)
              _imagePlaceholder()
            else
              PageView.builder(
                itemCount: images.length,
                onPageChanged: (index) =>
                    setState(() => _selectedImage = index),
                itemBuilder: (context, index) => Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(
                          color: const Color(0xFFE7EFED),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: GuzoColors.green,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                ),
              ),
            // Gradient overlay
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.45),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
            // Top-left verification badge
            Positioned(
              left: 16,
              top: 16,
              child: _glassChip(
                icon: Icons.verified_rounded,
                label: 'A great local stay',
              ),
            ),
            // Top-right favourite
            Positioned(
              right: 16,
              top: 16,
              child: FavoriteHotelButton(
                hotelId: widget.hotelId,
                size: 40,
                iconSize: 19,
              ),
            ),
            // Photo counter
            if (images.isNotEmpty)
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_selectedImage + 1} / ${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Thumbnail strip
            if (images.length > 1)
              Positioned(
                left: 16,
                bottom: 16,
                child: Row(
                  children: [
                    for (int i = 0;
                        i < (images.length > 5 ? 5 : images.length);
                        i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _selectedImage ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _selectedImage
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            // Fallback name overlay
            if (images.isEmpty)
              Positioned(
                left: 18,
                bottom: 18,
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _glassChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GuzoColors.green),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Overview
  // ─────────────────────────────────────────────────────────────
  Widget _overview(
    Map<String, dynamic> hotel,
    String category,
    String location,
    double rating,
  ) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    final currency = NumberFormat.currency(
      locale: 'en_ET',
      symbol: 'ETB ',
      decimalDigits: 0,
    );
    final roomCount = ((hotel['roomTypes'] as List?) ?? const []).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pills row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: GuzoColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_offer_rounded,
                    size: 12,
                    color: GuzoColors.green,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _titleCase(category).toUpperCase(),
                    style: const TextStyle(
                      color: GuzoColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            if (rating > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFD49B25),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        color: GuzoColors.ink,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'rating',
                      style: TextStyle(
                        color: Color(0xFF8B6F1F),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Title
        Text(
          hotelDisplayName(
            hotel['name']?.toString() ?? 'Hotel',
            hotel['city']?.toString() ?? '',
          ),
          style: TextStyle(
            fontSize: isWide ? 34 : 27,
            height: 1.1,
            letterSpacing: -0.9,
            fontWeight: FontWeight.w900,
            color: GuzoColors.ink,
          ),
        ),

        // Location
        if (location.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: GuzoColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: GuzoColors.green,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    color: GuzoColors.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 18),

        // Overview badges
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _overviewBadge(
              Icons.payments_outlined,
              'From ${currency.format((hotel['basePrice'] as num?)?.toInt() ?? 0)} / night',
            ),
            _overviewBadge(
              Icons.bed_outlined,
              '$roomCount room options',
            ),
          ],
        ),
      ],
    );
  }

  Widget _overviewBadge(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6ECEB)),
          boxShadow: [
            BoxShadow(
              color: GuzoColors.ink.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: GuzoColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: GuzoColors.green),
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: GuzoColors.ink,
              ),
            ),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────────
  // Description
  // ─────────────────────────────────────────────────────────────
  Widget _description(String description) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            eyebrow: 'ABOUT THIS STAY',
            title: 'A little more about the place',
          ),
          const SizedBox(height: 12),
          Text(
            description.isEmpty
                ? 'A welcoming place to settle in and explore the area.'
                : description,
            style: const TextStyle(
              color: Color(0xFF52646B),
              fontSize: 13.5,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Amenities
  // ─────────────────────────────────────────────────────────────
  Widget _amenities(List amenities) {
    final names = amenities
        .map((item) {
          if (item is! Map) return '';
          final amenity = item['amenity'];
          return (amenity is Map ? amenity['name'] : item['name'])
                  ?.toString() ??
              '';
        })
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          eyebrow: 'MAKE YOURSELF AT HOME',
          title: 'Popular amenities',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
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
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final name in names)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _amenityIcon(name),
                        size: 15,
                        color: GuzoColors.green,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: GuzoColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Rooms
  // ─────────────────────────────────────────────────────────────
  Widget _rooms(List rooms, NumberFormat currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          eyebrow: 'AVAILABLE ROOMS',
          title: 'Choose your room',
        ),
        const SizedBox(height: 14),
        if (rooms.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE6ECEB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: GuzoColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_busy_outlined,
                    size: 20,
                    color: GuzoColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'There are no rooms available to book right now.',
                    style: TextStyle(
                      color: GuzoColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...rooms.map((room) {
            final data = room is Map ? room : const <String, dynamic>{};
            final name = data['name']?.toString() ?? 'Room';
            final guests = data['maxGuests'] ?? 2;
            final price = (data['pricePerNight'] as num?)?.toInt() ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 470;

                  // Left icon badge
                  final iconBadge = Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          GuzoColors.green,
                          GuzoColors.green.withValues(alpha: 0.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: GuzoColors.green.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bed_outlined,
                      size: 24,
                      color: Colors.white,
                    ),
                  );

                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.3,
                          color: GuzoColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people_outline_rounded,
                                  size: 13,
                                  color: GuzoColors.muted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Up to $guests guests',
                                  style: const TextStyle(
                                    color: GuzoColors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currency.format(price),
                            style: const TextStyle(
                              color: GuzoColors.green,
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 5, bottom: 3),
                            child: Text(
                              'per night',
                              style: TextStyle(
                                color: GuzoColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );

                  final button = FilledButton.icon(
                    onPressed: data['id'] == null
                        ? null
                        : () => context.push('/book/${data['id']}'),
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                    ),
                    label: const Text('Reserve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: GuzoColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: Size(compact ? double.infinity : 130, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            iconBadge,
                            const SizedBox(width: 14),
                            Expanded(child: details),
                          ],
                        ),
                        const SizedBox(height: 16),
                        button,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      iconBadge,
                      const SizedBox(width: 16),
                      Expanded(child: details),
                      const SizedBox(width: 18),
                      button,
                    ],
                  );
                },
              ),
            );
          }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Section heading
  // ─────────────────────────────────────────────────────────────
  Widget _sectionHeading({
    required String eyebrow,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
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
                eyebrow,
                style: const TextStyle(
                  color: GuzoColors.green,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: GuzoColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
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
          child: Icon(
            Icons.hotel_rounded,
            size: 64,
            color: Color(0xFF9BAEAA),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
String _titleCase(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

IconData _amenityIcon(String name) {
  final value = name.toLowerCase();
  if (value.contains('wifi')) return Icons.wifi_rounded;
  if (value.contains('pool')) return Icons.pool_rounded;
  if (value.contains('parking')) return Icons.local_parking_rounded;
  if (value.contains('restaurant') || value.contains('breakfast')) {
    return Icons.restaurant_rounded;
  }
  if (value.contains('air') || value.contains('climate')) {
    return Icons.ac_unit_rounded;
  }
  if (value.contains('bar')) return Icons.local_bar_rounded;
  return Icons.check_circle_outline_rounded;
}

// ─────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────
class _HotelBackground extends StatelessWidget {
  const _HotelBackground();

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
// Floating glassy bottom bar
// ─────────────────────────────────────────────────────────────
class _HotelBottomBar extends StatelessWidget {
  final String currentPath;
  const _HotelBottomBar({required this.currentPath});

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
                  icon: Icons.person_outline_rounded,
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
