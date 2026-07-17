import 'dart:math' as math;

import 'solunar_day.dart';
import 'solunar_period.dart';

/// [day]'in periyotlarından, yerel gün için 24 saatlik [0..1] aktivite eğrisi
/// üretir (F4.4 "saatlik aktivite eğrisi"). Her periyot tepesi etrafında bir
/// çan eğrisi biriktirir — major periyotlar daha yüksek/geniş, minor daha
/// düşük/dar. Saf fonksiyon: `core/` hiçbir Flutter/IO bağımlılığı içermez.
///
/// [sampleCount] örnek sayısı (varsayılan 25 → 0,1..24 saat, grafik ekseniyle
/// hizalı). [localDate] + [offset] periyot zamanlarını yerel güne bucketler.
List<double> hourlyActivityCurve(
  SolunarDay day, {
  int sampleCount = 25,
}) {
  final samples = List<double>.filled(sampleCount, 0.0);
  const baseline = 0.08;

  void accumulate(SolunarPeriod p) {
    final peakHour = p.peak.hour + p.peak.minute / 60.0;
    final halfWidthHours = p.duration.inMinutes / 60.0; // start..peak yarısı
    final amplitude = p.type == SolunarPeriodType.major ? 1.0 : 0.55;
    final sigma = math.max(0.4, halfWidthHours * 0.9);

    for (var i = 0; i < sampleCount; i++) {
      final hour = i * 24.0 / (sampleCount - 1);
      // Gün sınırını dolanarak en kısa saat farkı (23:30 ↔ 00:30 sürekliliği).
      var d = (hour - peakHour).abs();
      if (d > 12) d = 24 - d;
      final v = amplitude * math.exp(-(d * d) / (2 * sigma * sigma));
      samples[i] += v;
    }
  }

  for (final p in day.majorPeriods) {
    accumulate(p);
  }
  for (final p in day.minorPeriods) {
    accumulate(p);
  }

  for (var i = 0; i < sampleCount; i++) {
    samples[i] = (baseline + samples[i]).clamp(0.0, 1.0);
  }
  return samples;
}
