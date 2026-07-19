import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// IANA zaman dilimi çözümü — data katmanı (Flutter/IO'dan bağımsız olması
/// gereken `core/` buraya bağımlı değildir; motor saf `Duration` alır).
///
/// **DST yaklaşımı:** Bir takvim gününün ofseti, o günün **yerel öğlen**
/// anındaki ofset olarak alınır. Yılda yalnız 2 geçiş gününde (±1 saatlik
/// pencere gün başı/sonuna denk gelir) küçük bir kenar sapması olabilir;
/// bu, günlük astronomi/skor gösterimi için endüstri standardı bir
/// basitleştirmedir. Bildirim planlaması (F5, Hafta 3) anlık-doğru
/// [tz.TZDateTime] kullanacak — orada bu yaklaşıklık kullanılmaz.
class AppTimeZone {
  AppTimeZone._();

  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _initialized = true;
  }

  /// [timeZoneId] (ör. `America/New_York`) için [localDate] takvim gününde
  /// geçerli UTC ofseti (DST dahil, öğlen referanslı — yukarıki not).
  static Duration offsetForLocalDate(String timeZoneId, DateTime localDate) {
    ensureInitialized();
    final location = tz.getLocation(timeZoneId);
    final noon = tz.TZDateTime(
      location,
      localDate.year,
      localDate.month,
      localDate.day,
      12,
    );
    return noon.timeZoneOffset;
  }

  /// [timeZoneId] için şu anki yerel duvar saati.
  static DateTime nowInZone(String timeZoneId) {
    ensureInitialized();
    final location = tz.getLocation(timeZoneId);
    return tz.TZDateTime.now(location);
  }
}
