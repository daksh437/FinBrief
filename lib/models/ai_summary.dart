class AiSummary {
  final String summary;
  final List<String> keyPoints;
  final double confidence;

  AiSummary({required this.summary, this.keyPoints = const [], this.confidence = 0});

  factory AiSummary.fromJson(Map<String, dynamic> json) {
    return AiSummary(
      summary: (json['summary'] as String?) ?? '',
      keyPoints: ((json['keyPoints'] as List?) ?? []).map((e) => e.toString()).toList(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// What a story concerns and which sectors it touches.
///
/// No direction, by design — see [AiPick] for why. `sentiment` and
/// `confidence` are simply ignored if an older backend still sends them.
class MarketImpact {
  final String reason;
  final List<String> affectedSectors;

  MarketImpact({
    required this.reason,
    this.affectedSectors = const [],
  });

  factory MarketImpact.fromJson(Map<String, dynamic> json) {
    return MarketImpact(
      reason: (json['reason'] as String?) ?? '',
      affectedSectors: ((json['affectedSectors'] as List?) ?? []).map((e) => e.toString()).toList(),
    );
  }
}
