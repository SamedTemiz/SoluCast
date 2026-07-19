/// AnglerPulse çekirdek motoru — saf Dart, %100 offline, Flutter/IO bağımsız.
///
/// Uygulamanın kalesi: astronomi efemerisi + solunar periyot/skor motoru.
/// USNO referanslarına karşı ±2 dk doğrulanır ([test/core/astro_validation_test.dart]).
/// UI ve data katmanları yalnız bu genel API'yi tüketir.
library;

// Astronomi
export 'astro/geo_position.dart';
export 'astro/day_ephemeris.dart';
export 'astro/ephemeris_source.dart';
export 'astro/astronomia_ephemeris.dart';

// Solunar
export 'solunar/solunar_period.dart';
export 'solunar/score_weights.dart';
export 'solunar/weather_input.dart';
export 'solunar/solunar_day.dart';
export 'solunar/solunar_engine.dart';
export 'solunar/hourly_activity.dart';
