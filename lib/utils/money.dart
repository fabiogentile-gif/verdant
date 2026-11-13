/// `$38.00`
String formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

/// `$26` for whole amounts, `$24.50` otherwise.
String formatCompactMoney(double value) => value == value.roundToDouble()
    ? '\$${value.toInt()}'
    : '\$${value.toStringAsFixed(2)}';
