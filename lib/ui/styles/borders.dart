// Cyber-Arb visual depth is border-driven: thin neon outlines replace elevation
// to keep high-density surfaces crisp and technical.
import 'package:flutter/material.dart';

import '../../core/theme/cyber_arb_theme.dart';

BoxDecoration cyberArbOpportunityDecoration({required double profitPercent}) {
  final borderColor = profitPercent >= 3
      ? CyberArbTheme.profitHighlight
      : profitPercent >= 1
      ? CyberArbTheme.primary
      : CyberArbTheme.textMuted.withValues(alpha: 0.3);

  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
    ),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: borderColor, width: 1),
  );
}

BoxDecoration cyberGlassPanelDecoration() {
  return BoxDecoration(
    color: Colors.black.withValues(alpha: 0.6),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: CyberArbTheme.secondary.withValues(alpha: 0.5),
      width: 1,
    ),
  );
}
