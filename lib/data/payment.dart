import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:verdant/data/storage.dart';
import 'package:verdant/l10n/i18n.dart';

// ---------------------------------------------------------------------------
// DEMO ONLY. Nothing here talks to a real payment provider.
// For safety we never keep the full card number or the CVC: only brand,
// last 4 digits, holder and expiry are stored (on the device).
// ---------------------------------------------------------------------------

/// Card networks recognised from the card number.
enum CardBrand {
  visa('Visa', 'VISA'),
  mastercard('Mastercard', 'MC'),
  amex('American Express', 'AMEX'),
  unknown('Card', 'CARD');

  const CardBrand(this._displayName, this.badge);

  final String _displayName;

  String get displayName => _displayName.tr;

  final String badge;

  /// Brand from the first digits of a card number.
  static CardBrand detect(String number) {
    final n = digitsOnly(number);
    if (n.startsWith('4')) return visa;
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(n)) return mastercard;
    if (RegExp(r'^3[47]').hasMatch(n)) return amex;
    return unknown;
  }

  /// Amex uses a 4-digit CVC and a 15-digit card number.
  int get cvcLength => this == amex ? 4 : 3;
  int get numberLength => this == amex ? 15 : 16;
}

/// A saved way to pay: a card or a PayPal account.
sealed class PaymentMethod {
  const PaymentMethod({required this.id});

  final String id;

  /// Short text inside the brand badge (e.g. "VISA").
  String get badge;
  String get title;
  String get subtitle;

  Map<String, Object?> toJson();

  static PaymentMethod? fromJson(Map json) => switch (json['type']) {
    'card' => CardPayment(
      id: json['id'] as String,
      brand: CardBrand.values.asNameMap()[json['brand']] ?? CardBrand.unknown,
      last4: json['last4'] as String,
      holder: json['holder'] as String,
      expMonth: json['expMonth'] as int,
      expYear: json['expYear'] as int,
    ),
    'paypal' => PayPalPayment(
      id: json['id'] as String,
      email: json['email'] as String,
    ),
    _ => null,
  };
}

/// A saved card: only brand, last 4 digits, holder and expiry date.
class CardPayment extends PaymentMethod {
  const CardPayment({
    required super.id,
    required this.brand,
    required this.last4,
    required this.holder,
    required this.expMonth,
    required this.expYear,
  });

  final CardBrand brand;
  final String last4;
  final String holder;
  final int expMonth;
  final int expYear; // two digits, e.g. 28

  @override
  String get badge => brand.badge;

  @override
  String get title => trArgs('{0} ending in {1}', [brand.displayName, last4]);

  @override
  String get subtitle => trArgs('{0} · Exp. {1}/{2}', [
    holder,
    expMonth.toString().padLeft(2, '0'),
    expYear.toString().padLeft(2, '0'),
  ]);

  /// Only non-sensitive fields: never the full number or the CVC.
  @override
  Map<String, Object?> toJson() => {
    'type': 'card',
    'id': id,
    'brand': brand.name,
    'last4': last4,
    'holder': holder,
    'expMonth': expMonth,
    'expYear': expYear,
  };
}

/// A connected PayPal account: only the email is saved.
class PayPalPayment extends PaymentMethod {
  const PayPalPayment({required super.id, required this.email});

  final String email;

  @override
  String get badge => 'PayPal';

  @override
  String get title => 'PayPal';

  @override
  String get subtitle => email;

  @override
  Map<String, Object?> toJson() => {'type': 'paypal', 'id': id, 'email': email};
}

/// Saved payment methods (on the device) and the one selected for checkout.
class Wallet extends ChangeNotifier {
  final List<PaymentMethod> _methods = [];
  String? _selectedId;

  List<PaymentMethod> get methods => List.unmodifiable(_methods);

  PaymentMethod? get selected {
    for (final m in _methods) {
      if (m.id == _selectedId) return m;
    }
    return null;
  }

  /// Validates and saves a card. Throws [ArgumentError] when invalid.
  CardPayment addCard({
    required String holder,
    required String number,
    required String expiry,
    required String cvc,
  }) {
    final error =
        CardValidator.holder(holder) ??
        CardValidator.number(number) ??
        CardValidator.expiry(expiry) ??
        CardValidator.cvc(cvc, CardBrand.detect(number));
    if (error != null) throw ArgumentError(error);

    final digits = digitsOnly(number);
    final (month, year) = CardValidator.parseExpiry(expiry)!;
    final card = CardPayment(
      id: _newId(),
      brand: CardBrand.detect(digits),
      last4: digits.substring(digits.length - 4),
      holder: holder.trim(),
      expMonth: month,
      expYear: year,
    );
    _add(card);
    return card;
  }

  /// Fake PayPal login: waits a moment, then "connects" the account.
  Future<PayPalPayment> connectPayPal({
    required String email,
    required String password,
  }) async {
    final error =
        PayPalValidator.email(email) ?? PayPalValidator.password(password);
    if (error != null) throw ArgumentError(error);

    await Future<void>.delayed(const Duration(milliseconds: 900));
    final account = PayPalPayment(id: _newId(), email: email.trim());
    _add(account);
    return account;
  }

  void select(String id) {
    if (_selectedId == id) return;
    _selectedId = id;
    _changed();
  }

  void remove(String id) {
    _methods.removeWhere((m) => m.id == id);
    if (_selectedId == id) {
      _selectedId = _methods.isEmpty ? null : _methods.last.id;
    }
    _changed();
  }

  void restore() {
    final json = Storage.read(StorageKeys.wallet);
    if (json is! Map) return;
    _methods
      ..clear()
      ..addAll(
        (json['methods'] as List? ?? [])
            .whereType<Map>()
            .map(PaymentMethod.fromJson)
            .nonNulls,
      );
    _selectedId = json['selectedId'] as String?;
    notifyListeners();
  }

  void reset() {
    _methods.clear();
    _selectedId = null;
    notifyListeners();
  }

  void _add(PaymentMethod method) {
    _methods.add(method);
    _selectedId = method.id;
    _changed();
  }

  void _changed() {
    Storage.write(StorageKeys.wallet, {
      'methods': _methods.map((m) => m.toJson()).toList(),
      'selectedId': _selectedId,
    });
    notifyListeners();
  }

  static final _random = Random();
  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}';
}

/// Payment methods shared by checkout and the profile.
final wallet = Wallet();

// ---------------------------------------------------------------------------
// Validation (returns an error message, or null when valid)
// ---------------------------------------------------------------------------

/// Removes spaces, dashes and any other non-digit character.
String digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

/// Validation of the card form fields.
abstract final class CardValidator {
  static String? holder(String value) =>
      value.trim().length < 2 ? 'Enter the name on the card.'.tr : null;

  static String? number(String value) {
    final n = digitsOnly(value);
    if (n.isEmpty) return 'Enter the card number.'.tr;
    final brand = CardBrand.detect(n);
    final expected = brand == CardBrand.unknown ? null : brand.numberLength;
    if (expected != null
        ? n.length != expected
        : (n.length < 13 || n.length > 19)) {
      return 'This card number looks incomplete.'.tr;
    }
    if (!luhn(n)) return 'This card number isn’t valid.'.tr;
    return null;
  }

  /// Accepts `MM/YY`. The card is valid through the end of that month.
  static String? expiry(String value, {DateTime? now}) {
    final parsed = parseExpiry(value);
    if (parsed == null) return 'Use the MM/YY format.'.tr;
    final (month, year) = parsed;
    final today = now ?? DateTime.now();
    final firstDayAfter = DateTime(2000 + year, month + 1);
    if (!firstDayAfter.isAfter(today)) return 'This card has expired.'.tr;
    return null;
  }

  static String? cvc(String value, CardBrand brand) {
    final n = digitsOnly(value);
    return n.length == brand.cvcLength
        ? null
        : trArgs('Enter the {0}-digit security code.', [brand.cvcLength]);
  }

  static (int, int)? parseExpiry(String value) {
    final m = RegExp(r'^\s*(\d{2})\s*/\s*(\d{2})\s*$').firstMatch(value);
    if (m == null) return null;
    final month = int.parse(m.group(1)!);
    if (month < 1 || month > 12) return null;
    return (month, int.parse(m.group(2)!));
  }

  /// Luhn checksum used by all major card networks.
  /// Example of a valid number: 5123 8372 7321 1090.
  static bool luhn(String digits) {
    var sum = 0;
    var double = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = digits.codeUnitAt(i) - 48;
      if (double) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      double = !double;
    }
    return sum % 10 == 0;
  }
}

/// Validation of the (fake) PayPal login form.
abstract final class PayPalValidator {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String value) =>
      _email.hasMatch(value.trim()) ? null : 'Enter a valid email address.'.tr;

  static String? password(String value) =>
      value.isEmpty ? 'Enter your PayPal password.'.tr : null;
}
