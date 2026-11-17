import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:verdant/models/product.dart';

/// Data contract used by the UI; the source (API, mock, cache) stays hidden.
abstract class ProductRepository {
  Future<List<ProductSummary>> getProducts({String? category});
  Future<List<ProductSummary>> getFeaturedProducts();
  Future<ProductDetails> getProductDetails(int id);
}

/// Why loading products failed, with a message fit for the UI.
enum ProductErrorKind { offline, timeout, notFound, server, badData }

/// Thrown by [ApiProductRepository] when products cannot be loaded.
class ProductLoadException implements Exception {
  const ProductLoadException(this.kind, [this.detail]);

  final ProductErrorKind kind;
  final String? detail;

  String get message => switch (kind) {
    ProductErrorKind.offline =>
      'We can’t reach the greenhouse. Check your connection.',
    ProductErrorKind.timeout => 'The greenhouse is taking too long to answer.',
    ProductErrorKind.notFound => 'This product is no longer available.',
    ProductErrorKind.server => 'Something went wrong on our side.',
    ProductErrorKind.badData => 'We received something unexpected.',
  };

  @override
  String toString() => 'ProductLoadException($kind, $detail)';
}

/// Backend base URL: `--dart-define=API_ORIGIN` wins, otherwise a platform default.
String get apiOrigin {
  const fromEnv = String.fromEnvironment('API_ORIGIN');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000'; // localhost for emulator android
  }
  return 'http://localhost:3000';
}

/// Global instance; non-final so tests can swap in a fake.
ProductRepository productRepository = ApiProductRepository(origin: apiOrigin);

/// Makes relative image paths absolute ("/img/a.jpg" -> "$origin/img/a.jpg").
String resolveImage(String path, String origin) =>
    path.startsWith('http') ? path : '$origin$path';

/// Remote URL -> NetworkImage, otherwise a local asset.
ImageProvider imageFor(String src) =>
    src.startsWith('http') ? NetworkImage(src) : AssetImage(src);

/// Loads products from the Express backend, with a timeout and a short in-memory cache.
class ApiProductRepository implements ProductRepository {
  // The client is injectable (e.g. MockClient in tests).
  ApiProductRepository({
    required this.origin,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    this.cacheFor = const Duration(minutes: 5),
  }) : _client = client ?? http.Client();

  final String origin;
  final Duration timeout;
  final Duration cacheFor;
  final http.Client _client;
  final Map<String, (DateTime, Object)> _cache = {};

  String get _api => '$origin/api';

  /// Forgets cached responses (e.g. on pull-to-refresh).
  void clearCache() => _cache.clear();

  Future<T> _cached<T extends Object>(
    String key,
    Future<T> Function() load,
  ) async {
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.$1) < cacheFor) {
      return hit.$2 as T;
    }
    final value = await load();
    _cache[key] = (DateTime.now(), value);
    return value;
  }

  /// Throws [ProductLoadException], otherwise returns the `data` field of `{ "data": ... }`.
  Future<dynamic> _get(Uri uri) async {
    final http.Response r;
    try {
      r = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const ProductLoadException(ProductErrorKind.timeout);
    } on http.ClientException catch (e) {
      throw ProductLoadException(ProductErrorKind.offline, e.message);
    }
    if (r.statusCode == 404) {
      throw const ProductLoadException(ProductErrorKind.notFound);
    }
    if (r.statusCode != 200) {
      throw ProductLoadException(ProductErrorKind.server, '${r.statusCode}');
    }
    try {
      return (jsonDecode(r.body) as Map<String, dynamic>)['data'];
    } catch (e) {
      throw ProductLoadException(ProductErrorKind.badData, '$e');
    }
  }

  /// JSON list -> ProductSummary, with `image` resolved to an absolute URL.
  List<ProductSummary> _summaries(Object? list) {
    if (list is! List) {
      throw const ProductLoadException(ProductErrorKind.badData);
    }
    return list
        .cast<Map<String, dynamic>>()
        .map(
          (j) => ProductSummary.fromJson({
            ...j,
            'image': resolveImage(j['image'] as String, origin),
          }),
        )
        .toList();
  }

  @override
  Future<List<ProductSummary>> getProducts({String? category}) =>
      _cached('products:$category', () async {
        final uri = Uri.parse('$_api/products').replace(
          queryParameters: category == null ? null : {'category': category},
        );
        return _summaries(await _get(uri));
      });

  @override
  Future<List<ProductSummary>> getFeaturedProducts() => _cached(
    'featured',
    () async => _summaries(await _get(Uri.parse('$_api/featured'))),
  );

  @override
  Future<ProductDetails> getProductDetails(int id) =>
      _cached('product:$id', () async {
        final json = await _get(Uri.parse('$_api/products/$id'));
        if (json is! Map<String, dynamic>) {
          throw const ProductLoadException(ProductErrorKind.badData);
        }
        // Make the product's own images and the related products' images absolute.
        String abs(String p) => resolveImage(p, origin);
        return ProductDetails.fromJson({
          ...json,
          'images': (json['images'] as List? ?? const [])
              .map((i) => abs(i as String))
              .toList(),
          'related': (json['related'] as List? ?? const [])
              .cast<Map<String, dynamic>>()
              .map((r) => {...r, 'image': abs(r['image'] as String)})
              .toList(),
        });
      });
}
