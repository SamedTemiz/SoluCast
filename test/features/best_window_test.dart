import 'package:flutter_test/flutter_test.dart';
import 'package:angler_pulse/core/core.dart';
import 'package:angler_pulse/data/location/saved_location.dart';
import 'package:angler_pulse/features/best_window/best_window_finder.dart';

void main() {
  const istanbul = SavedLocation(
    name: 'İstanbul',
    latitude: 41.0082,
    longitude: 28.9784,
    timeZoneId: 'Europe/Istanbul',
  );
  const sapanca = SavedLocation(
    name: 'Sapanca',
    latitude: 40.6883,
    longitude: 30.2675,
    timeZoneId: 'Europe/Istanbul',
  );

  SolunarPeriod major(DateTime startUtc, {bool twilight = false}) =>
      SolunarPeriod(
        type: SolunarPeriodType.major,
        kind: SolunarPeriodKind.upperTransit,
        start: startUtc,
        peak: startUtc.add(const Duration(hours: 1)),
        end: startUtc.add(const Duration(hours: 2)),
        overlapsTwilight: twilight,
      );

  SolunarDay day(int score, List<SolunarPeriod> majors) => SolunarDay(
    score: score,
    fishRating: (score / 20).ceil().clamp(1, 5),
    majorPeriods: majors,
    minorPeriods: const [],
    factors: const [],
    usedWeather: false,
  );

  final nowUtc = DateTime.utc(2026, 7, 20, 12); // öğlen

  BestWindowInput entry(
    SavedLocation location,
    DateTime localDate,
    SolunarDay solunarDay,
  ) => (
    location: location,
    localDate: localDate,
    day: solunarDay,
    utcOffset: const Duration(hours: 3),
  );

  group('bestUpcomingMajor', () {
    test('geçmiş pencereyi atlar, yaklaşanı seçer', () {
      final d = day(80, [
        major(DateTime.utc(2026, 7, 20, 4)), // bitti (06:00 UTC < now)
        major(DateTime.utc(2026, 7, 20, 16)),
      ]);
      expect(bestUpcomingMajor(d, nowUtc)!.start.hour, 16);
    });

    test('alacakaranlıkla çakışan pencereyi tercih eder', () {
      final d = day(80, [
        major(DateTime.utc(2026, 7, 21, 2)),
        major(DateTime.utc(2026, 7, 21, 16), twilight: true),
      ]);
      expect(bestUpcomingMajor(d, nowUtc)!.overlapsTwilight, isTrue);
    });

    test('tüm pencereler geçmişse null döner', () {
      final d = day(80, [major(DateTime.utc(2026, 7, 20, 2))]);
      expect(bestUpcomingMajor(d, nowUtc), isNull);
    });
  });

  group('findBestWindows', () {
    test('skora göre sıralar, eşitlikte erken tarih önce gelir', () {
      final result = findBestWindows(
        entries: [
          entry(
            istanbul,
            DateTime(2026, 7, 21),
            day(60, [major(DateTime.utc(2026, 7, 21, 5))]),
          ),
          entry(
            istanbul,
            DateTime(2026, 7, 23),
            day(85, [major(DateTime.utc(2026, 7, 23, 5))]),
          ),
          entry(
            istanbul,
            DateTime(2026, 7, 25),
            day(85, [major(DateTime.utc(2026, 7, 25, 5))]),
          ),
        ],
        nowUtc: nowUtc,
      );

      expect(result, hasLength(3));
      expect(result[0].day.score, 85);
      expect(result[0].localDate, DateTime(2026, 7, 23)); // eşitlikte erken
      expect(result[1].localDate, DateTime(2026, 7, 25));
      expect(result[2].day.score, 60);
    });

    test('aynı güne düşen konumlardan yüksek skorlusu kalır', () {
      final date = DateTime(2026, 7, 22);
      final result = findBestWindows(
        entries: [
          entry(istanbul, date, day(55, [major(DateTime.utc(2026, 7, 22, 5))])),
          entry(sapanca, date, day(78, [major(DateTime.utc(2026, 7, 22, 6))])),
        ],
        nowUtc: nowUtc,
      );

      expect(result, hasLength(1));
      expect(result.single.location, sapanca);
    });

    test('bugünün tüm pencereleri geçmişse bugün listeye girmez', () {
      final result = findBestWindows(
        entries: [
          entry(
            istanbul,
            DateTime(2026, 7, 20),
            day(95, [major(DateTime.utc(2026, 7, 20, 2))]), // geçti
          ),
          entry(
            istanbul,
            DateTime(2026, 7, 21),
            day(40, [major(DateTime.utc(2026, 7, 21, 5))]),
          ),
        ],
        nowUtc: nowUtc,
      );

      expect(result, hasLength(1));
      expect(result.single.localDate, DateTime(2026, 7, 21));
    });

    test('take sınırı uygulanır ve boş girdi boş liste döner', () {
      expect(findBestWindows(entries: const [], nowUtc: nowUtc), isEmpty);

      final many = findBestWindows(
        entries: [
          for (var i = 1; i <= 6; i++)
            entry(
              istanbul,
              DateTime(2026, 7, 20 + i),
              day(50 + i, [major(DateTime.utc(2026, 7, 20 + i, 5))]),
            ),
        ],
        nowUtc: nowUtc,
      );
      expect(many, hasLength(3));
      expect(many.first.day.score, 56); // en yüksek skor başta
    });
  });
}
