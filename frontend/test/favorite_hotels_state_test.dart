import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guzo/state/favorite_hotels_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads and persists favorites independently for each user', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_hotels_traveler-1': ['hotel-1'],
    });
    final favorites = FavoriteHotelsState();

    await favorites.loadForUser('traveler-1');
    expect(favorites.hotelIds, {'hotel-1'});

    await favorites.toggle('traveler-1', 'hotel-2');
    expect(favorites.hotelIds, {'hotel-1', 'hotel-2'});

    await favorites.loadForUser('traveler-2');
    expect(favorites.hotelIds, isEmpty);

    await favorites.loadForUser('traveler-1');
    expect(favorites.hotelIds, {'hotel-1', 'hotel-2'});
  });

  test('removing a favorite persists the removal', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_hotels_traveler-1': ['hotel-1'],
    });
    final favorites = FavoriteHotelsState();

    await favorites.loadForUser('traveler-1');
    await favorites.toggle('traveler-1', 'hotel-1');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorite_hotels_traveler-1'), isEmpty);
    expect(favorites.contains('hotel-1'), isFalse);
  });
}
