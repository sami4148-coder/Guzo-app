import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteHotelsState extends ChangeNotifier {
  String? _userId;
  Set<String> _hotelIds = {};
  final Set<String> _savingHotelIds = {};
  bool _loading = false;
  bool _loaded = false;

  Set<String> get hotelIds => Set.unmodifiable(_hotelIds);
  bool get loading => _loading;
  bool contains(String hotelId) => _hotelIds.contains(hotelId);
  bool isSaving(String hotelId) => _savingHotelIds.contains(hotelId);

  Future<void> loadForUser(String userId) async {
    if (_userId == userId && (_loading || _loaded)) return;

    _userId = userId;
    _hotelIds = {};
    _loading = true;
    _loaded = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList(_preferenceKey(userId)) ?? [];
      if (_userId != userId) return;
      _hotelIds = savedIds.toSet();
      _loaded = true;
    } finally {
      if (_userId == userId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggle(String userId, String hotelId) async {
    if (_userId != userId || !_loaded) {
      await loadForUser(userId);
    }
    if (!_loaded || _userId != userId || !_savingHotelIds.add(hotelId)) return;

    final wasFavorite = _hotelIds.contains(hotelId);
    if (wasFavorite) {
      _hotelIds.remove(hotelId);
    } else {
      _hotelIds.add(hotelId);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setStringList(
        _preferenceKey(userId),
        _hotelIds.toList(),
      );
      if (!saved) throw StateError('Unable to save favorite hotels.');
    } catch (_) {
      if (wasFavorite) {
        _hotelIds.add(hotelId);
      } else {
        _hotelIds.remove(hotelId);
      }
      notifyListeners();
      rethrow;
    } finally {
      _savingHotelIds.remove(hotelId);
      notifyListeners();
    }
  }

  String _preferenceKey(String userId) => 'favorite_hotels_$userId';
}
