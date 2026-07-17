import 'day_ephemeris.dart';
import 'geo_position.dart';

/// Astronomik olayların üretildiği kaynak. Solunar motoru **yalnız bu soyut
/// arayüze** bağımlıdır; efemeris uygulaması (şu an [AstronomiaEphemeris])
/// değiştirilebilir. `core/` hiçbir Flutter/IO import'u içermez → saf test.
abstract interface class EphemerisSource {
  /// [position]'daki gözlemci için, [utcOffset] ile tanımlı yerel takvim günü
  /// ([year]/[month]/[day]) boyunca tüm güneş-ay olaylarını hesaplar.
  DayEphemeris computeDay({
    required int year,
    required int month,
    required int day,
    required GeoPosition position,
    required Duration utcOffset,
  });
}
