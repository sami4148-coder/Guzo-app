import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../state/water_store.dart';
import 'first_login_guide.dart';

const _waterBlue = Color(0xFF147D9B);
const _waterInk = Color(0xFF173344);
const _waterMuted = Color(0xFF6F8290);
const _waterCanvas = Color(0xFFF5F9FA);
const _waterCategories = ['All', 'Bottled', 'Refills', 'Premium', 'Bulk'];

final _etb =
    NumberFormat.currency(locale: 'en_ET', symbol: 'ETB ', decimalDigits: 0);

class WaterHomePage extends StatefulWidget {
  const WaterHomePage({super.key});

  @override
  State<WaterHomePage> createState() => _WaterHomePageState();
}

class _WaterHomePageState extends State<WaterHomePage> {
  bool _guideScheduled = false;
  bool _guideShown = false;

  @override
  Widget build(BuildContext context) {
    _maybeShowFirstLoginGuide();
    final store = context.watch<WaterStore>();
    final auth = context.watch<AuthState>();
    final featured = WaterProduct.products.take(4).toList();

    return _MarketScaffold(
      selected: 0,
      title: 'AquaMarket',
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DeliveryLocation(
                    area: store.deliveryArea,
                    onChanged: store.setDeliveryArea,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Good water.\nRight to your door.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: _waterInk,
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Find your everyday refresh, delivered simply.',
                    style: TextStyle(color: _waterMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  _SearchField(
                    onTap: () => context.go('/explore'),
                    hint: 'Search water, brands and sizes',
                  ),
                  const SizedBox(height: 20),
                  _HeroBanner(onShop: () => context.go('/explore')),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeading(
              title: 'Shop by type',
              action: 'See all',
              onAction: () => context.go('/explore'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 102,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _waterCategories.length - 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = _waterCategories[index + 1];
                  final icon = switch (category) {
                    'Bottled' => Icons.water_drop_outlined,
                    'Refills' => Icons.recycling_outlined,
                    'Premium' => Icons.auto_awesome_outlined,
                    _ => Icons.inventory_2_outlined,
                  };
                  return _CategoryTile(
                    title: category,
                    icon: icon,
                    onTap: () => context.go(
                      '/explore?category=${Uri.encodeComponent(category)}',
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionHeading(
              title: 'Popular right now',
              subtitle: 'Customer favourites, delivered fresh',
              action: 'View all',
              onAction: () => context.go('/explore'),
            ),
          ),
          _ProductGrid(products: featured),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: _ServicePromise(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: _waterBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auth.isLoggedIn
                          ? 'Welcome back, ${auth.user?.fullName ?? 'water lover'}'
                          : 'Easy ordering. Clear prices. No surprises.',
                      style: const TextStyle(color: _waterMuted, fontSize: 13),
                    ),
                  ),
                  if (!auth.isLoggedIn)
                    Wrap(
                      spacing: 4,
                      children: [
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Sign in'),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Create account'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
}

class WaterCatalogPage extends StatefulWidget {
  const WaterCatalogPage({
    super.key,
    this.initialCategory = 'All',
    this.initialQuery = '',
  });

  final String initialCategory;
  final String initialQuery;

  @override
  State<WaterCatalogPage> createState() => _WaterCatalogPageState();
}

class _WaterCatalogPageState extends State<WaterCatalogPage> {
  late final TextEditingController _search;
  late String _category;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery);
    _category = _waterCategories.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'All';
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final products = WaterProduct.products.where((product) {
      final matchesCategory =
          _category == 'All' || product.category == _category;
      final matchesQuery = query.isEmpty ||
          '${product.name} ${product.brand} ${product.size} ${product.category}'
              .toLowerCase()
              .contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return _MarketScaffold(
      selected: 1,
      title: 'Shop water',
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _SearchField(
                controller: _search,
                hint: 'Search water, brands and sizes',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _waterCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final category = _waterCategories[index];
                  return ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                    selectedColor: _waterBlue.withValues(alpha: 0.13),
                    labelStyle: TextStyle(
                      color: _category == category ? _waterBlue : _waterInk,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _category == category
                          ? _waterBlue.withValues(alpha: 0.25)
                          : const Color(0xFFE4ECEF),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                '${products.length} products',
                style: const TextStyle(color: _waterMuted, fontSize: 13),
              ),
            ),
          ),
          if (products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No water found',
                message: 'Try another search or choose a different category.',
              ),
            )
          else
            _ProductGrid(products: products),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class WaterProductPage extends StatelessWidget {
  const WaterProductPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final product = WaterProduct.find(productId);
    if (product == null) {
      return const _MarketScaffold(
        selected: 1,
        title: 'Product',
        child: _EmptyState(
          icon: Icons.water_drop_outlined,
          title: 'Product not found',
          message: 'This product may no longer be available.',
        ),
      );
    }

    final store = context.watch<WaterStore>();
    return _MarketScaffold(
      selected: 1,
      title: 'Product details',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _ProductArtwork(product: product, height: 300, large: true),
          const SizedBox(height: 20),
          if (product.badge != null)
            Align(
              alignment: Alignment.centerLeft,
              child: _Badge(text: product.badge!),
            ),
          const SizedBox(height: 10),
          Text(
            product.name,
            style: const TextStyle(
              color: _waterInk,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${product.brand}  ·  ${product.size}',
            style: const TextStyle(color: _waterMuted, fontSize: 15),
          ),
          const SizedBox(height: 14),
          Text(
            _etb.format(product.price),
            style: const TextStyle(
              color: _waterBlue,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product.description,
            style: const TextStyle(color: _waterMuted, height: 1.55),
          ),
          const SizedBox(height: 20),
          _ServicePromise(),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                store.add(product);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to your basket'),
                      action: SnackBarAction(
                        label: 'View basket',
                        onPressed: () => context.go('/cart'),
                      ),
                    ),
                  );
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('Add to basket  ·  ${_etb.format(product.price)}'),
            ),
          ),
        ],
      ),
    );
  }
}

class WaterCartPage extends StatelessWidget {
  const WaterCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WaterStore>();
    final lines = store.quantities.entries
        .map((entry) {
          final product = WaterProduct.find(entry.key);
          return product == null
              ? null
              : (product: product, quantity: entry.value);
        })
        .whereType<({WaterProduct product, int quantity})>()
        .toList();

    return _MarketScaffold(
      selected: 2,
      title: 'Your basket',
      child: lines.isEmpty
          ? const _EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Your basket is empty',
              message: 'Find your favourites and add them here.',
              actionLabel: 'Explore water',
              actionRoute: '/explore',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  '${store.itemCount} ${store.itemCount == 1 ? 'item' : 'items'}',
                  style: const TextStyle(color: _waterMuted),
                ),
                const SizedBox(height: 12),
                for (final line in lines)
                  _CartLine(
                    product: line.product,
                    quantity: line.quantity,
                    onAdd: () => store.add(line.product),
                    onRemove: () => store.removeOne(line.product),
                  ),
                const SizedBox(height: 12),
                _DeliveryLocation(
                  area: store.deliveryArea,
                  onChanged: store.setDeliveryArea,
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _PriceRow(
                            label: 'Subtotal',
                            value: _etb.format(store.subtotal)),
                        const SizedBox(height: 8),
                        const _PriceRow(
                          label: 'Delivery',
                          value: 'Calculated at checkout',
                        ),
                        const Divider(height: 24),
                        _PriceRow(
                          label: 'Total',
                          value: _etb.format(store.subtotal),
                          strong: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => _showCheckoutNotice(context),
                    child: const Text('Continue to checkout'),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sample storefront: checkout and delivery are not connected yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _waterMuted, fontSize: 12),
                ),
              ],
            ),
    );
  }

  void _showCheckoutNotice(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.local_shipping_outlined, color: _waterBlue),
        title: const Text('You’re nearly there'),
        content: const Text(
          'This marketplace preview has a sample catalogue and a working basket. '
          'Order placement and delivery need to be connected before you can buy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _MarketScaffold extends StatelessWidget {
  const _MarketScaffold({
    required this.selected,
    required this.title,
    required this.child,
  });

  final int selected;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final itemCount = context.watch<WaterStore>().itemCount;
    return Scaffold(
      backgroundColor: _waterCanvas,
      appBar: AppBar(
        backgroundColor: _waterCanvas,
        titleSpacing: 20,
        title: Row(
          children: [
            const Icon(Icons.water_drop_rounded, color: _waterBlue, size: 25),
            const SizedBox(width: 8),
            Text(
              selected == 0 ? 'AquaMarket' : title,
              style: const TextStyle(
                color: _waterInk,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Your basket',
            onPressed: () => context.go('/cart'),
            icon: Badge(
              isLabelVisible: itemCount > 0,
              label: Text('$itemCount'),
              child: const Icon(Icons.shopping_bag_outlined, color: _waterInk),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(top: false, child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/explore');
              break;
            case 2:
              context.go('/cart');
              break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: itemCount > 0,
              label: Text('$itemCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_bag_rounded),
            label: 'Basket',
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<WaterProduct> products;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = width >= 1000
              ? 4
              : width >= 680
                  ? 3
                  : 2;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: width < 380 ? 0.61 : 0.67,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ProductCard(product: products[index]),
              childCount: products.length,
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final WaterProduct product;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE8EFF1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/products/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ProductArtwork(product: product),
                  if (product.badge != null)
                    Positioned(
                      top: 9,
                      left: 9,
                      child: _Badge(text: product.badge!),
                    ),
                  Positioned(
                    right: 9,
                    bottom: 9,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.read<WaterStore>().add(product),
                        child: const Padding(
                          padding: EdgeInsets.all(9),
                          child: Icon(
                            Icons.add_shopping_cart,
                            size: 18,
                            color: _waterBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _waterMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _waterInk,
                      fontSize: 14,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.size,
                    style: const TextStyle(color: _waterMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _etb.format(product.price),
                    style: const TextStyle(
                      color: _waterBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductArtwork extends StatelessWidget {
  const _ProductArtwork({
    required this.product,
    this.height,
    this.large = false,
  });

  final WaterProduct product;
  final double? height;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final color = Color(product.color);
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.34),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -35,
            top: -38,
            child: Container(
              width: large ? 190 : 125,
              height: large ? 190 : 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.27),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -52,
            child: Container(
              width: large ? 155 : 100,
              height: large ? 155 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
          ),
          _WaterBottle(color: color, large: large),
        ],
      ),
    );
  }
}

class _WaterBottle extends StatelessWidget {
  const _WaterBottle({required this.color, required this.large});

  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scale = large ? 1.4 : 1.0;
    return SizedBox(
      width: 84 * scale,
      height: 142 * scale,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 27 * scale,
              height: 21 * scale,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.82),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(7 * scale),
                  bottom: Radius.circular(3 * scale),
                ),
              ),
            ),
          ),
          Positioned(
            top: 17 * scale,
            child: Container(
              width: 42 * scale,
              height: 15 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.68),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(8 * scale),
                ),
              ),
            ),
          ),
          Positioned(
            top: 27 * scale,
            child: Container(
              width: 70 * scale,
              height: 108 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(17 * scale),
                  topRight: Radius.circular(17 * scale),
                  bottomLeft: Radius.circular(21 * scale),
                  bottomRight: Radius.circular(21 * scale),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _waterInk.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 58 * scale,
                  height: 40 * scale,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                    size: 24 * scale,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 13 * scale,
            top: 42 * scale,
            child: Container(
              width: 5 * scale,
              height: 54 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(5 * scale),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryLocation extends StatelessWidget {
  const _DeliveryLocation({required this.area, required this.onChanged});

  final String area;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final controller = TextEditingController(text: area);
        final updated = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delivery area'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'City or neighbourhood',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        controller.dispose();
        if (updated != null) onChanged(updated);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_outlined, color: _waterBlue, size: 18),
          const SizedBox(width: 5),
          const Text('Delivering to ', style: TextStyle(color: _waterMuted)),
          Flexible(
            child: Text(
              area,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _waterInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 19, color: _waterInk),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField(
      {this.controller, required this.hint, this.onTap, this.onChanged});

  final TextEditingController? controller;
  final String hint;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: TextField(
        controller: controller,
        readOnly: onTap != null,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: _waterBlue),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFE5ECEF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFE5ECEF)),
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF126D88), Color(0xFF36A6B3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'STAY HYDRATED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your water,\nyour way.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Everyday bottles to home refills.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: onShop,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.65)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('Shop now'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.water_drop_rounded,
            color: Color(0xFFBCEBEE),
            size: 88,
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        width: 91,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8EFF1)),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _waterBlue, size: 25),
            const SizedBox(height: 7),
            Text(
              title,
              style: const TextStyle(
                color: _waterInk,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _waterInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: _waterMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _waterBlue,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ServicePromise extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: _waterBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Convenient delivery',
              style: TextStyle(
                color: _waterInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.verified_outlined, color: _waterBlue),
          SizedBox(width: 5),
          Text(
            'Quality picks',
            style: TextStyle(
              color: _waterInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final WaterProduct product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EFF1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 75,
              height: 82,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _ProductArtwork(product: product),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _waterInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${product.brand} · ${product.size}',
                    style: const TextStyle(color: _waterMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _etb.format(product.price * quantity),
                    style: const TextStyle(
                      color: _waterBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuantityButton(icon: Icons.remove, onPressed: onRemove),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _QuantityButton(icon: Icons.add, onPressed: onAdd),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5F6),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 17, color: _waterBlue),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: strong ? _waterInk : _waterMuted,
            fontWeight: strong ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: _waterInk,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionRoute,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final String? actionRoute;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _waterBlue, size: 56),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _waterInk,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _waterMuted, height: 1.4),
            ),
            if (actionLabel != null && actionRoute != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(actionRoute!),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
