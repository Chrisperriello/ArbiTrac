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
