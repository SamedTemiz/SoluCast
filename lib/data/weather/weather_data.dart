import '../../core/core.dart';

/// Bir konum için anlık hava görüntüsü (Open-Meteo'dan). Skora yalnız
/// [pressureTrend] girer (F3.2); diğer alanlar UI şeridi içindir. [fetchedAt]
/// offline'da "son güncelleme X saat önce" için (F3.3).
class WeatherData {
  final double temperatureC;
  final double windSpeedKmh;
  final int windDirectionDeg;
  final int cloudCoverPct;
  final int precipitationProbabilityPct;
  final double pressureHpa;
  final PressureTrend pressureTrend;
  final DateTime fetchedAt; // UTC

  const WeatherData({
    required this.temperatureC,
    required this.windSpeedKmh,
    required this.windDirectionDeg,
    required this.cloudCoverPct,
    required this.precipitationProbabilityPct,
    required this.pressureHpa,
    required this.pressureTrend,
    required this.fetchedAt,
  });

  /// Skor motorunun tükettiği girdiye çevirir.
  WeatherInput toScoreInput() =>
      WeatherInput(pressureHpa: pressureHpa, trend: pressureTrend);

  Map<String, dynamic> toJson() => {
    't': temperatureC,
    'ws': windSpeedKmh,
    'wd': windDirectionDeg,
    'cc': cloudCoverPct,
    'pp': precipitationProbabilityPct,
    'p': pressureHpa,
    'pt': pressureTrend.name,
    'at': fetchedAt.toIso8601String(),
  };

  factory WeatherData.fromJson(Map<String, dynamic> j) => WeatherData(
    temperatureC: (j['t'] as num).toDouble(),
    windSpeedKmh: (j['ws'] as num).toDouble(),
    windDirectionDeg: (j['wd'] as num).toInt(),
    cloudCoverPct: (j['cc'] as num).toInt(),
    precipitationProbabilityPct: (j['pp'] as num).toInt(),
    pressureHpa: (j['p'] as num).toDouble(),
    pressureTrend: PressureTrend.values.byName(j['pt'] as String),
    fetchedAt: DateTime.parse(j['at'] as String),
  );
}

/// One local-wall-clock hourly forecast point returned for a selected day.
class HourlyWeatherData {
  final DateTime localTime;
  final double temperatureC;
  final double windSpeedKmh;
  final int precipitationProbabilityPct;
  final int weatherCode;

  const HourlyWeatherData({
    required this.localTime,
    required this.temperatureC,
    required this.windSpeedKmh,
    required this.precipitationProbabilityPct,
    required this.weatherCode,
  });
}

/// Son ~3 saatlik basınç serisinden trend sınıfı üretir (saf, testable).
/// Balıkçı bilgisi: hızlı düşüş → cephe geliyor → yüksek aktivite.
/// Eşikler 3 saatlik hPa değişimine göre:
///   ≤ -3   fallingFast · -3..-1 falling · -1..+1 steady · +1..+3 rising · ≥ +3 risingFast
PressureTrend classifyPressureTrend(List<double> recentHpa) {
  if (recentHpa.length < 2) return PressureTrend.steady;
  final delta = recentHpa.last - recentHpa.first;
  if (delta <= -3) return PressureTrend.fallingFast;
  if (delta <= -1) return PressureTrend.falling;
  if (delta < 1) return PressureTrend.steady;
  if (delta < 3) return PressureTrend.rising;
  return PressureTrend.risingFast;
}
