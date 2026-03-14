import 'package:decimal/decimal.dart';

class SportsEventDetail {
  const SportsEventDetail({
    required this.eventId,
    required this.sportKey,
    required this.awayTeam,
    required this.homeTeam,
    required this.commenceTime,
    required this.markets,
  });

  final String eventId;
  final String sportKey;
  final String awayTeam;
  final String homeTeam;
  final DateTime commenceTime;
  final List<SportsEventMarketDetail> markets;

  String get eventName => '$awayTeam vs $homeTeam';
}

class SportsEventMarketDetail {
  const SportsEventMarketDetail({
    required this.marketKey,
    required this.marketLabel,
    required this.bookmakerOdds,
  });

  final String marketKey;
  final String marketLabel;
  final List<SportsEventBookmakerOdds> bookmakerOdds;
}

class SportsEventBookmakerOdds {
  const SportsEventBookmakerOdds({
    required this.bookmakerTitle,
    required this.lastUpdatedAt,
    required this.outcomes,
  });

  final String bookmakerTitle;
  final DateTime lastUpdatedAt;
  final List<SportsEventOutcomeOdds> outcomes;
}

class SportsEventOutcomeOdds {
  const SportsEventOutcomeOdds({
    required this.name,
    this.decimalOdds,
    this.point,
  });

  final String name;
  final Decimal? decimalOdds;
  final Decimal? point;
}
