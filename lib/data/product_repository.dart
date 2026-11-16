import 'package:verdant/models/product.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Data contract used by the UI; the source (API, mock, cache) stays hidden.
abstract class ProductRepository {
  Future<List<ProductSummary>> getProducts({String? category});
  Future<List<ProductSummary>> getFeaturedProducts();
  Future<ProductDetails> getProductDetails(int id);
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

class ApiProductRepository implements ProductRepository {
  // The client is injectable (e.g. MockClient in tests).
  ApiProductRepository({required this.origin, http.Client? client})
    : _client = client ?? http.Client();

  final String origin;
  final http.Client _client;

  String get _api => '$origin/api';

  /// Throws on non-200, otherwise returns the `data` field of `{ "data": ... }`.
  dynamic _data(http.Response r, String what) {
    if (r.statusCode != 200) {
      throw Exception('Failed to load $what: ${r.statusCode}');
    }
    return (jsonDecode(r.body) as Map<String, dynamic>)['data'];
  }

  /// JSON list -> ProductSummary, with `image` resolved to an absolute URL.
  List<ProductSummary> _summaries(List list) => list
      .cast<Map<String, dynamic>>()
      .map(
        (j) => ProductSummary.fromJson({
          ...j,
          'image': resolveImage(j['image'] as String, origin),
        }),
      )
      .toList();

  @override
  Future<List<ProductSummary>> getProducts({String? category}) async {
    final uri = Uri.parse('$_api/products').replace(
      queryParameters: category == null ? null : {'category': category},
    );
    return _summaries(_data(await _client.get(uri), 'products') as List);
  }

  @override
  Future<List<ProductSummary>> getFeaturedProducts() async {
    final response = await _client.get(Uri.parse('$_api/featured'));
    return _summaries(_data(response, 'featured products') as List);
  }

  @override
  Future<ProductDetails> getProductDetails(int id) async {
    final json = _data(
      await _client.get(Uri.parse('$_api/products/$id')),
      'product ($id)',
    ) as Map<String, dynamic>;

    // Make the product's own images and the related products' images absolute.
    String abs(String p) => resolveImage(p, origin);
    return ProductDetails.fromJson({
      ...json,
      'images': (json['images'] as List).map((i) => abs(i as String)).toList(),
      'related': (json['related'] as List)
          .cast<Map<String, dynamic>>()
          .map((r) => {...r, 'image': abs(r['image'] as String)})
          .toList(),
    });
  }
}