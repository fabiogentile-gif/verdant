// Private fields can't be named parameters.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:verdant/data/api_client.dart';
import 'package:verdant/data/storage.dart';
import 'package:verdant/models/product.dart';
import 'package:verdant/l10n/i18n.dart';

/// A product in the cart with its quantity and optional variant (e.g. pot size).
class CartItem {
  CartItem({
    required this.productId,
    required String name,
    required this.unitPrice,
    required this.image,
    String? variant,
    this.quantity = 1,
  }) : _name = name,
       _variant = variant;

  final int productId;
  final String _name;
  final String? _variant;

  String get name => _name.tr;
  String? get variant => _variant?.tr;

  final double unitPrice;
  final String image;
  int quantity;

  double get total => unitPrice * quantity;

  Map<String, Object?> toJson() => {
    'productId': productId,
    'name': _name,
    'unitPrice': unitPrice,
    'image': image,
    'variant': _variant,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map json) => CartItem(
    productId: json['productId'] as int,
    name: json['name'] as String,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    image: json['image'] as String,
    variant: json['variant'] as String?,
    quantity: json['quantity'] as int? ?? 1,
  );
}

/// A discount code the shop recognises.
class DiscountCode {
  const DiscountCode({
    required this.code,
    required String label,
    required this.rate,
  }) : _label = label;

  final String code;
  final String _label;

  String get label => _label.tr;
  final double rate; // 0.10 = 10%

  /// e.g. `GROW10 · 10% off`
  String get shortLabel =>
      trArgs('{0} · {1}% off', [code, (rate * 100).round()]);

  Map<String, Object?> toJson() => {
    'code': code,
    'label': _label,
    'rate': rate,
  };

  factory DiscountCode.fromJson(Map json) => DiscountCode(
    code: json['code'] as String,
    label: json['label'] as String,
    rate: (json['rate'] as num).toDouble(),
  );
}

/// Delivery choices at checkout: price and expected days in transit.
enum ShippingOption {
  standard(
    label: 'Standard delivery',
    fee: 6.0,
    minDays: 5,
    maxDays: 7,
    note: 'plant-safe packaging',
  ),
  express(label: 'Express delivery', fee: 12.0, minDays: 2, maxDays: 4);

  const ShippingOption({
    required String label,
    required this.fee,
    required this.minDays,
    required this.maxDays,
    String? note,
  }) : _label = label,
       _note = note;

  final String _label;
  final double fee;
  final int minDays;
  final int maxDays;
  final String? _note;

  String get label => _label.tr;
  String? get note => _note?.tr;
}

/// Shopping cart shared by the whole app, saved on the device.
/// Listen to it with `ListenableBuilder(listenable: cart, ...)`.
class Cart extends ChangeNotifier {
  /// Standard delivery is free above this merchandise subtotal.
  static const freeDeliveryThreshold = 100.0;
  static const maxQuantity = 99;

  final List<CartItem> _items = [];
  DiscountCode? _discount;
  ShippingOption _shipping = ShippingOption.standard;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  DiscountCode? get discount => _discount;
  ShippingOption get shipping => _shipping;

  set shipping(ShippingOption value) {
    if (value == _shipping) return;
    _shipping = value;
    _changed();
  }

  /// Fee for [option] with the current cart (standard can become free).
  double feeFor(ShippingOption option) {
    if (isEmpty) return 0;
    if (option == ShippingOption.standard && hasFreeDelivery) return 0;
    return option.fee;
  }

  /// Total number of units (a plant with quantity 2 counts as 2).
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  /// Merchandise subtotal, before discount and delivery.
  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.total);

  double get discountAmount =>
      _discount == null ? 0 : _round(subtotal * _discount!.rate);

  /// Free delivery is based on the merchandise subtotal.
  bool get hasFreeDelivery => subtotal >= freeDeliveryThreshold;
  double get delivery => feeFor(_shipping);
  double get amountToFreeDelivery =>
      hasFreeDelivery ? 0 : freeDeliveryThreshold - subtotal;
  double get freeDeliveryProgress =>
      (subtotal / freeDeliveryThreshold).clamp(0.0, 1.0);

  double get total => _round(subtotal - discountAmount + delivery);

  void add({
    required int productId,
    required String name,
    required double unitPrice,
    required String image,
    String? variant,
    int quantity = 1,
  }) {
    final existing = _find(productId);
    if (existing != null) {
      existing.quantity = (existing.quantity + quantity).clamp(1, maxQuantity);
    } else {
      _items.add(
        CartItem(
          productId: productId,
          name: name,
          unitPrice: unitPrice,
          image: image,
          variant: variant,
          quantity: quantity.clamp(1, maxQuantity),
        ),
      );
    }
    _changed();
  }

  void addSummary(ProductSummary p, {int quantity = 1}) => add(
    productId: p.id,
    name: p.rawName,
    unitPrice: p.price,
    image: p.image,
    quantity: quantity,
  );

  void addDetails(ProductDetails p, {int quantity = 1}) => add(
    productId: p.id,
    name: p.rawName,
    unitPrice: p.price,
    image: p.images.isNotEmpty ? p.images.first : '',
    variant: p.rawVariantLabel,
    quantity: quantity,
  );

  void setQuantity(int productId, int quantity) {
    final item = _find(productId);
    if (item == null) return;
    item.quantity = quantity.clamp(1, maxQuantity);
    _changed();
  }

  void remove(int productId) {
    _items.removeWhere((i) => i.productId == productId);
    _changed();
  }

  /// Asks the server about [code] and applies it.
  /// Returns an error message, or null on success.
  Future<String?> applyDiscount(String code) async {
    try {
      final json = await api.post('/discounts/validate', {'code': code.trim()});
      _discount = DiscountCode.fromJson(json as Map);
      _changed();
      return null;
    } on ApiException catch (e) {
      return e.fields['code'] ?? e.message;
    }
  }

  void removeDiscount() {
    _discount = null;
    _changed();
  }

  void clear() {
    _items.clear();
    _discount = null;
    _shipping = ShippingOption.standard;
    _changed();
  }

  /// Empties the cart in memory only (saved data is handled by the caller).
  void reset() {
    _items.clear();
    _discount = null;
    _shipping = ShippingOption.standard;
    notifyListeners();
  }

  CartItem? _find(int productId) {
    for (final i in _items) {
      if (i.productId == productId) return i;
    }
    return null;
  }

  void restore() {
    final json = Storage.read(StorageKeys.cart);
    if (json is! Map) return;
    _items
      ..clear()
      ..addAll(
        (json['items'] as List? ?? []).whereType<Map>().map(CartItem.fromJson),
      );
    final saved = json['discount'];
    _discount = saved is Map ? DiscountCode.fromJson(saved) : null;
    _shipping =
        ShippingOption.values.asNameMap()[json['shipping']] ?? _shipping;
    notifyListeners();
  }

  void _changed() {
    Storage.write(StorageKeys.cart, {
      'items': _items.map((i) => i.toJson()).toList(),
      'discount': _discount?.toJson(),
      'shipping': _shipping.name,
    });
    notifyListeners();
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}

/// The cart shared by the shop, product pages and checkout.
final cart = Cart();
