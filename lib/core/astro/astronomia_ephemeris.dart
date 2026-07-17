import 'dart:math' as math;

import 'package:astronomia/coord.dart' as coord;
import 'package:astronomia/deltat.dart' as deltat;
import 'package:astronomia/moonillum.dart' as moonillum;
import 'package:astronomia/moonposition.dart' as moonpos;
import 'package:astronomia/nutation.dart' as nutation;
import 'package:astronomia/sidereal.dart' as sidereal;
import 'package:astronomia/solar.dart' as solar;

import 'day_ephemeris.dart';
import 'ephemeris_source.dart';
import 'geo_position.dart';

const double _deg2rad = math.pi / 180.0;
const double _twoPi = 2 * math.pi;

/// Unix epoch'un (1970-01-01T00:00Z) Julian Günü.
const double _jdUnixEpoch = 2440587.5;

/// Standart yükseklikler (radyan). Meeus/USNO gelenekleri.
const double _h0Sun = -0.8333 * _deg2rad; // kırılma + güneş yarıçapı
const double _h0Civil = -6.0 * _deg2rad;
const double _h0Astro = -18.0 * _deg2rad;

/// Efemeris kaynağının Meeus ([astronomia]) tabanlı uygulaması.
///
/// Rakiplerin "saatler yanlış" şikâyetinin kökü yanlış zaman-dilimi ve kaba
/// algoritmalardır. Burada olaylar UTC'de deterministik bulunur; yerel güne
/// bucketleme [utcOffset] ile yapılır. Doğruluk USNO snapshot'larıyla korunur.
class AstronomiaEphemeris implements EphemerisSource {
  /// Yükseklik/meridyen taramasında kaba adım (saniye). 5 dk; tek bir ufuk
  /// geçişini kaçırmayacak kadar sık, ay için bile güvenli.
  final int coarseStepSeconds;

  const AstronomiaEphemeris({this.coarseStepSeconds = 300});

  @override
  DayEphemeris computeDay({
    required int year,
    required int month,
    required int day,
    required GeoPosition position,
    required Duration utcOffset,
  }) {
    // Yerel gün penceresi → UTC. Yerel gece yarısı UTC = utc(midnight) - offset.
    final localMidnightUtc =
        DateTime.utc(year, month, day).subtract(utcOffset);
    final windowStartJd = _jdFromUtc(localMidnightUtc);
    final windowEndJd = windowStartJd + 1.0; // 24 saat

    final latRad = position.latitude * _deg2rad;
    final lonEastRad = position.longitude * _deg2rad;

    // --- Güneş olayları ---
    double sunAlt(double jdUt) {
      final eq = solar.apparentEquatorial(_jde(jdUt));
      return _altitude(eq.ra, eq.dec, jdUt, latRad, lonEastRad);
    }

    final sunrises = _findAltitudeCrossings(
        sunAlt, windowStartJd, windowEndJd, _h0Sun, rising: true);
    final sunsets = _findAltitudeCrossings(
        sunAlt, windowStartJd, windowEndJd, _h0Sun, rising: false);
    final civilDawns = _findAltitudeCrossings(
        sunAlt, windowStartJd, windowEndJd, _h0Civil, rising: true);
    final civilDusks = _findAltitudeCrossings(
        sunAlt, windowStartJd, windowEndJd, _h0Civil, rising: false);
    final astroDawns = _findAltitudeCrossings(
        sunAlt, windowStartJd, windowEndJd, _h0Astro, rising: true);
    final astroDusks = _findAltitudeCrossings(
        sunAlt, windowStartJd, windowEndJd, _h0Astro, rising: false);

    double sunHourAngle(double jdUt) {
      final eq = solar.apparentEquatorial(_jde(jdUt));
      return _hourAngle(eq.ra, jdUt, lonEastRad);
    }

    final solarNoons = _findMeridianCrossings(
        sunHourAngle, windowStartJd, windowEndJd, upper: true);

    // --- Ay olayları ---
    double moonAlt(double jdUt) {
      final eq = _moonEquatorial(_jde(jdUt));
      return _altitude(eq.ra, eq.dec, jdUt, latRad, lonEastRad);
    }

    // Ay için ufuk yüksekliği mesafeye (paralaksa) bağlı: h0 = 0.7275·π − 34'.
    double moonH0(double jdUt) {
      final dist = _moonEquatorial(_jde(jdUt)).distanceKm;
      final parallax = math.asin(6378.14 / dist);
      return 0.7275 * parallax - (34.0 / 60.0) * _deg2rad;
    }

    final moonrises = _findAltitudeCrossingsDynamic(
        moonAlt, moonH0, windowStartJd, windowEndJd, rising: true);
    final moonsets = _findAltitudeCrossingsDynamic(
        moonAlt, moonH0, windowStartJd, windowEndJd, rising: false);

    double moonHourAngle(double jdUt) {
      final eq = _moonEquatorial(_jde(jdUt));
      return _hourAngle(eq.ra, jdUt, lonEastRad);
    }

    final moonUpperTransits = _findMeridianCrossings(
        moonHourAngle, windowStartJd, windowEndJd, upper: true);
    final moonLowerTransits = _findMeridianCrossings(
        moonHourAngle, windowStartJd, windowEndJd, upper: false);

    // --- Ay fazı / aydınlanma (yerel öğlen anında) ---
    final noonUtc = localMidnightUtc.add(const Duration(hours: 12));
    final noonJde = _jde(_jdFromUtc(noonUtc));
    final phaseAngle = moonillum.phaseAngle3(noonJde); // radyan
    final illum = moonillum.illuminated(phaseAngle); // [0..1]
    final ageFraction = _moonAgeFraction(noonJde);

    return DayEphemeris(
      localDate: DateTime.utc(year, month, day),
      utcOffset: utcOffset,
      position: position,
      sunrise: _firstOrNull(sunrises),
      sunset: _firstOrNull(sunsets),
      solarNoon: _firstOrNull(solarNoons),
      civilDawn: _firstOrNull(civilDawns),
      civilDusk: _firstOrNull(civilDusks),
      astronomicalDawn: _firstOrNull(astroDawns),
      astronomicalDusk: _firstOrNull(astroDusks),
      moonrises: moonrises,
      moonsets: moonsets,
      moonUpperTransits: moonUpperTransits,
      moonLowerTransits: moonLowerTransits,
      moonIllumination: illum,
      moonAgeFraction: ageFraction,
      moonPhase: _phaseFromAge(ageFraction),
    );
  }

  // ---------------------------------------------------------------------------
  // Astronomi yardımcıları
  // ---------------------------------------------------------------------------

  /// UT Julian Günü → JDE (TD). ΔT ~ 69 sn (2026); gün içinde sabit sayılır.
  double _jde(double jdUt) {
    final year = _jdToCalendarYear(jdUt);
    final dt = year >= 2000
        ? deltat.polyAfter2000(year.toDouble())
        : deltat.poly1900to1997(jdUt);
    return jdUt + dt / 86400.0;
  }

  /// Ayın görünür ekvatoral koordinatları (RA, Dec radyan) + mesafe (km).
  ({double ra, double dec, double distanceKm}) _moonEquatorial(double jde) {
    final p = moonpos.position(jde); // ekliptik lon/lat (rad), delta (km)
    final eps = nutation.meanObliquity(jde);
    final eq = coord.eclToEq(p.lon, p.lat, math.sin(eps), math.cos(eps));
    return (ra: eq.ra, dec: eq.dec, distanceKm: p.delta);
  }

  /// Verilen UT anında bir cismin ufuk yüksekliği (radyan).
  double _altitude(
      double ra, double dec, double jdUt, double latRad, double lonEastRad) {
    final gast = sidereal.apparent(jdUt) * (_twoPi / 86400.0); // radyan
    final lst = gast + lonEastRad; // doğu-pozitif yerel yıldız zamanı
    final h = lst - ra; // saat açısı
    return math.asin(math.sin(latRad) * math.sin(dec) +
        math.cos(latRad) * math.cos(dec) * math.cos(h));
  }

  /// Cismin saat açısı [-π, π] (0 = üst meridyen, ±π = alt meridyen).
  double _hourAngle(double ra, double jdUt, double lonEastRad) {
    final gast = sidereal.apparent(jdUt) * (_twoPi / 86400.0);
    final lst = gast + lonEastRad;
    return _wrapPi(lst - ra);
  }

  /// Sinodik faz kesri [0..1). 0 = yeni ay, 0.5 = dolunay.
  double _moonAgeFraction(double jde) {
    // Güneş-ay ekliptik boylam farkı → sinodik faz.
    final moon = moonpos.position(jde);
    final sunEq = solar.apparentEquatorial(jde);
    // Güneşin ekliptik boylamı: ekvatoralden geri çevirmek yerine trueSun daha
    // basit ama apparentEquatorial elimizde; boylamı yaklaşık türet:
    final eps = nutation.meanObliquity(jde);
    final sunLon = math.atan2(
        math.sin(sunEq.ra) * math.cos(eps) +
            math.tan(sunEq.dec) * math.sin(eps),
        math.cos(sunEq.ra));
    final elong = _wrap2pi(moon.lon - sunLon);
    return elong / _twoPi;
  }

  // ---------------------------------------------------------------------------
  // Kök bulma (ufuk geçişi + meridyen geçişi)
  // ---------------------------------------------------------------------------

  /// Sabit hedef yükseklikli (güneş) ufuk geçişlerini bulur.
  List<DateTime> _findAltitudeCrossings(
    double Function(double jdUt) altFn,
    double startJd,
    double endJd,
    double targetAlt, {
    required bool rising,
  }) {
    return _findAltitudeCrossingsDynamic(
        altFn, (_) => targetAlt, startJd, endJd, rising: rising);
  }

  /// Hedef yüksekliği ana göre değişen (ay, paralaks) ufuk geçişleri.
  ///
  /// [rising] true → yükseklik yukarı geçer (doğuş); false → aşağı (batış).
  List<DateTime> _findAltitudeCrossingsDynamic(
    double Function(double jdUt) altFn,
    double Function(double jdUt) targetFn,
    double startJd,
    double endJd, {
    required bool rising,
  }) {
    final step = coarseStepSeconds / 86400.0;
    final results = <DateTime>[];
    double prevJd = startJd;
    double prevF = altFn(prevJd) - targetFn(prevJd);

    for (double t = startJd + step; t <= endJd + 1e-9; t += step) {
      final f = altFn(t) - targetFn(t);
      final crosses = rising ? (prevF < 0 && f >= 0) : (prevF > 0 && f <= 0);
      if (crosses) {
        final root = _bisect(
            (x) => altFn(x) - targetFn(x), prevJd, t, prevF < 0);
        results.add(_utcFromJd(root));
      }
      prevJd = t;
      prevF = f;
    }
    return results;
  }

  /// Meridyen geçişleri. [upper] true → üst geçiş (saat açısı 0), false → alt
  /// geçiş (saat açısı ±π).
  List<DateTime> _findMeridianCrossings(
    double Function(double jdUt) haFn,
    double startJd,
    double endJd, {
    required bool upper,
  }) {
    final step = coarseStepSeconds / 86400.0;
    final results = <DateTime>[];
    final target = upper ? 0.0 : math.pi;

    double prevJd = startJd;
    double prevD = _angleDiff(haFn(prevJd), target);

    for (double t = startJd + step; t <= endJd + 1e-9; t += step) {
      final d = _angleDiff(haFn(t), target);
      // İşaret değişimi + ±π sarma sıçraması olmadığından emin ol (küçük adım).
      final signChange = (prevD < 0 && d >= 0) || (prevD > 0 && d <= 0);
      if (signChange && (prevD - d).abs() < math.pi) {
        final root = _bisect(
            (x) => _angleDiff(haFn(x), target), prevJd, t, prevD < 0);
        results.add(_utcFromJd(root));
      }
      prevJd = t;
      prevD = d;
    }
    return results;
  }

  /// [a] ile [b] arasında f'in kökünü bisection ile bulur (~0.1 sn hassasiyet).
  /// [risingSign] true → f(a)<0<f(b) beklenir.
  double _bisect(double Function(double) f, double a, double b, bool risingSign) {
    double lo = a, hi = b;
    // ~1e-6 gün ≈ 0.09 sn → 40 iterasyon fazlasıyla yeterli.
    for (int i = 0; i < 40; i++) {
      final mid = (lo + hi) / 2;
      final fm = f(mid);
      final positiveOnHi = risingSign ? fm < 0 : fm > 0;
      if (positiveOnHi) {
        lo = mid;
      } else {
        hi = mid;
      }
      if ((hi - lo) < 1e-7) break;
    }
    return (lo + hi) / 2;
  }

  // ---------------------------------------------------------------------------
  // Zaman / açı dönüşümleri
  // ---------------------------------------------------------------------------

  double _jdFromUtc(DateTime utc) =>
      utc.millisecondsSinceEpoch / 86400000.0 + _jdUnixEpoch;

  DateTime _utcFromJd(double jd) => DateTime.fromMillisecondsSinceEpoch(
        ((jd - _jdUnixEpoch) * 86400000.0).round(),
        isUtc: true,
      );

  int _jdToCalendarYear(double jd) => _utcFromJd(jd).year;

  DateTime? _firstOrNull(List<DateTime> list) =>
      list.isEmpty ? null : list.first;

  /// [-π, π] aralığına sarar.
  double _wrapPi(double x) {
    var r = x % _twoPi;
    if (r > math.pi) r -= _twoPi;
    if (r < -math.pi) r += _twoPi;
    return r;
  }

  /// [0, 2π) aralığına sarar.
  double _wrap2pi(double x) {
    var r = x % _twoPi;
    if (r < 0) r += _twoPi;
    return r;
  }

  /// (a − b) farkını [-π, π] aralığında verir.
  double _angleDiff(double a, double b) => _wrapPi(a - b);

  MoonPhase _phaseFromAge(double age) {
    // 8 dilim, her biri 1/8 sinodik ay; sınır bandı ±0.02 ile "tam" fazlar.
    const band = 0.02;
    if (age < band || age > 1 - band) return MoonPhase.newMoon;
    if ((age - 0.25).abs() < band) return MoonPhase.firstQuarter;
    if ((age - 0.5).abs() < band) return MoonPhase.fullMoon;
    if ((age - 0.75).abs() < band) return MoonPhase.lastQuarter;
    if (age < 0.25) return MoonPhase.waxingCrescent;
    if (age < 0.5) return MoonPhase.waxingGibbous;
    if (age < 0.75) return MoonPhase.waningGibbous;
    return MoonPhase.waningCrescent;
  }
}
