import 'package:flutter_test/flutter_test.dart';
import 'package:solucast/core/astro/day_ephemeris.dart';
import 'package:solucast/core/astro/geo_position.dart';
import 'package:solucast/core/solunar/solunar_engine.dart';
import 'package:solucast/core/solunar/solunar_period.dart';
import 'package:solucast/core/solunar/weather_input.dart';

/// Sabit bir efemeris fixture'ı — solunar motoru astronomiden bağımsız,
/// deterministik test edilir.
DayEphemeris _eph({
  List<DateTime> upperTransits = const [],
  List<DateTime> lowerTransits = const [],
  List<DateTime> moonrises = const [],
  List<DateTime> moonsets = const [],
  DateTime? sunrise,
  DateTime? sunset,
  DateTime? civilDawn,
  DateTime? civilDusk,
  double age = 0.0,
  double illum = 0.0,
}) {
  return DayEphemeris(
    localDate: DateTime.utc(2026, 6, 21),
    utcOffset: Duration.zero,
    position: const GeoPosition(latitude: 40, longitude: 0),
    sunrise: sunrise,
    sunset: sunset,
    solarNoon: DateTime.utc(2026, 6, 21, 12),
    civilDawn: civilDawn,
    civilDusk: civilDusk,
    astronomicalDawn: null,
    astronomicalDusk: null,
    moonrises: moonrises,
    moonsets: moonsets,
    moonUpperTransits: upperTransits,
    moonLowerTransits: lowerTransits,
    moonIllumination: illum,
    moonAgeFraction: age,
    moonPhase: MoonPhase.newMoon,
  );
}

double _raw(dynamic day, String key) =>
    day.factors.firstWhere((f) => f.key == key).raw as double;

void main() {
  const engine = SolunarEngine();
  final t = DateTime.utc(2026, 6, 21, 15); // referans an

  group('Periyot üretimi', () {
    test('major periyot transitten ±60 dk üretilir', () {
      final day = engine.evaluate(_eph(upperTransits: [t]));
      expect(day.majorPeriods, hasLength(1));
      final p = day.majorPeriods.first;
      expect(p.type, SolunarPeriodType.major);
      expect(p.peak, t);
      expect(p.start, t.subtract(const Duration(minutes: 60)));
      expect(p.end, t.add(const Duration(minutes: 60)));
    });

    test('minor periyot doğuş/batıştan ±30 dk üretilir', () {
      final day = engine.evaluate(_eph(moonrises: [t], moonsets: [
        t.add(const Duration(hours: 6))
      ]));
      expect(day.minorPeriods, hasLength(2));
      final p = day.minorPeriods.first;
      expect(p.type, SolunarPeriodType.minor);
      expect(p.duration, const Duration(minutes: 60));
    });

    test('üst + alt transit → 2 major periyot', () {
      final day = engine.evaluate(_eph(
        upperTransits: [t],
        lowerTransits: [t.add(const Duration(hours: 12))],
      ));
      expect(day.majorPeriods, hasLength(2));
    });

    test('kutup günü: ay doğmaz/batmaz → minor boş, major transitten üretilir',
        () {
      final day = engine.evaluate(_eph(
        upperTransits: [t],
        lowerTransits: [t.add(const Duration(hours: 12))],
        moonrises: const [],
        moonsets: const [],
      ));
      expect(day.minorPeriods, isEmpty);
      expect(day.majorPeriods, hasLength(2));
    });
  });

  group('Ay fazı faktörü (yeni/dolunay pik)', () {
    test('yeni ay (age~0) → ~1.0', () {
      expect(_raw(engine.evaluate(_eph(age: 0.0)), 'moon_phase'),
          closeTo(1.0, 0.01));
    });
    test('dolunay (age 0.5) → ~1.0', () {
      expect(_raw(engine.evaluate(_eph(age: 0.5)), 'moon_phase'),
          closeTo(1.0, 0.01));
    });
    test('ilk dördün (age 0.25) → ~0.0', () {
      expect(_raw(engine.evaluate(_eph(age: 0.25)), 'moon_phase'),
          closeTo(0.0, 0.01));
    });
    test('hilal (age 0.125) → ~0.5', () {
      expect(_raw(engine.evaluate(_eph(age: 0.125)), 'moon_phase'),
          closeTo(0.5, 0.01));
    });
  });

  group('Hava verisi ağırlık dağıtımı (F3.4)', () {
    test('hava yok → pressure faktörü listede yok, usedWeather false', () {
      final day = engine.evaluate(_eph(age: 0.0));
      expect(day.usedWeather, isFalse);
      expect(day.factors.any((f) => f.key == 'pressure_trend'), isFalse);
    });

    test('hava yok → basınç ağırlığı diğerlerine dağıtılır (toplam korunur)',
        () {
      final day = engine.evaluate(_eph(age: 0.0));
      final total = day.factors.fold<double>(0, (s, f) => s + f.weight);
      expect(total, closeTo(1.0, 1e-9));
      // moon_phase ağırlığı 0.35 → 0.35/0.80 = 0.4375'e yükselir.
      final mp = day.factors.firstWhere((f) => f.key == 'moon_phase');
      expect(mp.weight, closeTo(0.4375, 1e-6));
    });

    test('hava var → pressure faktörü dahil, usedWeather true', () {
      final day = engine.evaluate(_eph(age: 0.0),
          weather: const WeatherInput(trend: PressureTrend.falling));
      expect(day.usedWeather, isTrue);
      final p = day.factors.firstWhere((f) => f.key == 'pressure_trend');
      expect(p.raw, closeTo(0.8, 1e-9));
      expect(p.weight, closeTo(0.20, 1e-9));
    });

    test('düşen basınç yükselen basınçtan daha yüksek skor verir', () {
      final base = _eph(age: 0.25); // faz nötr, fark hava kaynaklı
      final falling = engine.evaluate(base,
          weather: const WeatherInput(trend: PressureTrend.fallingFast));
      final rising = engine.evaluate(base,
          weather: const WeatherInput(trend: PressureTrend.risingFast));
      expect(falling.score, greaterThan(rising.score));
    });
  });

  group('Alacakaranlık çakışması', () {
    test('şafakla çakışan major → overlap işaretli ve faktör yüksek', () {
      final dawn = DateTime.utc(2026, 6, 21, 5, 30);
      final day = engine.evaluate(_eph(
        upperTransits: [dawn], // periyot 04:30–06:30, şafak penceresiyle çakışır
        sunrise: dawn,
        civilDawn: dawn.subtract(const Duration(minutes: 30)),
      ));
      expect(day.majorPeriods.first.overlapsTwilight, isTrue);
      expect(_raw(day, 'twilight_overlap'), greaterThanOrEqualTo(0.5));
    });

    test('gece yarısı major → çakışma yok', () {
      final midnight = DateTime.utc(2026, 6, 21, 0, 30);
      final day = engine.evaluate(_eph(
        upperTransits: [midnight],
        sunrise: DateTime.utc(2026, 6, 21, 5, 30),
        sunset: DateTime.utc(2026, 6, 21, 20, 30),
      ));
      expect(day.majorPeriods.first.overlapsTwilight, isFalse);
      expect(_raw(day, 'twilight_overlap'), 0.0);
    });
  });

  group('Balık derecesi eşikleri', () {
    test('skor arttıkça derece monoton artar', () {
      // Yeni ay + çift major şafak/akşam çakışması + düşen basınç → yüksek
      final high = engine.evaluate(
        _eph(
          age: 0.0,
          upperTransits: [DateTime.utc(2026, 6, 21, 5, 30)],
          lowerTransits: [DateTime.utc(2026, 6, 21, 20, 0)],
          sunrise: DateTime.utc(2026, 6, 21, 5, 30),
          sunset: DateTime.utc(2026, 6, 21, 20, 30),
          civilDawn: DateTime.utc(2026, 6, 21, 5, 0),
          civilDusk: DateTime.utc(2026, 6, 21, 21, 0),
        ),
        weather: const WeatherInput(trend: PressureTrend.fallingFast),
      );
      final low = engine.evaluate(_eph(age: 0.25));
      expect(high.score, greaterThan(low.score));
      expect(high.fishRating, greaterThanOrEqualTo(low.fishRating));
      expect(high.fishRating, inInclusiveRange(1, 5));
      expect(low.fishRating, inInclusiveRange(1, 5));
    });
  });

  group('nextPeriodAfter', () {
    test('verilen andan sonraki ilk periyodu döndürür', () {
      final day = engine.evaluate(_eph(
        upperTransits: [DateTime.utc(2026, 6, 21, 10)],
        lowerTransits: [DateTime.utc(2026, 6, 21, 22)],
      ));
      final next = day.nextPeriodAfter(DateTime.utc(2026, 6, 21, 12));
      expect(next, isNotNull);
      expect(next!.peak, DateTime.utc(2026, 6, 21, 22));
    });
  });
}
