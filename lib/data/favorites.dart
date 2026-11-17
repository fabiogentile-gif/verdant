import 'package:flutter/foundation.dart';
import 'package:verdant/data/storage.dart';

/// Favourite product ids, shared by the shop, product pages and homepage.
class Favorites extends ChangeNotifier {
  final Set<int> _ids = {};

  Set<int> get ids => Set.unmodifiable(_ids);
  bool contains(int productId) => _ids.contains(productId);

  void toggle(int productId) {
    if (!_ids.remove(productId)) _ids.add(productId);
    Storage.write(StorageKeys.favorites, _ids.toList());
    notifyListeners();
  }

  void restore() {
    final json = Storage.read(StorageKeys.favorites);
    if (json is! List) return;
    _ids
      ..clear()
      ..addAll(json.whereType<int>());
    notifyListeners();
  }

  void reset() {
    _ids.clear();
    notifyListeners();
  }
}

final favorites = Favorites();
