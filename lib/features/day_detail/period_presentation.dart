import 'package:flutter/material.dart';

import '../../core/core.dart';

/// Bir periyodun UI etiketi + yıldız yoğunluğu — yalnız sunum, skoru etkilemez.
/// Gerçek periyot türü + alacakaranlık çakışmasından türetilir (uydurma değil).
class PeriodPresentation {
  final String label;
  final IconData icon;
  final int stars; // 1..5

  const PeriodPresentation(
      {required this.label, required this.icon, required this.stars});

  factory PeriodPresentation.of(SolunarPeriod p, Duration utcOffset) {
    final localHour = p.peak.add(utcOffset).hour;
    final isDawnHalf = localHour < 12;

    switch (p.kind) {
      case SolunarPeriodKind.upperTransit:
        return PeriodPresentation(
          label: p.overlapsTwilight
              ? (isDawnHalf ? 'Dawn Transit' : 'Dusk Transit')
              : 'Overhead',
          icon: Icons.arrow_upward,
          stars: p.overlapsTwilight ? 5 : 4,
        );
      case SolunarPeriodKind.lowerTransit:
        return PeriodPresentation(
          label: p.overlapsTwilight
              ? (isDawnHalf ? 'Dawn Transit' : 'Dusk Transit')
              : 'Underfoot',
          icon: Icons.arrow_downward,
          stars: p.overlapsTwilight ? 5 : 4,
        );
      case SolunarPeriodKind.moonrise:
        return PeriodPresentation(
          label: 'Moonrise',
          icon: Icons.brightness_2_outlined,
          stars: p.overlapsTwilight ? 4 : 3,
        );
      case SolunarPeriodKind.moonset:
        return PeriodPresentation(
          label: 'Moonset',
          icon: Icons.brightness_3_outlined,
          stars: p.overlapsTwilight ? 4 : 3,
        );
    }
  }
}
