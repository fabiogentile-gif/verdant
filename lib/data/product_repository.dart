import 'package:verdant/models/product.dart';

abstract class ProductRepository {
  Future<ProductDetails> getProductDetails(String id);
}

/// Cambia questa riga quando l'API sarà pronta
ProductRepository productRepository = MockProductRepository();

// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiProductRepository implements ProductRepository {
//   ApiProductRepository({required this.baseUrl, http.Client? client})
//       : _client = client ?? http.Client();

//   final String baseUrl;
//   final http.Client _client;

//   @override
//   Future<ProductDetails> getProductDetails(String id) async {
//     final response = await _client.get(Uri.parse('$baseUrl/products/$id'));
//     if (response.statusCode != 200) {
//       throw Exception('Failed to load product ($id): ${response.statusCode}');
//     }
//     return ProductDetails.fromJson(
//       jsonDecode(response.body) as Map<String, dynamic>,
//     );
//   }
// }

class MockProductRepository implements ProductRepository {
  @override
  Future<ProductDetails> getProductDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final product = _products[id];
    if (product == null) {
      throw Exception('Product not found: $id');
    }
    return product;
  }

  static const _products = {
    'monstera': ProductDetails(
      id: 'monstera',
      name: 'Monstera deliciosa',
      eyebrow: 'THE STATEMENT LEAF',
      rating: 4.9,
      reviewCount: 128,
      price: 38,
      inStock: true,
      availabilityLabel: 'In stock · ready to grow',
      summary:
          'A little tropical drama, without the fuss. Meet the iconic split-leaf beauty that makes any corner feel alive.',
      tags: [
        ProductTag(label: 'Easy care', icon: 'sprout'),
        ProductTag(label: 'Indoor'),
        ProductTag(label: 'Air-loving'),
      ],
      images: ['assets/images/products/product_monstera_deliciosa.png'],
      variantLabel: '6-inch nursery pot',
      variantDetail: '18–24 in tall',
      purchaseNote: 'Nursery pot included · Decorative pot sold separately',
      descriptionTitle: 'A natural conversation starter',
      description:
          'Native to the tropical forests of Central America, this climbing aroid develops beautiful leaf splits as it matures. Give it room, gentle light and a moss pole, and watch a living sculpture unfold.',
      growth: 'Upright climber',
      goodToKnow: 'Keep away from pets',
      careSteps: [
        CareStep(
          icon: 'sun',
          title: 'Bright, indirect light',
          description: 'A few feet from a sunny window is just right.',
        ),
        CareStep(
          icon: 'droplets',
          title: 'Water every 7–10 days',
          description: 'Check first: let the top 2 inches of soil dry.',
        ),
        CareStep(
          icon: 'sprout',
          title: 'Airy, well-draining soil',
          description: 'A chunky potting mix keeps roots happy.',
        ),
      ],
      related: [
        ProductSummary(
          id: 'sandstone-pot',
          name: 'Sandstone pot',
          price: 24,
          image: 'assets/images/products/product_sandstone_pot.png',
        ),
        ProductSummary(
          id: 'potting-mix',
          name: 'Organic potting mix',
          price: 12,
          image: 'assets/images/products/product_organic_potting_mix.png',
        ),
      ],
    ),
  };
}