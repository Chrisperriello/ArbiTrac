import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

//The card for the manual arb
class ManualArbCalculatorCard extends ConsumerWidget {
  const ManualArbCalculatorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Calculator
    final calculatorState = ref.watch(manualArbCalculatorProvider);
    //result from the calculator
    final result = calculatorState.result;
    //format the odds
    final oddsFormat = ref.watch(manualArbOddsFormatProvider);

    return Card(
      //Expansion drop down card
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          'Manual Arb Calculator',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: const Text('Tap to expand'),
        children: [
          //This is the drop down formater
          _OddsFormatDropdown(
            value: oddsFormat,
            onChanged: (value) =>
                ref.read(manualArbOddsFormatProvider.notifier).state = value,
          ),
          const SizedBox(height: 8),
          //If odds are in decimal then
          if (oddsFormat == ManualArbOddsFormat.decimal) ...[
            //Input fields for each of the cards
            _DecimalInputField(
              label: 'Odds (Bookie A)',
              onChanged: (value) =>
                  ref.read(manualArbOddsAProvider.notifier).state = value,
            ),
            const SizedBox(height: 8),
            _DecimalInputField(
              label: 'Odds (Bookie B)',
              onChanged: (value) =>
                  ref.read(manualArbOddsBProvider.notifier).state = value,
            ),
            const SizedBox(height: 8),
            _DecimalInputField(
              label: 'Odds (Bookie C, optional)',
              onChanged: (value) =>
                  ref.read(manualArbOddsCProvider.notifier).state = value,
            ),
          ] else ...[
            _AmericanOddsInputRow(
              label: 'Bookie A',
              selectedSign: ref.watch(manualArbAmericanSignAProvider),
              onSignChanged: (value) =>
                  ref.read(manualArbAmericanSignAProvider.notifier).state =
                      value,
              onOddsChanged: (value) =>
                  ref.read(manualArbOddsAProvider.notifier).state = value,
            ),
            const SizedBox(height: 8),
            _AmericanOddsInputRow(
              label: 'Bookie B',
              selectedSign: ref.watch(manualArbAmericanSignBProvider),
              onSignChanged: (value) => {
                ref.read(manualArbAmericanSignBProvider.notifier).state = value,
              },
              onOddsChanged: (value) =>
                  ref.read(manualArbOddsBProvider.notifier).state = value,
            ),
            const SizedBox(height: 8),
            _AmericanOddsInputRow(
              label: 'Bookie C (optional)',
              selectedSign: ref.watch(manualArbAmericanSignCProvider),
              onSignChanged: (value) =>
                  ref.read(manualArbAmericanSignCProvider.notifier).state =
                      value,
              onOddsChanged: (value) =>
                  ref.read(manualArbOddsCProvider.notifier).state = value,
            ),
          ],
          const SizedBox(height: 8),
          _DecimalInputField(
            label: 'Total Investment (\$)',
            onChanged: (value) =>
                ref.read(manualArbTotalInvestmentProvider.notifier).state =
                    value,
          ),
          const SizedBox(height: 10),
          if (calculatorState.errorMessage != null)
            Text(
              calculatorState.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (result != null) ...[
            Text('Arbitrage % (sum): ${_formatDecimal(result.arbitrageSum)}'),
            Text(
              'Status: ${result.isArbitrage ? "Profitable opportunity" : "No guaranteed arbitrage"}',
            ),
            const SizedBox(height: 6),
            Text(
              'Required stakes:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            ...result.recommendedStakes.map(
              (stake) => Text(
                'Bet \$${_formatDecimal(stake.stake)} on ${stake.label} (odds ${_formatDecimal(stake.odds)})',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Guaranteed payout: \$${_formatDecimal(result.guaranteedPayout)}',
            ),
            Text('Net Profit: \$${_formatDecimal(result.netProfit)}'),
          ],
        ],
      ),
    );
  }
}

//For the odds formatting
class _OddsFormatDropdown extends StatelessWidget {
  const _OddsFormatDropdown({required this.value, required this.onChanged});
  //values
  final ManualArbOddsFormat value;
  final ValueChanged<ManualArbOddsFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Odds format'),
        const SizedBox(width: 10),
        DropdownButton<ManualArbOddsFormat>(
          value: value,
          items: const [
            DropdownMenuItem(
              value: ManualArbOddsFormat.decimal,
              child: Text('Decimal'),
            ),
            DropdownMenuItem(
              value: ManualArbOddsFormat.american,
              child: Text('American'),
            ),
          ],
          onChanged: (nextValue) {
            if (nextValue != null) {
              onChanged(nextValue);
            }
          },
        ),
      ],
    );
  }
}

class _AmericanOddsInputRow extends StatelessWidget {
  const _AmericanOddsInputRow({
    required this.label,
    required this.selectedSign,
    required this.onSignChanged,
    required this.onOddsChanged,
  });

  final String label;
  final ManualArbAmericanSign selectedSign;
  final ValueChanged<ManualArbAmericanSign> onSignChanged;
  final ValueChanged<String> onOddsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Row(
          children: [
            DropdownButton<ManualArbAmericanSign>(
              value: selectedSign,
              items: const [
                DropdownMenuItem(
                  value: ManualArbAmericanSign.plus,
                  child: Text('+'),
                ),
                DropdownMenuItem(
                  value: ManualArbAmericanSign.minus,
                  child: Text('-'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onSignChanged(value);
                }
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'American odds value (e.g. 150)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: onOddsChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DecimalInputField extends StatelessWidget {
  const _DecimalInputField({required this.label, required this.onChanged});

  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

String _formatDecimal(Decimal value) {
  final raw = value.toString();
  final decimalIndex = raw.indexOf('.');
  if (decimalIndex == -1) {
    return raw;
  }
  final maxLength = decimalIndex + 3;
  if (raw.length <= maxLength) {
    return raw;
  }
  return raw.substring(0, maxLength);
}
