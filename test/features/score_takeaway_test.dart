import 'package:flutter_test/flutter_test.dart';
import 'package:angler_pulse/core/core.dart';
import 'package:angler_pulse/features/shared/score_explanation_sheet.dart';
import 'package:angler_pulse/features/today/today_format.dart';

void main() {
  final fmt = TodayFormat(const Duration(hours: 3)); // UTC+3, 24h

  DayEphemeris ephemeris({DateTime? solarNoon}) => DayEphemeris(
    localDate: DateTime(2026, 7, 20),
    utcOffset: const Duration(hours: 3),
    position: const GeoPosition(latitude: 41, longitude: 29),
    sunrise: DateTime.utc(2026, 7, 20, 2, 30),
    sunset: DateTime.utc(2026, 7, 20, 17, 30),
    solarNoon: solarNoon ?? DateTime.utc(2026, 7, 20, 10),
    civilDawn: DateTime.utc(2026, 7, 20, 2),
    civilDusk: DateTime.utc(2026, 7, 20, 18),
    astronomicalDawn: null,
    astronomicalDusk: null,
    moonrises: const [],
    moonsets: const [],
    moonUpperTransits: const [],
    moonLowerTransits: const [],
    moonIllumination: 0.5,
    moonAgeFraction: 0.2,
    moonPhase: MoonPhase.firstQuarter,
  );

  SolunarPeriod major(
    DateTime startUtc, {
    bool twilight = false,
  }) => SolunarPeriod(
    type: SolunarPeriodType.major,
    kind: SolunarPeriodKind.upperTransit,
    start: startUtc,
    peak: startUtc.add(const Duration(hours: 1)),
    end: startUtc.add(const Duration(hours: 2)),
    overlapsTwilight: twilight,
  );

  SolunarDay day(List<SolunarPeriod> majors) => SolunarDay(
    score: 70,
    fishRating: 4,
    majorPeriods: majors,
    minorPeriods: const [],
    factors: const [],
    usedWeather: false,
  );

  test('prime pencere sabahtaysa şafak çıkarımı verir', () {
    // peak 03:30 UTC < solarNoon 10:00 → dawn.
    final d = day([major(DateTime.utc(2026, 7, 20, 2, 30), twilight: true)]);
    final text = buildScoreTakeaway(d, ephemeris(), fmt);
    expect(text, contains('dawn'));
    expect(text, contains('05:30')); // 02:30 UTC +3
  });

  test('prime pencere akşamdaysa alacakaranlık çıkarımı verir', () {
    // peak 16:30 UTC > solarNoon 10:00 → dusk.
    final d = day([major(DateTime.utc(2026, 7, 20, 15, 30), twilight: true)]);
    final text = buildScoreTakeaway(d, ephemeris(), fmt);
    expect(text, contains('dusk'));
  });

  test('twilight çakışması yoksa esnek zamanlama çıkarımı verir', () {
    final d = day([major(DateTime.utc(2026, 7, 20, 8))]);
    final text = buildScoreTakeaway(d, ephemeris(), fmt);
    expect(text, contains('flexible'));
  });

  test('major yoksa yalnız minor çıkarımı verir', () {
    final d = day(const []);
    final text = buildScoreTakeaway(d, ephemeris(), fmt);
    expect(text.toLowerCase(), contains('minor'));
  });

  test('Türkçe çıkarım da üretilir', () {
    final d = day([major(DateTime.utc(2026, 7, 20, 2, 30), twilight: true)]);
    final text = buildScoreTakeaway(d, ephemeris(), fmt, turkish: true);
    expect(text, contains('şafakla'));
  });
}
