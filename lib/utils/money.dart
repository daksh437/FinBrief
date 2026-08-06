/// Formats prices with the instrument's own currency.
///
/// The app used to print `₹` in front of every price. That is right for an NSE
/// listing and wrong for everything else — a watchlist holding AAPL showed
/// "₹311.58" for a dollar price, which is not a cosmetic problem on a finance
/// screen. The currency now travels with the quote from Yahoo, and this is the
/// only place that turns it into a symbol.
class Money {
  Money._();

  static const _symbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AED': 'AED ',
    'SGD': 'S\$',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  /// Falls back to the ISO code with a space ("CHF 91.20") rather than
  /// guessing — an unknown currency shown with the wrong symbol is worse than
  /// one shown with its code.
  static String symbol(String? currency) {
    if (currency == null || currency.isEmpty) return '';
    return _symbols[currency.toUpperCase()] ?? '${currency.toUpperCase()} ';
  }

  static String format(num? amount, String? currency, {int decimals = 2}) {
    if (amount == null) return '—';
    return '${symbol(currency)}${amount.toStringAsFixed(decimals)}';
  }

  /// Same, with an explicit sign — for gains and losses.
  static String formatSigned(num? amount, String? currency, {int decimals = 2}) {
    if (amount == null) return '—';
    final sign = amount >= 0 ? '+' : '-';
    return '$sign${symbol(currency)}${amount.abs().toStringAsFixed(decimals)}';
  }
}
