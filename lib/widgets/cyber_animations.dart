import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/cyber_arb_theme.dart';

Widget cyberShimmer({required Widget child}) {
  return Shimmer.fromColors(
    baseColor: CyberArbTheme.primary.withValues(alpha: 0.22),
    highlightColor: CyberArbTheme.secondary.withValues(alpha: 0.38),
    period: const Duration(milliseconds: 1300),
    child: child,
  );
}

class CyberPulseIndicator extends StatefulWidget {
  const CyberPulseIndicator({
    super.key,
    required this.stalenessSeconds,
    this.tooltipMessage,
    this.pulseColor,
  });

  final int stalenessSeconds;
  final String? tooltipMessage;
  final Color? pulseColor;

  @override
  State<CyberPulseIndicator> createState() => _CyberPulseIndicatorState();
}

class _CyberPulseIndicatorState extends State<CyberPulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Duration get _period => widget.stalenessSeconds > 15
      ? const Duration(milliseconds: 420)
      : const Duration(milliseconds: 900);

  Color get _defaultColor => widget.stalenessSeconds > 45
      ? Colors.redAccent
      : widget.stalenessSeconds > 15
      ? CyberArbTheme.secondary
      : CyberArbTheme.profitHighlight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _period)
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CyberPulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_period != _controller.duration) {
      _controller
        ..duration = _period
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltipMessage ?? '',
      waitDuration: const Duration(milliseconds: 250),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
        child: Icon(
          Icons.circle,
          size: 9,
          color: widget.pulseColor ?? _defaultColor,
        ),
      ),
    );
  }
}
