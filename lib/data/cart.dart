import 'package:flutter/foundation.dart';
import 'package:verdant/data/storage.dart';
import 'package:verdant/models/product.dart';

/// A product in the cart with its quantity and optional variant (e.g. pot size).
class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.image,
    this.variant,
    this.quantity = 1,
  });

  final int productId;
  final String name;
  final double unitPrice;
  final String image;
  final String? variant;
  int quantity;

  double get total => unitPrice * quantity;

  Map<String, Object?> toJson() => {
    'productId': productId,
    'name': name,
    'unitPrice': unitPrice,
    'image': image,
    'variant': variant,
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
    required this.label,
    required this.rate,
  });

  final String code;
  final String label;
  final double rate; // 0.10 = 10%

  /// e.g. `GROW10 · 10% off`
  String get shortLabel => '$code · ${(rate * 100).round()}% off';
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
    required this.label,
    required this.fee,
    required this.minDays,
    required this.maxDays,
    this.note,
  });

  final String label;
  final double fee;
  final int minDays;
  final int maxDays;
  final String? note;
}

/// Shopping cart shared by the whole app, saved on the device.
/// Listen to it with `ListenableBuilder(listenable: cart, ...)`.
class Cart extends ChangeNotifier {
  /// Standard delivery is free above this merchandise subtotal.
  static const freeDeliveryThreshold = 100.0;
  static const maxQuantity = 99;

  static const _codes = {
    'GROW10': DiscountCode(
      code: 'GROW10',
      label: 'Welcome discount (10%)',
      rate: 0.10,
    ),
  };

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
    name: p.name,
    unitPrice: p.price,
    image: p.image,
    quantity: quantity,
  );

  void addDetails(ProductDetails p, {int quantity = 1}) => add(
    productId: p.id,
    name: p.name,
    unitPrice: p.price,
    image: p.images.isNotEmpty ? p.images.first : '',
    variant: p.variantLabel,
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

  /// Returns true when [code] is valid and has been applied.
  bool applyDiscount(String code) {
    final match = _codes[code.trim().toUpperCase()];
    if (match == null) return false;
    _discount = match;
    _changed();
    return true;
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
    _discount = _codes[json['discount']];
    _shipping =
        ShippingOption.values.asNameMap()[json['shipping']] ?? _shipping;
    notifyListeners();
  }

  void _changed() {
    Storage.write(StorageKeys.cart, {
      'items': _items.map((i) => i.toJson()).toList(),
      'discount': _discount?.code,
      'shipping': _shipping.name,
    });
    notifyListeners();
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}

/// The cart shared by the shop, product pages and checkout.
final cart = Cart();
