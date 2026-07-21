import '../../core/core.dart';
import '../../data/location/saved_location.dart';

/// "Ne zaman gitmeli?" adayı: bir konum + gün + o günün öne çıkan major
/// penceresi. Saf veri — UI biçimlendirmeyi [utcOffset] ile kendisi yapar.
class BestWindow {
  final SavedLocation location;
  final DateTime localDate;
  final SolunarDay day;
  final SolunarPeriod period;
  final Duration utcOffset;

  const BestWindow({
    required this.location,
    required this.localDate,
    required this.day,
    required this.period,
    required this.utcOffset,
  });
}

typedef BestWindowInput = ({
  SavedLocation location,
  DateTime localDate,
  SolunarDay day,
  Duration utcOffset,
});

/// Günün öne çıkan major penceresi: bitmemiş olanlar arasından alacakaranlıkla
/// çakışan ("prime") tercih edilir, yoksa ilk yaklaşan. Hepsi geçtiyse null.
SolunarPeriod? bestUpcomingMajor(SolunarDay day, DateTime nowUtc) {
  final upcoming = day.majorPeriods.where((p) => p.end.isAfter(nowUtc)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  if (upcoming.isEmpty) return null;
  return upcoming.firstWhere(
    (p) => p.overlapsTwilight,
    orElse: () => upcoming.first,
  );
}

/// Tarama sonucunu sıralar: skor azalan, eşitlikte erken tarih önce.
///
/// Aynı takvim gününe birden fazla konum düşerse yalnız en yüksek skorlusu
/// kalır — bu kartın sorusu "ne zaman", "hangi nokta" sorusunun tam
/// karşılaştırması Spot Compare'in işidir.
List<BestWindow> findBestWindows({
  required Iterable<BestWindowInput> entries,
  required DateTime nowUtc,
  int take = 3,
}) {
  // Gün başına en iyi aday (geçmiş pencereli günler elenir).
  final byDate = <int, BestWindow>{};
  for (final entry in entries) {
    final period = bestUpcomingMajor(entry.day, nowUtc);
    if (period == null) continue;
    final key =
        entry.localDate.year * 10000 +
        entry.localDate.month * 100 +
        entry.localDate.day;
    final current = byDate[key];
    if (current == null || entry.day.score > current.day.score) {
      byDate[key] = BestWindow(
        location: entry.location,
        localDate: entry.localDate,
        day: entry.day,
        period: period,
        utcOffset: entry.utcOffset,
      );
    }
  }

  final ranked = byDate.values.toList()
    ..sort((a, b) {
      final byScore = b.day.score.compareTo(a.day.score);
      if (byScore != 0) return byScore;
      return a.localDate.compareTo(b.localDate);
    });
  return ranked.take(take).toList();
}
