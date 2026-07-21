import '../../core/solunar/solunar_day.dart';
import '../../data/location/saved_location.dart';

/// A ranked, explainable comparison of saved fishing spots for one date.
///
/// The calculation intentionally consumes the same final [SolunarDay] value
/// shown elsewhere in the app. That keeps the comparison honest: it never
/// invents a second scoring system just to create a ranking.
class SpotComparison {
  const SpotComparison._(this.entries);

  final List<SpotComparisonEntry> entries;

  factory SpotComparison.fromDays(
    Iterable<({SavedLocation location, SolunarDay day, Duration utcOffset})>
    days,
  ) {
    final entries = [
      for (final value in days)
        SpotComparisonEntry(
          location: value.location,
          day: value.day,
          utcOffset: value.utcOffset,
        ),
    ]..sort((a, b) => b.day.score.compareTo(a.day.score));
    return SpotComparison._(List.unmodifiable(entries));
  }

  SpotComparisonEntry? get best => entries.isEmpty ? null : entries.first;

  /// Point lead of the winner over the runner-up, if a comparison is possible.
  int? get lead {
    if (entries.length < 2) return null;
    return entries.first.day.score - entries[1].day.score;
  }

  /// The factor that most explains why [best] is ahead of the runner-up.
  /// A null result means the two scores are tied or their factor sets differ.
  SpotComparisonFactorDifference? get strongestAdvantage {
    if (entries.length < 2) return null;
    final winner = entries[0].day;
    final runnerUp = entries[1].day;
    final runnerUpByKey = {
      for (final factor in runnerUp.factors) factor.key: factor,
    };

    SpotComparisonFactorDifference? strongest;
    for (final factor in winner.factors) {
      final other = runnerUpByKey[factor.key];
      if (other == null) continue;
      final difference = factor.contribution - other.contribution;
      if (difference <= 0) continue;
      if (strongest == null || difference > strongest.points) {
        strongest = SpotComparisonFactorDifference(
          factorKey: factor.key,
          points: difference,
        );
      }
    }
    return strongest;
  }
}

class SpotComparisonEntry {
  const SpotComparisonEntry({
    required this.location,
    required this.day,
    this.utcOffset = Duration.zero,
  });

  final SavedLocation location;
  final SolunarDay day;
  final Duration utcOffset;
}

class SpotComparisonFactorDifference {
  const SpotComparisonFactorDifference({
    required this.factorKey,
    required this.points,
  });

  final String factorKey;
  final double points;

  int get roundedPoints => points.round();
}
