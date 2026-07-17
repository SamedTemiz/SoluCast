import 'package:flutter_test/flutter_test.dart';
import 'package:solucast/core/core.dart';

void main() {
  const engine = SolunarEngine();

  DayEphemeris eph({
    List<DateTime> upperTransits = const [],
    List<DateTime> moonrises = const [],
  }) {
    return DayEphemeris(
      localDate: DateTime.utc(2026, 6, 21),
      utcOffset: Duration.zero,
      position: const GeoPosition(latitude: 40, longitude: 0),
      sunrise: null,
      sunset: null,
      solarNoon: null,
      civilDawn: null,
      civilDusk: null,
      astronomicalDawn: null,
      astronomicalDusk: null,
      moonrises: moonrises,
      moonsets: const [],
      moonUpperTransits: upperTransits,
      moonLowerTransits: const [],
      moonIllumination: 0.5,
      moonAgeFraction: 0.5,
      moonPhase: MoonPhase.fullMoon,
    );
  }

  test('eğri 25 örnek döner ve [0,1] aralığında kalır', () {
    final day = engine.evaluate(eph(upperTransits: [DateTime.utc(2026, 6, 21, 12)]));
    final curve = hourlyActivityCurve(day);
    expect(curve, hasLength(25));
    for (final v in curve) {
      expect(v, inInclusiveRange(0.0, 1.0));
    }
  });

  test('major periyot tepesinde eğri belirgin şekilde yükselir', () {
    final peak = DateTime.utc(2026, 6, 21, 12);
    final day = engine.evaluate(eph(upperTransits: [peak]));
    final curve = hourlyActivityCurve(day);
    // 25 örnek, 24/24 saat aralığı → index 12 tam öğlen (peak).
    final atPeak = curve[12];
    final farFromPeak = curve[0]; // gece yarısı
    expect(atPeak, greaterThan(farFromPeak));
    expect(atPeak, greaterThan(0.5));
  });

  test('periyot yokken eğri düz taban seviyesinde kalır', () {
    final day = engine.evaluate(eph());
    final curve = hourlyActivityCurve(day);
    for (final v in curve) {
      expect(v, closeTo(0.08, 1e-9));
    }
  });

  test('gün sınırını dolanan tepe (23:xx) sarma ile doğru işlenir', () {
    final peak = DateTime.utc(2026, 6, 21, 23, 45);
    final day = engine.evaluate(eph(upperTransits: [peak]));
    final curve = hourlyActivityCurve(day);
    // Son örnek (24:00 ≈ 00:00) tepeye yakın olmalı, tabana değil.
    expect(curve.last, greaterThan(0.3));
  });
}
