/// Skor ağırlıkları — tek yerde tutulur ki A/B testi ya da Remote Config'e taşıma
/// tek dosya değişikliği olsun (mimari kararı §6). Ağırlıklar 1.0'a toplanır.
///
/// Hava verisi yoksa [pressureTrend] ağırlığı diğerlerine oranla dağıtılır
/// (F3.4: uygulama yalnız astronomiyle de çalışır).
class ScoreWeights {
  /// Ay fazı — yeni/dolunay pik. Solunar teorisinin çekirdeği.
  final double moonPhase;

  /// Periyot ↔ şafak/akşam çakışması — "prime time" bonusu.
  final double twilightOverlap;

  /// Barometrik basınç trendi — düşüş öncesi pik (balıkçı bilgisi).
  final double pressureTrend;

  /// Mevsim / fotoperiyot normalizasyonu.
  final double seasonal;

  const ScoreWeights({
    this.moonPhase = 0.35,
    this.twilightOverlap = 0.25,
    this.pressureTrend = 0.20,
    this.seasonal = 0.20,
  });

  double get total => moonPhase + twilightOverlap + pressureTrend + seasonal;

  /// Hava verisi yokken basınç ağırlığını kalan üç faktöre oranla dağıtır.
  ScoreWeights withoutPressure() {
    final remaining = moonPhase + twilightOverlap + seasonal;
    if (remaining == 0) return this;
    final scale = 1.0 / remaining;
    return ScoreWeights(
      moonPhase: moonPhase * scale,
      twilightOverlap: twilightOverlap * scale,
      pressureTrend: 0.0,
      seasonal: seasonal * scale,
    );
  }

  static const ScoreWeights defaults = ScoreWeights();
}
