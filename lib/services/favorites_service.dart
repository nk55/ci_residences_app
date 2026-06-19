import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorites';

  static Future<bool> isFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];
    return favorites.contains(id);
  }

  static Future<bool> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];

    if (favorites.contains(id)) {
      favorites.remove(id);
      await prefs.setStringList(_key, favorites);
      return false;
    } else {
      favorites.add(id);
      await prefs.setStringList(_key, favorites);
      return true;
    }
  }

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}