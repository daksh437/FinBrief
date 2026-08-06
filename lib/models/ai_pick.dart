/// A company or asset the day's news is about.
///
/// Deliberately carries no direction. A `sentiment` field (bullish / bearish /
/// neutral) used to sit here, but naming a security and attaching a direction
/// to it reads as a recommendation however carefully it is worded — which is
/// the line SEBI's adviser and research-analyst regulations sit on. What is
/// left is reporting: which companies the news concerns, and what it says.
class AiPick {
  final String symbol;
  final String name;
  final String reason;

  /// Live price and day change. Null when the ticker couldn't be resolved —
  /// the tile then drops the price line rather than showing a placeholder.
  /// These replaced the sentiment badge: a real number is information, where
  /// the badge was a generated opinion dressed as one.
  final double? price;
  final double? changePercent;

  AiPick({
    required this.symbol,
    required this.name,
    required this.reason,
    this.price,
    this.changePercent,
  });

  bool get hasPrice => price != null;
  bool get isUp => (changePercent ?? 0) >= 0;

  factory AiPick.fromJson(Map<String, dynamic> json) {
    return AiPick(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      reason: json['reason'] as String,
      price: (json['price'] as num?)?.toDouble(),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
    );
  }
}
