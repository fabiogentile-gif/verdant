class ProductTag {
  const ProductTag({required this.label, this.icon});

  final String label;
  final String? icon; // chiave icona, es. "sprout"

  factory ProductTag.fromJson(Map<String, dynamic> json) => ProductTag(
        label: json['label'] as String,
        icon: json['icon'] as String?,
      );
}

class CareStep {
  const CareStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final String icon; // "sun", "droplets", "sprout"
  final String title;
  final String description;

  factory CareStep.fromJson(Map<String, dynamic> json) => CareStep(
        icon: json['icon'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
      );
}

/// Versione leggera di un prodotto (liste, correlati)
class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.tag,
  });

  final int id;
  final String name;
  final double price;
  final String image;
  final String? tag;

  factory ProductSummary.fromJson(Map<String, dynamic> json) => ProductSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        image: json['image'] as String,
        tag: json['tag'] as String?,
      );
}

class ProductDetails {
  const ProductDetails({
    required this.id,
    required this.name,
    required this.price,
    this.eyebrow,
    this.rating,
    this.reviewCount,
    this.inStock = true,
    this.availabilityLabel,
    this.summary,
    this.tags = const [],
    this.images = const [],
    this.variantLabel,
    this.variantDetail,
    this.purchaseNote,
    this.descriptionTitle,
    this.description,
    this.growth,
    this.goodToKnow,
    this.careSteps = const [],
    this.related = const [],
  });

  final int id;
  final String name;
  final double price;
  final String? eyebrow;
  final double? rating;
  final int? reviewCount;
  final bool inStock;
  final String? availabilityLabel;
  final String? summary;
  final List<ProductTag> tags;
  final List<String> images;
  final String? variantLabel;
  final String? variantDetail;
  final String? purchaseNote;
  final String? descriptionTitle;
  final String? description;
  final String? growth;
  final String? goodToKnow;
  final List<CareStep> careSteps;
  final List<ProductSummary> related;

  factory ProductDetails.fromJson(Map<String, dynamic> json) => ProductDetails(
        id: json['id'] as int,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        eyebrow: json['eyebrow'] as String?,
        rating: (json['rating'] as num?)?.toDouble(),
        reviewCount: json['review_count'] as int?,
        inStock: json['in_stock'] as bool? ?? true,
        availabilityLabel: json['availability_label'] as String?,
        summary: json['summary'] as String?,
        tags: _list(json['tags'], ProductTag.fromJson),
        images: (json['images'] as List? ?? const []).cast<String>(),
        variantLabel: json['variant_label'] as String?,
        variantDetail: json['variant_detail'] as String?,
        purchaseNote: json['purchase_note'] as String?,
        descriptionTitle: json['description_title'] as String?,
        description: json['description'] as String?,
        growth: json['growth'] as String?,
        goodToKnow: json['good_to_know'] as String?,
        careSteps: _list(json['care_steps'], CareStep.fromJson),
        related: _list(json['related'], ProductSummary.fromJson),
      );
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  return (raw as List? ?? const [])
      .map((e) => parse(e as Map<String, dynamic>))
      .toList();
}