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

class MarketImpact {
  final String sentiment; // bullish | bearish | neutral
  final double confidence;
  final String reason;
  final List<String> affectedSectors;

  MarketImpact({
    required this.sentiment,
    required this.reason,
    this.confidence = 0,
    this.affectedSectors = const [],
  });

  factory MarketImpact.fromJson(Map<String, dynamic> json) {
    return MarketImpact(
      sentiment: (json['sentiment'] as String?) ?? 'neutral',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reason: (json['reason'] as String?) ?? '',
      affectedSectors: ((json['affectedSectors'] as List?) ?? []).map((e) => e.toString()).toList(),
    );
  }
}
