/// A live price for one instrument.
///
/// Replaces the plain `Map<String, double>` the quotes endpoint used to return.
/// That map carried the price and nothing else, which is why every screen had
/// to guess the currency — and guessed rupees for everything.
class Quote {
  const Quote({
    required this.symbol,
    required this.price,
    this.changePercent,
    this.currency,
  });

  final String symbol;
  final double price;
  final double? changePercent;

  /// ISO code from the quote source ("INR", "USD"). Null if the source didn't
  /// report one, in which case the UI shows the number without a symbol rather
  /// than assuming.
  final String? currency;

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      symbol: json['symbol'] as String,
      price: (json['price'] as num).toDouble(),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}
