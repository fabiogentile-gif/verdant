// Private fields can't be named parameters.
// ignore_for_file: prefer_initializing_formals

import 'package:verdant/l10n/i18n.dart';

/// A label shown on a product page, with an optional icon.
class ProductTag {
  const ProductTag({required String label, this.icon}) : _label = label;

  final String _label;
  final String? icon; // icon key, e.g. "sprout"

  String get label => _label.tr;

  factory ProductTag.fromJson(Map<String, dynamic> json) =>
      ProductTag(label: json['label'] as String, icon: json['icon'] as String?);
}

/// One care tip shown on a product page.
class CareStep {
  const CareStep({
    required this.icon,
    required String title,
    required String description,
  }) : _title = title,
       _description = description;

  final String icon; // "sun", "droplets", "sprout"
  final String _title;
  final String _description;

  String get title => _title.tr;
  String get description => _description.tr;

  factory CareStep.fromJson(Map<String, dynamic> json) => CareStep(
    icon: json['icon'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
  );
}

/// Lightweight version of a product (lists, related products).
///
/// The API sends English; display getters follow the app language, while
/// [rawName] and [tags] stay in English for saving and category filters.
class ProductSummary {
  const ProductSummary({
    required this.id,
    required String name,
    required this.price,
    required this.image,
    String? tag,
    this.category,
    this.tags = const [],
    this.rating,
    this.featured = false,
    this.inStock = true,
  }) : rawName = name,
       _tag = tag;

  final int id;
  final String rawName;
  final double price;
  final String image;
  final String? _tag;

  String get name => rawName.tr;
  String? get tag => _tag?.tr;

  /// Backend category: "plants", "planters", "accessories".
  final String? category;

  /// Tag labels in English, e.g. "Easy care", "Indoor".
  final List<String> tags;
  final double? rating;
  final bool featured;
  final bool inStock;

  factory ProductSummary.fromJson(Map<String, dynamic> json) => ProductSummary(
    id: json['id'] as int,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    image: json['image'] as String,
    tag: json['tag'] as String?,
    category: json['category'] as String?,
    tags: [
      for (final t in json['tags'] as List? ?? const [])
        if (t is Map && t['label'] is String) t['label'] as String,
    ],
    rating: (json['rating'] as num?)?.toDouble(),
    featured: json['featured'] as bool? ?? false,
    inStock: json['inStock'] as bool? ?? true,
  );
}

/// Everything shown on a product page, as returned by `GET /api/products/:id`.
class ProductDetails {
  const ProductDetails({
    required this.id,
    required String name,
    required this.price,
    String? eyebrow,
    this.rating,
    this.reviewCount,
    this.inStock = true,
    String? availabilityLabel,
    String? summary,
    this.tags = const [],
    this.images = const [],
    String? variantLabel,
    String? variantDetail,
    String? purchaseNote,
    String? descriptionTitle,
    String? description,
    String? growth,
    String? goodToKnow,
    this.careSteps = const [],
    this.related = const [],
  }) : rawName = name,
       _eyebrow = eyebrow,
       _availabilityLabel = availabilityLabel,
       _summary = summary,
       rawVariantLabel = variantLabel,
       _variantDetail = variantDetail,
       _purchaseNote = purchaseNote,
       _descriptionTitle = descriptionTitle,
       _description = description,
       _growth = growth,
       _goodToKnow = goodToKnow;

  final int id;
  final String rawName;
  final double price;
  final String? _eyebrow;
  final double? rating;
  final int? reviewCount;
  final bool inStock;
  final String? _availabilityLabel;
  final String? _summary;
  final List<ProductTag> tags;
  final List<String> images;
  final String? rawVariantLabel;
  final String? _variantDetail;
  final String? _purchaseNote;
  final String? _descriptionTitle;
  final String? _description;
  final String? _growth;
  final String? _goodToKnow;
  final List<CareStep> careSteps;
  final List<ProductSummary> related;

  String get name => rawName.tr;
  String? get eyebrow => _eyebrow?.tr;
  String? get availabilityLabel => _availabilityLabel?.tr;
  String? get summary => _summary?.tr;
  String? get variantLabel => rawVariantLabel?.tr;
  String? get variantDetail => _variantDetail?.tr;
  String? get purchaseNote => _purchaseNote?.tr;
  String? get descriptionTitle => _descriptionTitle?.tr;
  String? get description => _description?.tr;
  String? get growth => _growth?.tr;
  String? get goodToKnow => _goodToKnow?.tr;

  factory ProductDetails.fromJson(Map<String, dynamic> json) => ProductDetails(
    id: json['id'] as int,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    eyebrow: json['eyebrow'] as String?,
    rating: (json['rating'] as num?)?.toDouble(),
    reviewCount: json['reviewCount'] as int?,
    inStock: json['inStock'] as bool? ?? true,
    availabilityLabel: json['availabilityLabel'] as String?,
    summary: json['summary'] as String?,
    tags: _list(json['tags'], ProductTag.fromJson),
    images: (json['images'] as List? ?? const []).cast<String>(),
    variantLabel: json['variantLabel'] as String?,
    variantDetail: json['variantDetail'] as String?,
    purchaseNote: json['purchaseNote'] as String?,
    descriptionTitle: json['descriptionTitle'] as String?,
    description: json['description'] as String?,
    growth: json['growth'] as String?,
    goodToKnow: json['goodToKnow'] as String?,
    careSteps: _list(json['careSteps'], CareStep.fromJson),
    related: _list(json['related'], ProductSummary.fromJson),
  );
}

/// Parses a JSON list of objects with [parse]; a missing list becomes empty.
List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  return (raw as List? ?? const [])
      .map((e) => parse(e as Map<String, dynamic>))
      .toList();
}
