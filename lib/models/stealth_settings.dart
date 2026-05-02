class StealthSettings {
  const StealthSettings({
    this.stealthModeEnabled = false,
    this.betsPerDay = 5,
    this.booksCount = 3,
    this.sportsCount = 3,
    this.roundingIncrement = 5,
  });

  final bool stealthModeEnabled;
  final int betsPerDay;
  final int booksCount;
  final int sportsCount;
  final int roundingIncrement;

  StealthSettings copyWith({
    bool? stealthModeEnabled,
    int? betsPerDay,
    int? booksCount,
    int? sportsCount,
    int? roundingIncrement,
  }) {
    return StealthSettings(
      stealthModeEnabled: stealthModeEnabled ?? this.stealthModeEnabled,
      betsPerDay: betsPerDay ?? this.betsPerDay,
      booksCount: booksCount ?? this.booksCount,
      sportsCount: sportsCount ?? this.sportsCount,
      roundingIncrement: roundingIncrement ?? this.roundingIncrement,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stealthModeEnabled': stealthModeEnabled,
      'betsPerDay': betsPerDay,
      'booksCount': booksCount,
      'sportsCount': sportsCount,
      'roundingIncrement': roundingIncrement,
    };
  }

  factory StealthSettings.fromMap(Map<String, dynamic> map) {
    return StealthSettings(
      stealthModeEnabled: map['stealthModeEnabled'] as bool? ?? false,
      betsPerDay: (map['betsPerDay'] as num? ?? 5).toInt(),
      booksCount: (map['booksCount'] as num? ?? 3).toInt(),
      sportsCount: (map['sportsCount'] as num? ?? 3).toInt(),
      roundingIncrement: (map['roundingIncrement'] as num? ?? 5).toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StealthSettings &&
          runtimeType == other.runtimeType &&
          stealthModeEnabled == other.stealthModeEnabled &&
          betsPerDay == other.betsPerDay &&
          booksCount == other.booksCount &&
          sportsCount == other.sportsCount &&
          roundingIncrement == other.roundingIncrement;

  @override
  int get hashCode =>
      stealthModeEnabled.hashCode ^
      betsPerDay.hashCode ^
      booksCount.hashCode ^
      sportsCount.hashCode ^
      roundingIncrement.hashCode;
}
