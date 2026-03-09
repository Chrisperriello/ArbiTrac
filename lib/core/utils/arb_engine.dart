import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

class ArbEngine {

  // Constants for the class using the Decimal Class
  static final Decimal _one = Decimal.fromInt(1);
  static final Decimal _zero = Decimal.fromInt(0);
  static const int _scaleOnInfinitePrecision = 12;


  //Converter from normal number types to decimal, this is due to type 
  // Compatbility 
  static Decimal _toDecimal(Rational value) {
    return value.toDecimal(scaleOnInfinitePrecision: _scaleOnInfinitePrecision);
  }


  //Function for converting the implied Probability, this converts from the bookmaker
  //odds to probabilities
  static Decimal impliedProbability(Decimal decimalOdds) {
    if (decimalOdds <= _zero) {
      throw ArgumentError.value(
        decimalOdds,
        'decimalOdds',
        'Must be greater than 0.',
      );
    }
    return _toDecimal(_one / decimalOdds);
  }

  //This is the abritrage Percentage 
  // Meaning given given all the odds 
  static Decimal arbitragePercentage(List<Decimal> decimalOdds) {
    if (decimalOdds.length < 2) {
      throw ArgumentError.value(
        decimalOdds,
        'decimalOdds',
        'At least two odds are required.',
      );
    }
    //From list map the function to each item
    // fold all the items into one number by the function (just summing)
    return decimalOdds
        .map(impliedProbability)
        .fold(_zero, (sum, probability) => sum + probability);
  }

  //This says if there is profit chance 
  static bool isArbitrageOpportunity(List<Decimal> decimalOdds) {
    return arbitragePercentage(decimalOdds) < _one;
  }


  //Once you know there is an Arbitrafe Opportunity
  //Then this will tell you how much to put on each of the 
  // odds to get the maximum profit 
  static List<Decimal> individualStakes({
    required List<Decimal> decimalOdds,
    required Decimal totalInvestment,
  }) {
    if (totalInvestment <= _zero) {
      throw ArgumentError.value(
        totalInvestment,
        'totalInvestment',
        'Must be greater than 0.',
      );
    }

    final arbPercentage = arbitragePercentage(decimalOdds);
    return decimalOdds
        .map(
          (odds) =>
              _toDecimal(totalInvestment / arbPercentage) *
              impliedProbability(odds),
        )
        .toList(growable: false);
  }
}
