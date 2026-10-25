import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/auth_state.dart';
import 'owner_hotel_posts.dart';

class ExplorePage extends StatefulWidget {
  final Map<String, String> initial;
  const ExplorePage({super.key, this.initial = const {}});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _city = TextEditingController();
  String? _category;
  RangeValues _price = const RangeValues(0, 20000);
  double _minRating = 0;
  String _sort = 'popularity';
  int? _guests;
  List<Hotel> _hotels = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _city.text = widget.initial['city'] ?? '';
    _city.addListener(() => setState(() {}));
    _guests = int.tryParse(widget.initial['guests'] ?? '');
    final category = widget.initial['category'];
    if (category != null &&
        const {'luxury', 'budget', 'resort', 'guesthouse'}.contains(category)) {
      _category = category;
    }
    _load();
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    setState(() {
      if (showLoading) _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.getList(
        '/hotels',
        query: {
          'sort': _sort,
          'minPrice': _price.start.round().toString(),
          'maxPrice': _price.end.round().toString(),
          if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
          if (_category != null) 'category': _category!,
          if (_minRating > 0) 'minRating': _minRating.toString(),
          if (_guests != null) 'guests': _guests.toString(),
        },
      );
      if (!mounted) return;
      setState(() {
        _hotels = data.map((item) => Hotel.fromJson(item)).toList();
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted && showLoading) setState(() => _loading = false);
    }
  }

  void _resetFilters() {
    setState(() {
      _city.clear();
      _category = null;
      _price = const RangeValues(0, 20000);
      _minRating = 0;
      _guests = null;
      _sort = 'popularity';
    });
    _load();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_category != null) count++;
    if (_price.start > 0 || _price.end < 20000) count++;
    if (_minRating > 0) count++;
    if (_guests != null) count++;
    if (_sort != 'popularity') count++;
    return count;
  }

  Future<void> _showFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _FilterSheet(
        price: _price,
        minRating: _minRating,
        sort: _sort,
        guests: _guests,
        category: _category,
        onCategoryChanged: (c) => setState(() => _category = c),
        onPriceChanged: (p) => setState(() => _price = p),
        onRatingChanged: (r) => setState(() => _minRating = r),
        onSortChanged: (s) => setState(() => _sort = s),
        onGuestsChanged: (g) => setState(() => _guests = g),
        onApply: () {
          Navigator.pop(sheetContext);
          _load();
        },
        onReset: () {
          _resetFilters();
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 940;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      extendBody: true,
       appBar: PreferredSize(
         preferredSize: const Size.fromHeight(96),
         child: SafeArea(
           bottom: false,
           child: Padding(
             padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(26),
               child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                       colors: [
                         Colors.white.withValues(alpha: 0.86),
                         GuzoColors.cream.withValues(alpha: 0.78),
                       ],
                     ),
                     borderRadius: BorderRadius.circular(26),
                     border: Border.all(color: Colors.white.withValues(alpha: 0.95), width: 1.2),
                     boxShadow: [
                       BoxShadow(color: GuzoColors.ink.withValues(alpha: 0.10), blurRadius: 30, offset: const Offset(0, 12)),
                       BoxShadow(color: GuzoColors.green.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6)),
                     ],
                   ),
                   child: Row(
                     children: [
                       _ExploreAppBarButton(icon: Icons.arrow_back_rounded, onTap: () => context.go('/')),
                       const SizedBox(width: 12),
                       Container(
                         width: 40,
                         height: 40,
                         decoration: BoxDecoration(
                           gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [GuzoColors.green, GuzoColors.gold]),
                           borderRadius: BorderRadius.circular(14),
                           boxShadow: [BoxShadow(color: GuzoColors.green.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                         ),
                         child: const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 20),
                       ),
                       const SizedBox(width: 12),
                       const Expanded(
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text('Explore stays', style: TextStyle(color: GuzoColors.ink, fontWeight: FontWeight.w900, letterSpacing: -0.6, fontSize: 19, height: 1.05)),
                             SizedBox(height: 2),
                             Text('Find your perfect getaway', style: TextStyle(color: GuzoColors.muted, fontWeight: FontWeight.w600, fontSize: 12)),
                           ],
                         ),
                       ),
                       if (!wide) _FilterButton(activeCount: _activeFilterCount, onTap: _showFilters),
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
          const Positioned.fill(child: _ExploreBackground()),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                SizedBox(
                  width: 300,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 0, 96),
                    child: _DesktopFilterPanel(
                      price: _price,
                      minRating: _minRating,
                      sort: _sort,
                      guests: _guests,
                      category: _category,
                      city: _city,
                      onCategoryChanged: (c) => setState(() => _category = c),
                      onPriceChanged: (p) => setState(() => _price = p),
                      onRatingChanged: (r) => setState(() => _minRating = r),
                      onSortChanged: (s) => setState(() => _sort = s),
                      onGuestsChanged: (g) => setState(() => _guests = g),
                      onApply: _load,
                      onReset: _resetFilters,
                    ),
                  ),
                ),
              Expanded(child: _results(wide)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const _ExploreBottomBar(currentPath: '/explore'),
    );
  }

  Widget _results(bool wide) {
    final hPad = wide ? 28.0 : 18.0;
    final isApprovedOwner = context.watch<AuthState>().isOwner;

    return RefreshIndicator(
      onRefresh: () => _load(showLoading: false),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 22),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _intro(wide),
                if (isApprovedOwner) ...[
                  const SizedBox(height: 18),
                  OwnerHotelPosts(onChanged: _load),
                ],
                if (!wide) ...[
                  const SizedBox(height: 18),
                  _mobileSearch(),
                  const SizedBox(height: 14),
                  _categoryStrip(),
                ],
                const SizedBox(height: 22),
                _resultsHeading(),
                const SizedBox(height: 14),
              ]),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: GuzoColors.green),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _statusMessage(
                icon: Icons.cloud_off_rounded,
                title: 'We couldn\'t load stays',
                message: _error!,
                action: TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ),
            )
          else if (_hotels.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _statusMessage(
                icon: Icons.travel_explore_rounded,
                title: 'No stays found',
                message: 'Try a different destination or loosen your filters.',
                action: TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Clear all filters'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 365,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 0.86,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _StayCard(hotel: _hotels[index]),
                  childCount: _hotels.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Hero intro
  // ─────────────────────────────────────────────────────────────
  Widget _intro(bool wide) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: GuzoColors.ink.withValues(alpha: 0.22), blurRadius: 36, offset: const Offset(0, 18)),
          BoxShadow(color: GuzoColors.green.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1400&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B5260), Color(0xFF16849A), Color(0xFF43B8AE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF061B2E).withValues(alpha: 0.88),
                      const Color(0xFF0B2545).withValues(alpha: 0.55),
                      const Color(0xFF147D9B).withValues(alpha: 0.25),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.25)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(wide ? 34 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.travel_explore_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 6),
                        Text('DISCOVER ETHIOPIA', style: TextStyle(color: Colors.white, fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Find a place\nthat feels like yours.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: wide ? 34 : 28,
                      height: 1.08,
                      letterSpacing: -1.0,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'From highland hideaways to city escapes.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: const [
                      _HeroPill(icon: Icons.verified_rounded, label: 'Verified stays'),
                      _HeroPill(icon: Icons.star_rounded, label: 'Top rated'),
                      _HeroPill(icon: Icons.payments_rounded, label: 'Best prices'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _mobileSearch() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEEC)),
      ),
      child: TextField(
        controller: _city,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _load(),
        decoration: const InputDecoration(
          hintText: 'Search city or hotel',
          prefixIcon: Icon(Icons.search_rounded),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _categoryStrip() {
    const categories = ['luxury', 'budget', 'resort', 'guesthouse'];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final selected = _category == null;
            return ChoiceChip(
              label: const Text('All'),
              selected: selected,
              onSelected: (_) {
                setState(() => _category = null);
                _load();
              },
            );
          }
          final cat = categories[index - 1];
          final selected = _category == cat;
          return ChoiceChip(
            label: Text(_titleCase(cat)),
            avatar: Icon(_categoryIcon(cat), size: 16),
            selected: selected,
            onSelected: (_) {
              setState(() => _category = selected ? null : cat);
              _load();
            },
          );
        },
      ),
    );
  }

  Widget _resultsHeading() {
    return Row(
      children: [
        Text(
          '${_hotels.length} stay${_hotels.length == 1 ? '' : 's'} found',
          style: const TextStyle(
            color: GuzoColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _statusMessage({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: GuzoColors.muted),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: GuzoColors.ink)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: GuzoColors.muted)),
            if (action != null) ...[const SizedBox(height: 12), action],
          ],
        ),
      ),
    );
  }
}

class _ExploreAppBarButton extends StatelessWidget {
  const _ExploreAppBarButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: GuzoColors.ink),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: GuzoColors.green.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: GuzoColors.green,
              ),
            ),
          ),
        ),
        if (activeCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: GuzoColors.green,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '$activeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────// Stay card
// ─────────────────────────────────────────────────────────────
class _StayCard extends StatelessWidget {
  const _StayCard({required this.hotel});

  final Hotel hotel;

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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEEC)),
        boxShadow: [
          BoxShadow(
            color: GuzoColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => context.push('/hotels/${hotel.id}'),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _HotelImage(url: hotel.coverImage),
                      // Bottom fade
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.22),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Text(
                            _titleCase(hotel.category.isEmpty
                                ? 'Featured'
                                : hotel.category),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFD49B25),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                hotel.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
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
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 12, 15, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotelDisplayName(hotel.name, hotel.city),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
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
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currency.format(hotel.basePrice),
                            style: const TextStyle(
                              color: GuzoColors.green,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 2),
                            child: Text(
                              '/ night',
                              style: TextStyle(
                                color: GuzoColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: GuzoColors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: GuzoColors.green,
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
    );
  }
}

class _HotelImage extends StatelessWidget {
  const _HotelImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _placeholder();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Container(
              color: const Color(0xFFE7EFED),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GuzoColors.green,
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
            colors: [Color(0xFFE7EFED), Color(0xFFD8E5E2)],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.hotel_rounded,
            size: 46,
            color: Color(0xFF9BAEAA),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────
class _ExploreBackground extends StatelessWidget {
  const _ExploreBackground();

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
              color: GuzoColors.green.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: -60,
            right: -90,
            child: _Blob(
              size: 200,
              color: const Color(0xFF4FB3A3).withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: _Blob(
              size: 280,
              color: GuzoColors.green.withValues(alpha: 0.12),
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
class _ExploreBottomBar extends StatelessWidget {
  final String currentPath;
  const _ExploreBottomBar({required this.currentPath});

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
                  icon: Icons.explore_rounded,
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

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
String _titleCase(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

IconData _categoryIcon(String category) => switch (category) {
      'luxury' => Icons.diamond_outlined,
      'resort' => Icons.pool_outlined,
      'budget' => Icons.savings_outlined,
      _ => Icons.home_work_outlined,
    };

Color _categoryColor(String category) => switch (category) {
      'luxury' => const Color(0xFF8E6BBF),
      'resort' => const Color(0xFF2E86AB),
      'budget' => const Color(0xFFD49B25),
      _ => const Color(0xFFC05746),
    };

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.price,
    required this.minRating,
    required this.sort,
    required this.guests,
    required this.category,
    required this.onCategoryChanged,
    required this.onPriceChanged,
    required this.onRatingChanged,
    required this.onSortChanged,
    required this.onGuestsChanged,
    required this.onApply,
    required this.onReset,
  });

  final RangeValues price;
  final double minRating;
  final String sort;
  final int? guests;
  final String? category;
  final ValueChanged<int?> onGuestsChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<RangeValues> onPriceChanged;
  final ValueChanged<double> onRatingChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE5E2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: GuzoColors.ink)),
              const SizedBox(height: 16),
              _filterBody(
                context: context,
                price: price,
                minRating: minRating,
                sort: sort,
                guests: guests,
                category: category,
                cityController: null,
                onCategoryChanged: onCategoryChanged,
                onPriceChanged: onPriceChanged,
                onRatingChanged: onRatingChanged,
                onSortChanged: onSortChanged,
                onGuestsChanged: onGuestsChanged,
                onCityChanged: (_) {},
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApply,
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopFilterPanel extends StatelessWidget {
  const _DesktopFilterPanel({
    required this.price,
    required this.minRating,
    required this.sort,
    required this.guests,
    required this.category,
    required this.city,
    required this.onCategoryChanged,
    required this.onPriceChanged,
    required this.onRatingChanged,
    required this.onSortChanged,
    required this.onGuestsChanged,
    required this.onApply,
    required this.onReset,
  });

  final RangeValues price;
  final double minRating;
  final String sort;
  final int? guests;
  final String? category;
  final ValueChanged<int?> onGuestsChanged;
  final TextEditingController city;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<RangeValues> onPriceChanged;
  final ValueChanged<double> onRatingChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEEC)),
        boxShadow: [
          BoxShadow(color: GuzoColors.ink.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: GuzoColors.ink)),
            const SizedBox(height: 14),
            _filterBody(
              context: context,
              price: price,
              minRating: minRating,
              sort: sort,
              guests: guests,
              category: category,
              cityController: city,
              onCategoryChanged: onCategoryChanged,
              onPriceChanged: onPriceChanged,
              onRatingChanged: onRatingChanged,
              onSortChanged: onSortChanged,
              onGuestsChanged: onGuestsChanged,
              onCityChanged: (_) {},
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: onReset, child: const Text('Reset'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: onApply, child: const Text('Apply'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _filterBody({
  required BuildContext context,
  required RangeValues price,
  required double minRating,
  required String sort,
  required int? guests,
  required String? category,
  required TextEditingController? cityController,
  required ValueChanged<String?> onCategoryChanged,
  required ValueChanged<RangeValues> onPriceChanged,
  required ValueChanged<double> onRatingChanged,
  required ValueChanged<String> onSortChanged,
  required ValueChanged<int?> onGuestsChanged,
  required ValueChanged<String> onCityChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (cityController != null) ...[
        TextField(
          controller: cityController,
          decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_rounded)),
          onChanged: onCityChanged,
        ),
        const SizedBox(height: 12),
      ],
      const Text('Category', style: TextStyle(fontWeight: FontWeight.w700, color: GuzoColors.ink)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: category == null,
            onSelected: (_) => onCategoryChanged(null),
          ),
          for (final c in const ['luxury', 'budget', 'resort', 'guesthouse'])
            FilterChip(
              label: Text(_titleCase(c)),
              avatar: Icon(_categoryIcon(c), size: 16),
              selected: category == c,
              onSelected: (_) => onCategoryChanged(category == c ? null : c),
            ),
        ],
      ),
      const SizedBox(height: 14),
      Text('Price: ETB ${price.start.round()} - ${price.end.round()}', style: const TextStyle(fontWeight: FontWeight.w700, color: GuzoColors.ink)),
      RangeSlider(
        min: 0,
        max: 20000,
        divisions: 40,
        values: price,
        onChanged: onPriceChanged,
      ),
      const SizedBox(height: 8),
      Text('Min rating: ${minRating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w700, color: GuzoColors.ink)),
      Slider(
        min: 0,
        max: 5,
        divisions: 10,
        value: minRating,
        onChanged: onRatingChanged,
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: sort,
        decoration: const InputDecoration(labelText: 'Sort by'),
        items: const [
          DropdownMenuItem(value: 'popularity', child: Text('Popularity')),
          DropdownMenuItem(value: 'price_low', child: Text('Price: low to high')),
          DropdownMenuItem(value: 'price_high', child: Text('Price: high to low')),
          DropdownMenuItem(value: 'rating', child: Text('Rating')),
        ],
        onChanged: (v) => onSortChanged(v ?? 'popularity'),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int?>(
        initialValue: guests,
        decoration: const InputDecoration(labelText: 'Guests'),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('Any')),
          for (int i = 1; i <= 8; i++) DropdownMenuItem<int?>(value: i, child: Text('$i')),
        ],
        onChanged: onGuestsChanged,
      ),
    ],
  );
}
