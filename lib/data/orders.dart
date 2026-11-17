import 'package:flutter/foundation.dart';
import 'package:verdant/data/address.dart';
import 'package:verdant/data/cart.dart';
import 'package:verdant/data/payment.dart';
import 'package:verdant/data/storage.dart';

/// A placed (demo) order: a snapshot of the cart at checkout time.
class Order {
  const Order({
    required this.items,
    required this.subtotal,
    required this.discountLabel,
    required this.discountAmount,
    required this.shipping,
    required this.delivery,
    required this.total,
    required this.paymentTitle,
    this.number,
    this.placedAt,
    this.address,
  });

  /// Snapshot of the live cart (not yet placed).
  factory Order.fromCart([PaymentMethod? method]) => Order(
    items: cart.items,
    subtotal: cart.subtotal,
    discountLabel: cart.discount?.shortLabel,
    discountAmount: cart.discountAmount,
    shipping: cart.shipping,
    delivery: cart.delivery,
    total: cart.total,
    paymentTitle: method?.title,
  );

  final List<CartItem> items;
  final double subtotal;
  final String? discountLabel;
  final double discountAmount;
  final ShippingOption shipping;
  final double delivery;
  final double total;
  final String? paymentTitle;

  /// Set once the order is placed.
  final String? number;
  final DateTime? placedAt;
  final DeliveryAddress? address;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  /// Earliest and latest expected delivery date.
  (DateTime, DateTime) get arrivalWindow {
    final from = placedAt ?? DateTime.now();
    return (
      from.add(Duration(days: shipping.minDays)),
      from.add(Duration(days: shipping.maxDays)),
    );
  }

  /// "Placed", "On its way" or "Delivered", estimated from the dates
  /// (there is no real shipping partner).
  String status({DateTime? now}) {
    final at = now ?? DateTime.now();
    final (_, latest) = arrivalWindow;
    if (at.isAfter(latest)) return 'Delivered';
    if (placedAt != null && at.difference(placedAt!).inDays >= 1) {
      return 'On its way';
    }
    return 'Placed';
  }

  Order placed({
    required String number,
    required DateTime at,
    required DeliveryAddress address,
  }) => Order(
    items: items,
    subtotal: subtotal,
    discountLabel: discountLabel,
    discountAmount: discountAmount,
    shipping: shipping,
    delivery: delivery,
    total: total,
    paymentTitle: paymentTitle,
    number: number,
    placedAt: at,
    address: address,
  );

  Map<String, Object?> toJson() => {
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'discountLabel': discountLabel,
    'discountAmount': discountAmount,
    'shipping': shipping.name,
    'delivery': delivery,
    'total': total,
    'paymentTitle': paymentTitle,
    'number': number,
    'placedAt': placedAt?.toIso8601String(),
    'address': address?.toJson(),
  };

  factory Order.fromJson(Map json) => Order(
    items: (json['items'] as List)
        .whereType<Map>()
        .map(CartItem.fromJson)
        .toList(),
    subtotal: (json['subtotal'] as num).toDouble(),
    discountLabel: json['discountLabel'] as String?,
    discountAmount: (json['discountAmount'] as num).toDouble(),
    shipping:
        ShippingOption.values.asNameMap()[json['shipping']] ??
        ShippingOption.standard,
    delivery: (json['delivery'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    paymentTitle: json['paymentTitle'] as String?,
    number: json['number'] as String?,
    placedAt: json['placedAt'] == null
        ? null
        : DateTime.parse(json['placedAt'] as String),
    address: json['address'] is Map
        ? DeliveryAddress.fromJson(json['address'] as Map)
        : null,
  );
}

/// Orders placed on this device, most recent first.
class OrderHistory extends ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  void add(Order order) {
    _orders.insert(0, order);
    Storage.write(StorageKeys.orders, _orders.map((o) => o.toJson()).toList());
    notifyListeners();
  }

  void restore() {
    final json = Storage.read(StorageKeys.orders);
    if (json is! List) return;
    _orders
      ..clear()
      ..addAll(json.whereType<Map>().map(Order.fromJson));
    notifyListeners();
  }

  void reset() {
    _orders.clear();
    notifyListeners();
  }
}

/// Orders placed on this device, shared by checkout, profile and notifications.
final orderHistory = OrderHistory();
