import 'dart:math' as math;

import '../astro/day_ephemeris.dart';
import 'score_weights.dart';
import 'solunar_day.dart';
import 'solunar_period.dart';
import 'weather_input.dart';

/// Efemeris çıktısını solunar periyotlara + 0–100 skora çeviren saf motor.
///
/// `core/` kuralı: hiçbir Flutter/IO bağımlılığı yok → tamamen birim test
/// edilebilir. Ağırlıklar [ScoreWeights]'te; girdiler şeffaf faktörlere ayrışır.
class SolunarEngine {
  final ScoreWeights weights;

  /// Major periyot yarı-genişliği (transit ±). Varsayılan 60 dk.
  final Duration majorHalfWidth;

  /// Minor periyot yarı-genişliği (doğuş/batış ±). Varsayılan 30 dk.
  final Duration minorHalfWidth;

  const SolunarEngine({
    this.weights = ScoreWeights.defaults,
    this.majorHalfWidth = const Duration(minutes: 60),
    this.minorHalfWidth = const Duration(minutes: 30),
  });

  SolunarDay evaluate(
    DayEphemeris eph, {
    WeatherInput? weather,
  }) {
    final twilightWindows = _twilightWindows(eph);

    final majors = <SolunarPeriod>[
      for (final t in eph.moonUpperTransits)
        _period(SolunarPeriodType.major, SolunarPeriodKind.upperTransit, t,
            majorHalfWidth, twilightWindows),
      for (final t in eph.moonLowerTransits)
        _period(SolunarPeriodType.major, SolunarPeriodKind.lowerTransit, t,
            majorHalfWidth, twilightWindows),
    ]..sort((a, b) => a.start.compareTo(b.start));

    final minors = <SolunarPeriod>[
      for (final t in eph.moonrises)
        _period(SolunarPeriodType.minor, SolunarPeriodKind.moonrise, t,
            minorHalfWidth, twilightWindows),
      for (final t in eph.moonsets)
        _period(SolunarPeriodType.minor, SolunarPeriodKind.moonset, t,
            minorHalfWidth, twilightWindows),
    ]..sort((a, b) => a.start.compareTo(b.start));

    // --- Faktörler ---
    final hasWeather = weather?.hasData ?? false;
    final effectiveWeights =
        hasWeather ? weights : weights.withoutPressure();

    final moonPhaseRaw = _moonPhaseRaw(eph.moonAgeFraction);
    final twilightRaw = _twilightOverlapRaw(majors, minors);
    final pressureRaw = hasWeather ? weather!.activityFactor : 0.0;
    final seasonalRaw = _seasonalRaw(eph);

    final factors = <ScoreFactor>[
      _factor('moon_phase', moonPhaseRaw, effectiveWeights.moonPhase),
      _factor('twilight_overlap', twilightRaw, effectiveWeights.twilightOverlap),
      if (hasWeather)
        _factor('pressure_trend', pressureRaw, effectiveWeights.pressureTrend),
      _factor('seasonal', seasonalRaw, effectiveWeights.seasonal),
    ];

    final score = factors
        .fold<double>(0.0, (sum, f) => sum + f.contribution)
        .round()
        .clamp(0, 100);

    return SolunarDay(
      score: score,
      fishRating: _fishRating(score),
      majorPeriods: majors,
      minorPeriods: minors,
      factors: factors,
      usedWeather: hasWeather,
    );
  }

  // ---------------------------------------------------------------------------

  SolunarPeriod _period(
    SolunarPeriodType type,
    SolunarPeriodKind kind,
    DateTime peak,
    Duration halfWidth,
    List<({DateTime start, DateTime end})> twilightWindows,
  ) {
    final start = peak.subtract(halfWidth);
    final end = peak.add(halfWidth);
    final overlaps = twilightWindows.any(
        (w) => start.isBefore(w.end) && end.isAfter(w.start));
    return SolunarPeriod(
      type: type,
      kind: kind,
      start: start,
      peak: peak,
      end: end,
      overlapsTwilight: overlaps,
    );
  }

  /// Şafak ve akşam alacakaranlık pencereleri (prime feeding). Ufuk anları yoksa
  /// (kutup) o pencere atlanır.
  List<({DateTime start, DateTime end})> _twilightWindows(DayEphemeris e) {
    final windows = <({DateTime start, DateTime end})>[];

    final dawnStart = e.civilDawn ?? e.sunrise?.subtract(const Duration(minutes: 30));
    final dawnEnd = e.sunrise?.add(const Duration(minutes: 60)) ??
        e.civilDawn?.add(const Duration(minutes: 90));
    if (dawnStart != null && dawnEnd != null) {
      windows.add((start: dawnStart, end: dawnEnd));
    }

    final duskStart = e.sunset?.subtract(const Duration(minutes: 60)) ??
        e.civilDusk?.subtract(const Duration(minutes: 90));
    final duskEnd = e.civilDusk ?? e.sunset?.add(const Duration(minutes: 30));
    if (duskStart != null && duskEnd != null) {
      windows.add((start: duskStart, end: duskEnd));
    }

    return windows;
  }

  /// Ay fazı ham faktörü: yeni (0) ve dolunay (0.5) pik, dördünlerde (0.25/0.75)
  /// taban. Sinodik kesre en yakın pik uzaklığından türetilir.
  double _moonPhaseRaw(double age) {
    final d = [
      (age - 0.0).abs(),
      (age - 0.5).abs(),
      (age - 1.0).abs(),
    ].reduce(math.min);
    // Pike max uzaklık 0.25 (dördün). 0 uzaklık → 1.0, 0.25 → 0.0.
    return (1.0 - d / 0.25).clamp(0.0, 1.0);
  }

  /// Periyot-alacakaranlık çakışması: her çakışan major +0.5, minor +0.25; 1.0'da
  /// tavan. Şafak/akşamla çakışan bir major, "prime day"in imzasıdır.
  double _twilightOverlapRaw(
      List<SolunarPeriod> majors, List<SolunarPeriod> minors) {
    var v = 0.0;
    for (final p in majors) {
      if (p.overlapsTwilight) v += 0.5;
    }
    for (final p in minors) {
      if (p.overlapsTwilight) v += 0.25;
    }
    return v.clamp(0.0, 1.0);
  }

  /// Mevsim/fotoperiyot faktörü: gün uzunluğu 8s→0.2, 14s+→1.0 arası. Kutup
  /// edge'inde (ufuk anı yok) nötr 0.6. Konservatif — baskın olmasın diye.
  double _seasonalRaw(DayEphemeris e) {
    final sr = e.sunrise;
    final ss = e.sunset;
    if (sr == null || ss == null) return 0.6;
    final dayLenHours = ss.difference(sr).inMinutes / 60.0;
    return ((dayLenHours - 8.0) / 6.0).clamp(0.2, 1.0);
  }

  ScoreFactor _factor(String key, double raw, double weight) => ScoreFactor(
        key: key,
        raw: raw,
        weight: weight,
        contribution: raw * weight * 100.0,
      );

  int _fishRating(int score) {
    if (score >= 80) return 5;
    if (score >= 60) return 4;
    if (score >= 45) return 3;
    if (score >= 25) return 2;
    return 1;
  }
}
