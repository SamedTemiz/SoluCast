import 'solunar_period.dart';

/// Skora giren tek bir faktörün şeffaf dökümü (F2.6: "Yeni ay +30, major şafakla
/// çakışıyor +20…"). UI bunu doğrudan gösterir.
class ScoreFactor {
  /// Kısa etiket anahtarı (l10n için), ör. `moon_phase`, `twilight_overlap`.
  final String key;

  /// Ham faktör değeri [0..1].
  final double raw;

  /// Uygulanan ağırlık.
  final double weight;

  /// Bu faktörün 0..100 skora katkısı (weight * raw * 100).
  final double contribution;

  const ScoreFactor({
    required this.key,
    required this.raw,
    required this.weight,
    required this.contribution,
  });
}

/// Bir gün için tam solunar sonuç: skor, balık derecesi, periyotlar ve faktör
/// dökümü. Bugün ekranı ve takvim ikonları bunu tüketir.
class SolunarDay {
  /// 0–100 iç skor.
  final int score;

  /// 1–5 balık ikonu (renk körlüğü dostu: ikon sayısıyla ifade).
  final int fishRating;

  final List<SolunarPeriod> majorPeriods;
  final List<SolunarPeriod> minorPeriods;

  /// Skorun nasıl oluştuğunun şeffaf dökümü.
  final List<ScoreFactor> factors;

  /// Hava verisi skora dahil edildi mi? (false → yalnız astronomi)
  final bool usedWeather;

  const SolunarDay({
    required this.score,
    required this.fishRating,
    required this.majorPeriods,
    required this.minorPeriods,
    required this.factors,
    required this.usedWeather,
  });

  /// Bugünün tüm periyotları, zamana göre sıralı.
  List<SolunarPeriod> get allPeriods {
    final all = [...majorPeriods, ...minorPeriods];
    all.sort((a, b) => a.start.compareTo(b.start));
    return all;
  }

  /// [now]'dan sonraki ilk periyodun başlangıcı (geri sayım için), yoksa null.
  SolunarPeriod? nextPeriodAfter(DateTime now) {
    for (final p in allPeriods) {
      if (p.start.isAfter(now)) return p;
    }
    return null;
  }
}
