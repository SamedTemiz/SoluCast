import 'geo_position.dart';

/// Ay fazının kaba adlandırması (UI + skor için).
enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

/// Bir gözlemci konumu ve yerel takvim günü için hesaplanmış tüm astronomik
/// olaylar. Tüm zaman damgaları **UTC** `DateTime`'dır; UI, konumun
/// [utcOffset]'i ile yerel saate çevirir.
///
/// Kutup/yüksek enlemde bir olay o gün gerçekleşmeyebilir → ilgili alan `null`
/// (ör. "no moonrise today"). Motorun kalesi budur: internet olmadan, sınırsız
/// ileri tarih için deterministik üretilir.
class DayEphemeris {
  /// Hesabın yapıldığı yerel takvim tarihi (yıl-ay-gün; saat bileşeni anlamsız).
  final DateTime localDate;

  /// Konumun bu gün için UTC ofseti (DST dahil). Çağıran (data katmanı) verir.
  final Duration utcOffset;

  final GeoPosition position;

  // --- Güneş ---
  final DateTime? sunrise;
  final DateTime? sunset;

  /// Güneşin üst meridyen geçişi (gerçek öğle). Kutup gecesinde bile en yüksek
  /// nokta olarak tanımlıdır; pencere içinde yoksa `null`.
  final DateTime? solarNoon;

  /// Sivil alacakaranlık (güneş merkezi -6°): şafak / akşam.
  final DateTime? civilDawn;
  final DateTime? civilDusk;

  /// Astronomik alacakaranlık (-18°): gece balıkçılığı bonusu için.
  final DateTime? astronomicalDawn;
  final DateTime? astronomicalDusk;

  // --- Ay ---
  /// O yerel gün içindeki ay doğuşları (0, 1, nadiren 2).
  final List<DateTime> moonrises;

  /// O yerel gün içindeki ay batışları (0, 1, nadiren 2).
  final List<DateTime> moonsets;

  /// Ayın üst meridyen geçişleri (major periyot merkezleri — tepede).
  final List<DateTime> moonUpperTransits;

  /// Ayın alt meridyen geçişleri (major periyot merkezleri — ayak altında).
  final List<DateTime> moonLowerTransits;

  /// Aydınlanma oranı [0..1] (yerel öğlen anında). 0 = yeni ay, 1 = dolunay.
  final double moonIllumination;

  /// Sinodik faz kesri [0..1). 0 = yeni ay, 0.5 = dolunay. Yön (artan/azalan)
  /// bu değerden okunur: <0.5 artan (waxing), >0.5 azalan (waning).
  final double moonAgeFraction;

  final MoonPhase moonPhase;

  const DayEphemeris({
    required this.localDate,
    required this.utcOffset,
    required this.position,
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.civilDawn,
    required this.civilDusk,
    required this.astronomicalDawn,
    required this.astronomicalDusk,
    required this.moonrises,
    required this.moonsets,
    required this.moonUpperTransits,
    required this.moonLowerTransits,
    required this.moonIllumination,
    required this.moonAgeFraction,
    required this.moonPhase,
  });

  bool get moonRisesToday => moonrises.isNotEmpty;
  bool get moonSetsToday => moonsets.isNotEmpty;
}
