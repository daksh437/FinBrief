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

  AiPick({required this.symbol, required this.name, required this.reason});

  factory AiPick.fromJson(Map<String, dynamic> json) {
    return AiPick(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      reason: json['reason'] as String,
    );
  }
}
