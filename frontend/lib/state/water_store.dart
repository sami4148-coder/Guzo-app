import 'package:flutter/foundation.dart';

class WaterProduct {
  const WaterProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.size,
    required this.price,
    required this.category,
    required this.description,
    required this.color,
    this.badge,
  });

  final String id;
  final String name;
  final String brand;
  final String size;
  final int price;
  final String category;
  final String description;
  final int color;
  final String? badge;

  static const products = [
    WaterProduct(
      id: 'source-spring',
      name: 'Natural Spring Water',
      brand: 'Blue Nile',
      size: '12 × 1 L',
      price: 420,
      category: 'Bottled',
      description:
          'Crisp, naturally filtered spring water for the whole family. A convenient case for home, work, and everything in between.',
      color: 0xFF5BBAE8,
      badge: 'BEST SELLER',
    ),
    WaterProduct(
      id: 'daily-purified',
      name: 'Purified Drinking Water',
      brand: 'Aqua Pure',
      size: '12 × 500 ml',
      price: 240,
      category: 'Bottled',
      description:
          'Light, refreshing purified water in easy-to-carry bottles. Keep a case ready for busy days and outings.',
      color: 0xFF43B8AE,
      badge: 'GREAT VALUE',
    ),
    WaterProduct(
      id: 'family-refill',
      name: 'Family Water Refill',
      brand: 'Highland',
      size: '20 L refill',
      price: 160,
      category: 'Refills',
      description:
          'A fresh 20-litre refill for your home dispenser. Choose a refill when you have a reusable returnable bottle.',
      color: 0xFF70A8E8,
      badge: 'ECO PICK',
    ),
    WaterProduct(
      id: 'glass-sparkling',
      name: 'Sparkling Mineral Water',
      brand: 'Misty',
      size: '6 × 750 ml',
      price: 540,
      category: 'Premium',
      description:
          'Bright bubbles and a clean mineral finish, served in elegant glass bottles for special meals and moments.',
      color: 0xFF8C85DB,
    ),
    WaterProduct(
      id: 'office-case',
      name: 'Office Hydration Case',
      brand: 'Blue Nile',
      size: '24 × 500 ml',
      price: 450,
      category: 'Bulk',
      description:
          'A convenient bulk case of refreshing water, sized for team meetings, shared spaces, and office kitchens.',
      color: 0xFF4C9CD4,
      badge: 'BULK SAVINGS',
    ),
    WaterProduct(
      id: 'kids-minis',
      name: 'Little Sips',
      brand: 'Aqua Pure',
      size: '12 × 330 ml',
      price: 210,
      category: 'Bottled',
      description:
          'Small, easy-to-pack bottles for lunchboxes, school bags, and family days out.',
      color: 0xFFF0A967,
    ),
  ];

  static WaterProduct? find(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }
}

class WaterStore extends ChangeNotifier {
  final Map<String, int> _quantities = {};
  String deliveryArea = 'Addis Ababa';

  Map<String, int> get quantities => Map.unmodifiable(_quantities);
  int get itemCount => _quantities.values.fold(0, (sum, quantity) => sum + quantity);
  int get subtotal => _quantities.entries.fold(0, (sum, entry) {
        final product = WaterProduct.find(entry.key);
        return sum + (product?.price ?? 0) * entry.value;
      });

  void add(WaterProduct product) {
    _quantities.update(product.id, (quantity) => quantity + 1, ifAbsent: () => 1);
    notifyListeners();
  }

  void removeOne(WaterProduct product) {
    final quantity = _quantities[product.id];
    if (quantity == null) return;
    if (quantity <= 1) {
      _quantities.remove(product.id);
    } else {
      _quantities[product.id] = quantity - 1;
    }
    notifyListeners();
  }

  void setDeliveryArea(String area) {
    final normalized = area.trim();
    if (normalized.isEmpty || normalized == deliveryArea) return;
    deliveryArea = normalized;
    notifyListeners();
  }
}
