import 'package:flutter/material.dart';

class RiskMonitor extends StatefulWidget {
  const RiskMonitor({super.key, required this.level});

  final int level;

  @override
  State<RiskMonitor> createState() => _RiskMonitorState();
}

class _RiskMonitorState extends State<RiskMonitor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final durationMs = 1200 - (widget.level.clamp(1, 10) * 80);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat(reverse: true);

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(RiskMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      final durationMs = 1200 - (widget.level.clamp(1, 10) * 80);
      _controller.duration = Duration(milliseconds: durationMs);
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRiskColor(int level) {
    if (level <= 2) return const Color(0xFF1B5E20); // Dark Green
    if (level <= 4) return const Color(0xFF4CAF50); // Light Green
    if (level <= 6) return const Color(0xFFFFEB3B); // Yellow
    if (level <= 8) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  String _getRiskLabel(int level) {
    if (level <= 2) return 'Low Risk';
    if (level <= 4) return 'Low-Mod Risk';
    if (level <= 6) return 'Mod Risk';
    if (level <= 8) return 'Mod-High Risk';
    return 'High Risk';
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(widget.level);
    final riskLabel = _getRiskLabel(widget.level);
    final mutedColor = Theme.of(context).disabledColor.withValues(alpha: 0.1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 30,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(10, (index) {
              final isFilled = index < widget.level;
              return AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? riskColor.withValues(alpha: _pulseAnimation.value)
                          : mutedColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: riskColor.withValues(alpha: 0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                },
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          riskLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: riskColor,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class NoRiskMonitor extends StatefulWidget {
  const NoRiskMonitor({super.key});

  @override
  State<NoRiskMonitor> createState() => _NoRiskMonitorState();
}

class _NoRiskMonitorState extends State<NoRiskMonitor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 0.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          'NO RISK',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
