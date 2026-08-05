class MarketItem {
  final String symbol;
  final String name;
  final double value;
  final double changePercent;

  MarketItem({
    required this.symbol,
    required this.name,
    required this.value,
    required this.changePercent,
  });

  bool get isUp => changePercent >= 0;

  factory MarketItem.fromJson(Map<String, dynamic> json) {
    return MarketItem(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
    );
  }
}
