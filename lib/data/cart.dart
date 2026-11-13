import 'package:flutter/foundation.dart';
import 'package:verdant/models/product.dart';

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
}

/// In-memory shopping cart shared by the whole app.
/// Listen to it with `ListenableBuilder(listenable: cart, ...)`.
class Cart extends ChangeNotifier {
  static const freeDeliveryThreshold = 100.0;
  static const deliveryFee = 6.0;
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

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  DiscountCode? get discount => _discount;

  /// Total number of units (a plant with quantity 2 counts as 2).
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  /// Merchandise subtotal, before discount and delivery.
  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.total);

  double get discountAmount =>
      _discount == null ? 0 : _round(subtotal * _discount!.rate);

  /// Free delivery is based on the merchandise subtotal.
  bool get hasFreeDelivery => subtotal >= freeDeliveryThreshold;
  double get delivery => isEmpty || hasFreeDelivery ? 0 : deliveryFee;
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
    notifyListeners();
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
    notifyListeners();
  }

  void remove(int productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  /// Returns true when [code] is valid and has been applied.
  bool applyDiscount(String code) {
    final match = _codes[code.trim().toUpperCase()];
    if (match == null) return false;
    _discount = match;
    notifyListeners();
    return true;
  }

  void removeDiscount() {
    _discount = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _discount = null;
    notifyListeners();
  }

  CartItem? _find(int productId) {
    for (final i in _items) {
      if (i.productId == productId) return i;
    }
    return null;
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}

final cart = Cart();
