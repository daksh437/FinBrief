class AiPick {
  final String symbol;
  final String name;
  final String sentiment; // bullish | bearish | neutral
  final String reason;

  AiPick({required this.symbol, required this.name, required this.sentiment, required this.reason});

  factory AiPick.fromJson(Map<String, dynamic> json) {
    return AiPick(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      sentiment: json['sentiment'] as String,
      reason: json['reason'] as String,
    );
  }
}
