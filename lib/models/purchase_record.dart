class PurchaseRecord {
  final String productId;
  final String type; // 'subscription'
  final String? basePlan; // 'monthly' | 'six-month' | 'yearly'
  final int createdAt;

  PurchaseRecord({
    required this.productId,
    required this.type,
    required this.createdAt,
    this.basePlan,
  });

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      productId: json['productId'] as String,
      type: json['type'] as String,
      // Absent on records written before credit packs were dropped, and on any
      // purchase made by an older build.
      basePlan: json['basePlan'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
    );
  }
}
