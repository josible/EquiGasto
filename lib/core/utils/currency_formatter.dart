import '../../features/groups/domain/entities/currency.dart';

class CurrencyFormatter {
  /// Formatea un importe con el símbolo de la moneda después del número
  static String formatAmount(double amount, Currency currency) {
    final formattedAmount = amount.toStringAsFixed(2).replaceAll('.', ',');
    return '$formattedAmount ${currency.symbol}';
  }

  /// Formatea un importe con signo positivo/negativo y el símbolo de la moneda
  static String formatAmountWithSign(double amount, Currency currency) {
    if (amount > 0) {
      return '+${formatAmount(amount, currency)}';
    } else if (amount < 0) {
      return '-${formatAmount(-amount, currency)}';
    } else {
      return formatAmount(0, currency);
    }
  }
}

