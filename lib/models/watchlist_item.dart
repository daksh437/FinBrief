class WatchlistItem {
  final String symbol;
  final String? name;
  final double? alertPrice;
  final String type;

  WatchlistItem({required this.symbol, this.name, this.alertPrice, this.type = 'Stocks'});

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      symbol: json['symbol'] as String,
      name: json['name'] as String?,
      alertPrice: (json['alertPrice'] as num?)?.toDouble(),
      type: json['type'] as String? ?? 'Stocks',
    );
  }
}
