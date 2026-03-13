import 'package:decimal/decimal.dart';

//Class to represent one Arb opporunity 
class ArbOpportunity {
  const ArbOpportunity({
    required this.eventName,
    required this.marketLabel,
    required this.bookmakerA,
    required this.bookmakerB,
    required this.arbitrageSum,
    required this.profitMarginPercent,
    required this.commenceTime,
    required this.lastUpdatedAt,
  });

  final String eventName;
  final String marketLabel;
  final String bookmakerA;
  final String bookmakerB;
  final Decimal arbitrageSum;
  final Decimal profitMarginPercent;
  final DateTime commenceTime;
  final DateTime lastUpdatedAt;
}
