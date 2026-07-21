import 'package:angler_pulse/core/core.dart';
import 'package:angler_pulse/data/location/saved_location.dart';
import 'package:angler_pulse/features/spot_compare/spot_comparison.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const istanbul = SavedLocation(
    name: 'Istanbul',
    latitude: 41,
    longitude: 29,
    timeZoneId: 'Europe/Istanbul',
  );
  const miami = SavedLocation(
    name: 'Miami',
    latitude: 26,
    longitude: -80,
    timeZoneId: 'America/New_York',
  );

  SolunarDay day(int score, List<ScoreFactor> factors) => SolunarDay(
    score: score,
    fishRating: 3,
    majorPeriods: const [],
    minorPeriods: const [],
    factors: factors,
    usedWeather: false,
  );

  ScoreFactor factor(String key, double contribution) => ScoreFactor(
    key: key,
    raw: contribution / 100,
    weight: 1,
    contribution: contribution,
  );

  test('ranks spots by their displayed score and reports the lead', () {
    final comparison = SpotComparison.fromDays([
      (
        location: istanbul,
        day: day(46, [factor('moon_phase', 20)]),
        utcOffset: Duration.zero,
      ),
      (
        location: miami,
        day: day(67, [factor('moon_phase', 32)]),
        utcOffset: Duration.zero,
      ),
    ]);

    expect(comparison.best?.location, miami);
    expect(comparison.lead, 21);
  });

  test('explains the greatest positive factor difference for the winner', () {
    final comparison = SpotComparison.fromDays([
      (
        location: istanbul,
        day: day(55, [factor('moon_phase', 24), factor('seasonal', 18)]),
        utcOffset: Duration.zero,
      ),
      (
        location: miami,
        day: day(71, [factor('moon_phase', 36), factor('seasonal', 20)]),
        utcOffset: Duration.zero,
      ),
    ]);

    final advantage = comparison.strongestAdvantage;
    expect(advantage?.factorKey, 'moon_phase');
    expect(advantage?.roundedPoints, 12);
  });

  test('does not claim an advantage for tied spots', () {
    final comparison = SpotComparison.fromDays([
      (
        location: istanbul,
        day: day(55, [factor('moon_phase', 20)]),
        utcOffset: Duration.zero,
      ),
      (
        location: miami,
        day: day(55, [factor('moon_phase', 20)]),
        utcOffset: Duration.zero,
      ),
    ]);

    expect(comparison.lead, 0);
    expect(comparison.strongestAdvantage, isNull);
  });
}
