
import 'dart:async';

import 'package:flutter/material.dart';

class FreshnessIndicator extends StatefulWidget {
  const FreshnessIndicator({super.key, required this.lastUpdatedAt});

  final DateTime lastUpdatedAt;

  @override
  State<FreshnessIndicator> createState() => _FreshnessIndicatorState();
}

class _FreshnessIndicatorState extends State<FreshnessIndicator> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final freshnessSeconds = DateTime.now()
        .difference(widget.lastUpdatedAt)
        .inSeconds;
    final freshnessColor = freshnessSeconds <= 15
        ? Colors.green
        : freshnessSeconds <= 45
        ? Colors.orange
        : Colors.red;
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: freshnessColor),
        const SizedBox(width: 8),
        Text('Updated ${freshnessSeconds < 0 ? 0 : freshnessSeconds}s ago'),
      ],
    );
  }
}
