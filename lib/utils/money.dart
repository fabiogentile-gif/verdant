import 'package:verdant/l10n/i18n.dart';

String _decimals(String amount) =>
    I18n.isItalian ? amount.replaceAll('.', ',') : amount;

/// `$38.00` (`$38,00` in Italian).
String formatMoney(double value) => '\$${_decimals(value.toStringAsFixed(2))}';

/// `$26` for whole amounts, `$24.50` otherwise.
String formatCompactMoney(double value) =>
    value == value.roundToDouble() ? '\$${value.toInt()}' : formatMoney(value);
