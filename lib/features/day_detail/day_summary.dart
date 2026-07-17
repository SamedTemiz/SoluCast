import '../../core/core.dart';

/// Skor faktörlerinden tek cümlelik özet üretir (Stitch hero kart açıklaması).
/// Uydurma değil — en yüksek katkılı 1-2 gerçek faktörden inşa edilir.
String buildDaySummary(SolunarDay day, DayEphemeris ephemeris) {
  final sorted = [...day.factors]
    ..sort((a, b) => b.contribution.compareTo(a.contribution));
  final top = sorted.take(2).where((f) => f.contribution > 5).toList();

  if (top.isEmpty) {
    return 'A quiet day — no strong solunar or twilight signals line up.';
  }

  final phrases = top.map((f) => _phrase(f, ephemeris)).toList();
  final joined = phrases.length == 1
      ? phrases.first
      : '${phrases.first} and ${phrases[1]}';

  final verb = day.fishRating >= 4 ? 'make today a great day to fish' : 'shape today\'s conditions';
  return '${joined[0].toUpperCase()}${joined.substring(1)} $verb.';
}

String _phrase(ScoreFactor f, DayEphemeris ephemeris) {
  switch (f.key) {
    case 'moon_phase':
      return _moonPhrase(ephemeris.moonPhase);
    case 'twilight_overlap':
      return 'a major period overlapping dawn or dusk';
    case 'pressure_trend':
      return 'a falling barometric pressure trend';
    case 'seasonal':
      return 'long daylight hours this season';
    default:
      return f.key;
  }
}

String _moonPhrase(MoonPhase phase) {
  switch (phase) {
    case MoonPhase.newMoon:
      return 'the new moon';
    case MoonPhase.fullMoon:
      return 'the full moon';
    case MoonPhase.firstQuarter:
    case MoonPhase.lastQuarter:
      return 'the quarter moon';
    default:
      return 'the current moon phase';
  }
}
