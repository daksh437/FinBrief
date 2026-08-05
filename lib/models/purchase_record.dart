class PurchaseRecord {
  final String productId;
  final String type; // subscription | credits
  final int? creditsGranted;
  final int createdAt;

  PurchaseRecord({
    required this.productId,
    required this.type,
    required this.createdAt,
    this.creditsGranted,
  });

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      productId: json['productId'] as String,
      type: json['type'] as String,
      creditsGranted: (json['creditsGranted'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as num).toInt(),
    );
  }
}
