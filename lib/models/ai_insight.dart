class AiInsight {
  final String insight;
  final String generatedAt;

  AiInsight({required this.insight, required this.generatedAt});

  factory AiInsight.fromJson(Map<String, dynamic> json) {
    return AiInsight(
      insight: json['insight'] as String,
      generatedAt: json['generatedAt'] as String,
    );
  }
}
