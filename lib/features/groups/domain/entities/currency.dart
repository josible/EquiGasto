enum Currency {
  eur('EUR', '€', 'Euro'),
  usd('USD', '\$', 'Dólar estadounidense'),
  gbp('GBP', '£', 'Libra esterlina'),
  ars('ARS', '\$', 'Peso argentino'),
  cop('COP', '\$', 'Peso colombiano'),
  mxn('MXN', '\$', 'Peso mexicano'),
  pen('PEN', 'S/', 'Sol');

  final String code;
  final String symbol;
  final String displayName;

  const Currency(this.code, this.symbol, this.displayName);

  static Currency fromString(String code) {
    return Currency.values.firstWhere(
      (currency) => currency.code == code.toUpperCase(),
      orElse: () => Currency.eur, // Default a EUR
    );
  }

  // Obtener las monedas principales (las que aparecen primero)
  static List<Currency> get mainCurrencies => [eur, usd, gbp];
  
  // Obtener todas las monedas (principales primero, luego las demás)
  static List<Currency> get allCurrencies => [
    ...mainCurrencies,
    ...Currency.values.where((c) => !mainCurrencies.contains(c)),
  ];
}

