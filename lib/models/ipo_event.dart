class IpoEvent {
  final String company;
  final String openDate;
  final String closeDate;
  final String priceRange;

  IpoEvent({
    required this.company,
    required this.openDate,
    required this.closeDate,
    required this.priceRange,
  });

  factory IpoEvent.fromJson(Map<String, dynamic> json) {
    return IpoEvent(
      company: json['company'] as String,
      openDate: json['openDate'] as String,
      closeDate: json['closeDate'] as String,
      priceRange: json['priceRange'] as String,
    );
  }
}
