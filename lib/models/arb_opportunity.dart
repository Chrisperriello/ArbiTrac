import 'package:decimal/decimal.dart';

//Class to represent one Arb opporunity
class ArbOpportunity {
  const ArbOpportunity({
    required this.eventId,
    required this.sportKey,
    required this.eventName,
    required this.marketLabel,
    required this.bookmakerAKey,
    required this.bookmakerBKey,
    required this.bookmakerA,
    required this.bookmakerB,
    required this.decimalOddsA,
    required this.decimalOddsB,
    required this.arbitrageSum,
    required this.profitMarginPercent,
    required this.commenceTime,
    required this.lastUpdatedAt,
  });

  final String eventId;
  final String sportKey;
  final String eventName;
  final String marketLabel;
  final String bookmakerAKey;
  final String bookmakerBKey;
  final String bookmakerA;
  final String bookmakerB;
  final Decimal decimalOddsA;
  final Decimal decimalOddsB;
  final Decimal arbitrageSum;
  final Decimal profitMarginPercent;
  final DateTime commenceTime;
  final DateTime lastUpdatedAt;

  String get favoriteId =>
      '$eventId|$marketLabel|$bookmakerAKey|$bookmakerBKey';
}
