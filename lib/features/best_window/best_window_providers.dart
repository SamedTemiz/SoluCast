import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/location/saved_location.dart';
import '../shared/entitlement.dart';
import '../today/today_providers.dart';
import 'best_window_finder.dart';

/// Free kapsamı: aktif nokta + 7 gün. Pro: tüm noktalar + 14 gün (F4.3 ile
/// tutarlı — 14 günlük ufuk Pro değeridir).
const bestWindowFreeDays = 7;
const bestWindowProDays = 14;

/// Önümüzdeki günlerin en iyi major pencereleri (skora göre, gün başına tek).
/// Tamamen cihaz içi ve senkron — motorun sıfır maliyetli tarama avantajı.
///
/// "Şimdi" hesaplama anında dondurulur; Bugün ekranının pull-to-refresh'i
/// geçmişte kalan pencereleri ayıklamak için bu provider'ı invalidate eder.
final bestWindowsProvider = Provider<List<BestWindow>>((ref) {
  final isPro = ref.watch(isProPreviewProvider);
  final state = ref.watch(locationsProvider);
  final locations = isPro ? state.locations : [state.active];
  final horizon = isPro ? bestWindowProDays : bestWindowFreeDays;
  final nowUtc = DateTime.now().toUtc();

  final entries = <BestWindowInput>[
    for (final location in locations)
      for (var i = 0; i < horizon; i++)
        _entryFor(ref, location, i),
  ];
  return findBestWindows(entries: entries, nowUtc: nowUtc);
});

BestWindowInput _entryFor(Ref ref, SavedLocation location, int dayOffset) {
  final date = localToday(location).add(Duration(days: dayOffset));
  final result = ref.watch(
    solunarForDateProvider((location: location, localDate: date)),
  );
  return (
    location: location,
    localDate: result.localDate,
    day: result.solunar,
    utcOffset: result.ephemeris.utcOffset,
  );
}
