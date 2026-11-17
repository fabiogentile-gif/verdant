import 'package:flutter/foundation.dart';
import 'package:verdant/models/product.dart';

/// A Greenhouse category chip, matched on the client against the catalogue.
class ShopCategory {
  const ShopCategory(this.label, this.matches);

  final String label;
  final bool Function(ProductSummary p) matches;

  static bool _hasTag(ProductSummary p, String tag) =>
      p.tags.any((t) => t.toLowerCase() == tag.toLowerCase());

  static bool _mentions(ProductSummary p, List<String> words) {
    final text = [p.name, ...p.tags].join(' ').toLowerCase();
    return words.any(text.contains);
  }

  static final all = ShopCategory('All', (_) => true);
  static final indoorPlants = ShopCategory(
    'Indoor Plants',
    (p) => p.category == 'plants' && !_hasTag(p, 'Outdoor'),
  );
  static final outdoorPlants = ShopCategory(
    'Outdoor Plants',
    (p) => p.category == 'plants' && _hasTag(p, 'Outdoor'),
  );
  static final pots = ShopCategory('Pots', (p) => p.category == 'planters');
  static final soil = ShopCategory(
    'Soil',
    (p) => _mentions(p, ['soil', 'potting mix']),
  );
  static final fertilizers = ShopCategory(
    'Fertilizers',
    (p) => _mentions(p, ['fertili', 'plant food', 'feed']),
  );
  static final accessories = ShopCategory(
    'Accessories',
    (p) =>
        p.category == 'accessories' && !_mentions(p, ['soil', 'potting mix']),
  );

  static final values = [
    all,
    indoorPlants,
    outdoorPlants,
    pots,
    soil,
    fertilizers,
    accessories,
  ];
}

/// Sort orders offered in the Greenhouse.
enum ShopSort {
  featured('Featured'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  rating('Top rated'),
  name('Name: A to Z');

  const ShopSort(this.label);
  final String label;
}

/// Search, category, sort and filter state of the Greenhouse.
/// Other pages (homepage search, category chips, product tags) set it and
/// then switch to the Greenhouse tab.
class ShopFilter extends ChangeNotifier {
  String _query = '';
  ShopCategory _category = ShopCategory.all;
  ShopSort _sort = ShopSort.featured;
  bool _inStockOnly = false;
  bool _favoritesOnly = false;

  String get query => _query;
  ShopCategory get category => _category;
  ShopSort get sort => _sort;
  bool get inStockOnly => _inStockOnly;
  bool get favoritesOnly => _favoritesOnly;

  /// True when anything narrows the default list.
  bool get isActive =>
      _query.trim().isNotEmpty ||
      _category != ShopCategory.all ||
      _inStockOnly ||
      _favoritesOnly;

  int get extraFilterCount => (_inStockOnly ? 1 : 0) + (_favoritesOnly ? 1 : 0);

  set query(String v) => _set(() => _query = v);
  set category(ShopCategory v) => _set(() => _category = v);
  set sort(ShopSort v) => _set(() => _sort = v);
  set inStockOnly(bool v) => _set(() => _inStockOnly = v);
  set favoritesOnly(bool v) => _set(() => _favoritesOnly = v);

  /// Opens the shop on a clean state with an optional search or category.
  void show({String query = '', ShopCategory? category}) => _set(() {
    _query = query;
    _category = category ?? ShopCategory.all;
  });

  void clear() => _set(() {
    _query = '';
    _category = ShopCategory.all;
    _inStockOnly = false;
    _favoritesOnly = false;
  });

  List<ProductSummary> apply(
    List<ProductSummary> products, {
    required Set<int> favoriteIds,
  }) {
    final q = _query.trim().toLowerCase();
    final result = products.where((p) {
      if (!_category.matches(p)) return false;
      if (_inStockOnly && !p.inStock) return false;
      if (_favoritesOnly && !favoriteIds.contains(p.id)) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          (p.tag?.toLowerCase().contains(q) ?? false) ||
          p.tags.any((t) => t.toLowerCase().contains(q)) ||
          (p.category?.toLowerCase().contains(q) ?? false);
    }).toList();

    int byName(ProductSummary a, ProductSummary b) => a.name.compareTo(b.name);
    switch (_sort) {
      case ShopSort.featured:
        // Stable: featured first, catalogue order otherwise.
        final featured = result.where((p) => p.featured).toList();
        final rest = result.where((p) => !p.featured).toList();
        return [...featured, ...rest];
      case ShopSort.priceLow:
        result.sort((a, b) => a.price.compareTo(b.price));
      case ShopSort.priceHigh:
        result.sort((a, b) => b.price.compareTo(a.price));
      case ShopSort.rating:
        result.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      case ShopSort.name:
        result.sort(byName);
    }
    return result;
  }

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }
}

/// Greenhouse search and filter state shared by every page.
final shopFilter = ShopFilter();
