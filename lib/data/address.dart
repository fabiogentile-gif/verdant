import 'package:flutter/foundation.dart';
import 'package:verdant/data/storage.dart';

class DeliveryAddress {
  const DeliveryAddress({
    required this.fullName,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.phone,
    required this.email,
    this.label = 'Home',
  });

  final String fullName;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final String phone;
  final String email;
  final String label;

  /// Demo address until user accounts exist.
  static const demo = DeliveryAddress(
    fullName: 'Maya Thompson',
    street: '124 Maple Street, Apt 3B',
    city: 'Portland, OR',
    postalCode: '97205',
    country: 'United States',
    phone: '+1 (503) 555-0148',
    email: 'maya.thompson@email.com',
  );

  /// Multi-line postal format.
  String get lines => '$street\n$city $postalCode\n$country';

  Map<String, Object?> toJson() => {
    'fullName': fullName,
    'street': street,
    'city': city,
    'postalCode': postalCode,
    'country': country,
    'phone': phone,
    'email': email,
    'label': label,
  };

  factory DeliveryAddress.fromJson(Map json) => DeliveryAddress(
    fullName: json['fullName'] as String,
    street: json['street'] as String,
    city: json['city'] as String,
    postalCode: json['postalCode'] as String,
    country: json['country'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String,
    label: json['label'] as String? ?? 'Home',
  );
}

/// The saved delivery address, kept on the device.
class AddressBook extends ChangeNotifier {
  DeliveryAddress _address = DeliveryAddress.demo;

  DeliveryAddress get address => _address;

  set address(DeliveryAddress value) {
    _address = value;
    Storage.write(StorageKeys.address, value.toJson());
    notifyListeners();
  }

  void restore() {
    final json = Storage.read(StorageKeys.address);
    if (json is! Map) return;
    _address = DeliveryAddress.fromJson(json);
    notifyListeners();
  }

  void reset() {
    _address = DeliveryAddress.demo;
    notifyListeners();
  }
}

final addressBook = AddressBook();
