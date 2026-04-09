import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/quant_theme.dart';
import '../providers/providers.dart';
import '../widgets/cyber_borders.dart';
import '../widgets/manual_arb_calculator_card.dart';

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  static const String routeName = '/calculator';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculatorState = ref.watch(manualArbCalculatorProvider);
    final result = calculatorState.result;

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Stake Allocation')),
      backgroundColor: QuantTheme.background,
      body: Stack(
        children: [
          const SizedBox.expand(),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 560,
                    constraints: const BoxConstraints(maxWidth: 560),
                    decoration: cyberGlassPanelDecoration(),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ManualArbCalculatorCard(),
                        const SizedBox(height: 10),
                        const _ManualArbHowToUseSection(),
                        if (result != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Guaranteed Profit: \$${_fixed(result.netProfit)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: QuantTheme.profit),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _HowToUseMode { american, decimal }

class _ManualArbHowToUseSection extends StatefulWidget {
  const _ManualArbHowToUseSection();

  @override
  State<_ManualArbHowToUseSection> createState() =>
      _ManualArbHowToUseSectionState();
}

class _ManualArbHowToUseSectionState extends State<_ManualArbHowToUseSection> {
  _HowToUseMode _selectedMode = _HowToUseMode.american;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: QuantTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: QuantTheme.textMuted.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'How to Use This',
                  style: textTheme.titleMedium?.copyWith(
                    color: QuantTheme.action,
                  ),
                ),
              ),
              SegmentedButton<_HowToUseMode>(
                segments: const [
                  ButtonSegment<_HowToUseMode>(
                    value: _HowToUseMode.american,
                    label: Text('American'),
                  ),
                  ButtonSegment<_HowToUseMode>(
                    value: _HowToUseMode.decimal,
                    label: Text('Decimal'),
                  ),
                ],
                selected: {_selectedMode},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  final selected = selection.first;
                  setState(() {
                    _selectedMode = selected;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedMode == _HowToUseMode.american) ...[
            Text(
              '2-Way Market Example (H2H/Moneyline) - American',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text('Scenario: NFL - Kansas City Chiefs vs. Buffalo Bills.'),
            const Text('Setup: Bookie A Chiefs +110, Bookie B Bills +105.'),
            const SizedBox(height: 4),
            const Text('1. Set Bookie A sign to + and enter 110.'),
            const Text('2. Set Bookie B sign to + and enter 105.'),
            const Text('3. Enter \$100 in Total Investment.'),
            const Text('Result: Arb % is about 97.5% (profitable).'),
            const Text(
              'Bet about \$48.78 on Chiefs and \$51.22 on Bills for guaranteed profit.',
            ),
          ] else ...[
            Text(
              '2-Way Market Example (H2H/Moneyline) - Decimal',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text('Scenario: NFL - Kansas City Chiefs vs. Buffalo Bills.'),
            const Text('Setup: Bookie A Chiefs 2.10, Bookie B Bills 2.05.'),
            const SizedBox(height: 4),
            const Text('1. Enter 2.10 for Bookie A.'),
            const Text('2. Enter 2.05 for Bookie B.'),
            const Text('3. Enter \$100 in Total Investment.'),
            const Text(
              'Result: the implied probability total is below 100%, so this is profitable.',
            ),
          ],
        ],
      ),
    );
  }
}

String _fixed(Object value) {
  final stringValue = value.toString();
  final dotIndex = stringValue.indexOf('.');
  if (dotIndex == -1) {
    return '$stringValue.00';
  }
  final decimals = stringValue.length - dotIndex - 1;
  if (decimals == 2 || decimals == 3) {
    return stringValue;
  }
  if (decimals < 2) {
    return '$stringValue${'0' * (2 - decimals)}';
  }
  return stringValue.substring(0, dotIndex + 4);
}
