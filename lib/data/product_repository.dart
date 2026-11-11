import 'package:verdant/models/product.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class ProductRepository {
  Future<List<ProductSummary>> getProducts({String? category});
  Future<List<ProductSummary>> getFeaturedProducts();
  Future<ProductDetails> getProductDetails(int id);
}

String get apiOrigin {
  const fromEnv = String.fromEnvironment('API_ORIGIN');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000'; // localhost for emulator android
  }
  return 'http://localhost:3000';
}

ProductRepository productRepository = ApiProductRepository(origin: apiOrigin);

String resolveImage(String path, String origin) =>
    path.startsWith('http') ? path : '$origin$path';

ImageProvider imageFor(String src) =>
    src.startsWith('http') ? NetworkImage(src) : AssetImage(src);

class ApiProductRepository implements ProductRepository {
  ApiProductRepository({required this.origin, http.Client? client})
    : _client = client ?? http.Client();

  final String origin;
  final http.Client _client;

  String get _api => '$origin/api';

  dynamic _data(http.Response r, String what) {
    if (r.statusCode != 200) {
      throw Exception('Failed to load $what: ${r.statusCode}');
    }
    return (jsonDecode(r.body) as Map<String, dynamic>)['data'];
  }

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
