/// Barometrik basınç trendi. Balıkçı bilgisi: balıklar cephe geçişinden hemen
/// önce, basınç düşerken en aktif; yüksek/sabit basınçta durgun.
enum PressureTrend { fallingFast, falling, steady, rising, risingFast }

/// Skora giren isteğe bağlı hava girdisi. `null` olabilir → skor yalnız
/// astronomiyle hesaplanır (F3.4). Hava katmanı (data/) bunu doldurur.
class WeatherInput {
  final double? pressureHpa;
  final PressureTrend? trend;

  const WeatherInput({this.pressureHpa, this.trend});

  bool get hasData => trend != null;

  /// Trendi 0..1 aktivite katkısına çevirir. Düşen basınç → yüksek.
  double get activityFactor {
    switch (trend) {
      case PressureTrend.fallingFast:
        return 1.0;
      case PressureTrend.falling:
        return 0.8;
      case PressureTrend.steady:
        return 0.5;
      case PressureTrend.rising:
        return 0.3;
      case PressureTrend.risingFast:
        return 0.15;
      case null:
        return 0.5;
    }
  }
}
