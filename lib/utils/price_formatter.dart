import 'package:intl/intl.dart';

class PriceFormatter {
  static final _format = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 0,
  );

  static String format(int amount) => _format.format(amount);

  static String formatFromString(String value) {
    final n = int.tryParse(value) ?? 0;
    return format(n);
  }
}
