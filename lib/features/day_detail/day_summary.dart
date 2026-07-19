import '../../core/core.dart';

/// Skor faktörlerinden tek cümlelik özet üretir (Stitch hero kart açıklaması).
/// Uydurma değil — en yüksek katkılı 1-2 gerçek faktörden inşa edilir.
String buildDaySummary(
  SolunarDay day,
  DayEphemeris ephemeris, {
  bool turkish = false,
}) {
  final sorted = [...day.factors]
    ..sort((a, b) => b.contribution.compareTo(a.contribution));
  final top = sorted.take(2).where((f) => f.contribution > 5).toList();

  if (top.isEmpty) {
    return turkish
        ? 'Sakin bir gün — güçlü solunar veya alacakaranlık sinyalleri çakışmıyor.'
        : 'A quiet day — no strong solunar or twilight signals line up.';
  }

  final phrases = top.map((f) => _phrase(f, ephemeris, turkish)).toList();
  final joined = phrases.length == 1
      ? phrases.first
      : '${phrases.first}${turkish ? ' ve ' : ' and '}${phrases[1]}';

  final verb = turkish
      ? (day.fishRating >= 4
            ? 'bugünü balıkçılık için harika kılıyor'
            : 'bugünün koşullarını şekillendiriyor')
      : (day.fishRating >= 4
            ? 'make today a great day to fish'
            : 'shape today\'s conditions');
  return '${joined[0].toUpperCase()}${joined.substring(1)} $verb.';
}

String _phrase(ScoreFactor f, DayEphemeris ephemeris, bool turkish) {
  switch (f.key) {
    case 'moon_phase':
      return _moonPhrase(ephemeris.moonPhase, turkish);
    case 'twilight_overlap':
      return turkish
          ? 'şafak veya alacakaranlıkla çakışan ana dönem'
          : 'a major period overlapping dawn or dusk';
    case 'pressure_trend':
      return turkish
          ? 'düşen barometrik basınç eğilimi'
          : 'a falling barometric pressure trend';
    case 'seasonal':
      return turkish
          ? 'bu mevsimdeki uzun gün ışığı süresi'
          : 'long daylight hours this season';
    default:
      return f.key;
  }
}

String _moonPhrase(MoonPhase phase, bool turkish) {
  switch (phase) {
    case MoonPhase.newMoon:
      return turkish ? 'yeni ay' : 'the new moon';
    case MoonPhase.fullMoon:
      return turkish ? 'dolunay' : 'the full moon';
    case MoonPhase.firstQuarter:
    case MoonPhase.lastQuarter:
      return turkish ? 'dördün evresindeki ay' : 'the quarter moon';
    default:
      return turkish ? 'mevcut ay evresi' : 'the current moon phase';
  }
}
