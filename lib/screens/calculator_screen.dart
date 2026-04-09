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
                    constraints: BoxConstraints(
                      maxWidth: 560,
                      maxHeight: MediaQuery.sizeOf(context).height - 110,
                    ),
                    decoration: cyberGlassPanelDecoration(),
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const ManualArbCalculatorCard(),

                          const SizedBox(height: 10),
                          const _ManualArbHowToUseSection(),
                        ],
                      ),
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
            const _ExampleBlock(
              title: '2-Way Market Example (H2H/Moneyline) - American',
              scenario: 'NFL - Kansas City Chiefs vs. Buffalo Bills.',
              setup: 'Bookie A Chiefs +110, Bookie B Bills +105.',
              steps: [
                'Set Bookie A sign to + and enter 110.',
                'Set Bookie B sign to + and enter 105.',
                'Enter \$100 in Total Investment.',
              ],
              resultLines: [
                'Arb % is about 97.5% (profitable).',
                'Bet about \$48.78 on Chiefs and \$51.22 on Bills for guaranteed profit.',
              ],
            ),
            const SizedBox(height: 10),
            const _ExampleBlock(
              title: '3-Way Market Example (1X2/Soccer) - American',
              scenario:
                  'Premier League - Liverpool vs. Arsenal (including Draw).',
              setup:
                  'Bookie A Liverpool +150, Bookie B Draw +250, Bookie C Arsenal +280.',
              steps: [
                'Enter Bookie A as +150.',
                'Enter Bookie B as +250.',
                'Enter Bookie C as +280.',
              ],
              resultLines: [
                'The app sums reciprocal odds.',
                'If total implied probability is below 100%, it marks a Profitable Opportunity and shows the 3-way stake split.',
              ],
            ),
          ] else ...[
            const _ExampleBlock(
              title: '2-Way Market Example (H2H/Moneyline) - Decimal',
              scenario: 'NFL - Kansas City Chiefs vs. Buffalo Bills.',
              setup: 'Bookie A Chiefs 2.10, Bookie B Bills 2.05.',
              steps: [
                'Enter 2.10 for Bookie A.',
                'Enter 2.05 for Bookie B.',
                'Enter \$100 in Total Investment.',
              ],
              resultLines: [
                'The implied probability total is below 100%, so this is profitable.',
              ],
            ),
            const SizedBox(height: 10),
            const _ExampleBlock(
              title: '3-Way Market Example (1X2/Soccer) - Decimal',
              scenario:
                  'Premier League - Liverpool vs. Arsenal (including Draw).',
              setup: 'Bookie A 2.50, Bookie B 3.50, Bookie C 3.80.',
              steps: [
                'Enter 2.50 for Bookie A, 3.50 for Bookie B, and 3.80 for Bookie C.',
                'Use all three legs in the calculator.',
                'Enter your total investment.',
              ],
              resultLines: [
                'Calculation: 1/2.5 + 1/3.5 + 1/3.8 = 0.40 + 0.28 + 0.26 = 0.94.',
                'This implies about a 6% profit margin.',
              ],
            ),
          ],
          const SizedBox(height: 10),
          const _ProTipBox(),
        ],
      ),
    );
  }
}

class _ExampleBlock extends StatelessWidget {
  const _ExampleBlock({
    required this.title,
    required this.scenario,
    required this.setup,
    required this.steps,
    required this.resultLines,
  });

  final String title;
  final String scenario;
  final String setup;
  final List<String> steps;
  final List<String> resultLines;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text('Scenario: $scenario'),
        Text('Setup: $setup'),
        const SizedBox(height: 6),
        ...List.generate(
          steps.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _StepCard(stepNumber: index + 1, text: steps[index]),
          ),
        ),
        ...resultLines.map((line) => Text('Result: $line')),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.stepNumber, required this.text});

  final int stepNumber;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QuantTheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: QuantTheme.textMuted.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$stepNumber.',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: QuantTheme.action,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ProTipBox extends StatelessWidget {
  const _ProTipBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QuantTheme.action.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: QuantTheme.action.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(10),
      child: Text(
        'Pro Tip: If the total implied probability is less than 100%, you have found an arbitrage.',
        style: Theme.of(context).textTheme.bodyMedium,
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
