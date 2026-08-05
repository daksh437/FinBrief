class PortfolioItem {
  final String symbol;
  final String? name;
  final double quantity;
  final double avgPrice;

  PortfolioItem({
    required this.symbol,
    required this.quantity,
    required this.avgPrice,
    this.name,
  });

  double get investedValue => quantity * avgPrice;

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      symbol: json['symbol'] as String,
      name: json['name'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      avgPrice: (json['avgPrice'] as num).toDouble(),
    );
  }
}
