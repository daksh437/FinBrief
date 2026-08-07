/// A mutual fund scheme, and — when the user holds it — their position in it.
///
/// NAV always comes from the server at read time, never from storage: a saved
/// NAV is stale the moment it is written, and a stale figure presented as
/// today's is worse on a money screen than showing none.
class Fund {
  const Fund({
    required this.schemeCode,
    required this.name,
    this.nav,
    this.navDate,
    this.units,
    this.invested,
    this.currentValue,
    this.gain,
    this.house,
    this.category,
  });

  final String schemeCode;
  final String name;

  final double? nav;

  /// The date AMFI struck this NAV. Shown to the user because it is usually
  /// yesterday's — funds are valued once, after markets close.
  final String? navDate;

  /// Null on a search result; set on a holding.
  final double? units;
  final double? invested;
  final double? currentValue;
  final double? gain;

  final String? house;
  final String? category;

  bool get isHolding => units != null;
  bool get isUp => (gain ?? 0) >= 0;

  double? get gainPercent =>
      (gain != null && invested != null && invested! > 0) ? (gain! / invested!) * 100 : null;

  /// AMFI names carry the plan in them ("… - Direct Plan - Growth"), which is
  /// noise once a fund is in the list. The leading part is the fund.
  String get shortName {
    final cut = name.split(RegExp(r'\s+-\s+')).first.trim();
    return cut.isEmpty ? name : cut;
  }

  /// The plan detail dropped from [shortName], shown smaller beneath it.
  String? get planLabel {
    final parts = name.split(RegExp(r'\s+-\s+'));
    if (parts.length < 2) return null;
    return parts.sublist(1).join(' · ').trim();
  }

  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      // Search results call it `code`; holdings call it `schemeCode`.
      schemeCode: (json['schemeCode'] ?? json['code']).toString(),
      name: json['name'] as String,
      nav: (json['nav'] as num?)?.toDouble(),
      navDate: json['navDate'] as String? ?? json['date'] as String?,
      units: (json['units'] as num?)?.toDouble(),
      invested: (json['invested'] as num?)?.toDouble(),
      currentValue: (json['currentValue'] as num?)?.toDouble(),
      gain: (json['gain'] as num?)?.toDouble(),
      house: json['house'] as String?,
      category: json['category'] as String?,
    );
  }
}
