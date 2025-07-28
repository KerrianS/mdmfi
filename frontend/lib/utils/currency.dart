import 'package:intl/intl.dart';

extension DoubleCurrency on double {
  String format({bool isKEuros = false}) {
    return Currency.format(this, isKEuros: isKEuros);
  }
}

class Currency {
  static final _numberFormat =
      NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  static final _numberFormatKEuros =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'K€');

  static String format(double value, {bool isKEuros = false}) {
    if (isKEuros) {
      return _numberFormatKEuros.format(value / 1000);
    }
    return _numberFormat.format(value);
  }
}
