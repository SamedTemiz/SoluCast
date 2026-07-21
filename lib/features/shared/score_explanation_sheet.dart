import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/core.dart';
import '../today/today_format.dart';

/// Skorun göründüğü her yerden (Today, Gün Detayı, Spot Compare) açılan ortak
/// "Neden bu skor?" sayfası: gerçek faktör dökümü + o güne özgü, eyleme dönük
/// tek satır çıkarım. Tüm veriler [day]/[ephemeris]'ten gelir; uydurma yok.
void showScoreExplanation(
  BuildContext context, {
  required SolunarDay day,
  required DayEphemeris ephemeris,
  bool use24h = true,
}) {
  final scheme = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;
  final moss = SoluPalette.of(context).neonMoss;
  final fmt = TodayFormat(ephemeris.utcOffset, use24h: use24h);

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n('Why ${day.fishRating}/5?', 'Neden ${day.fishRating}/5?'),
              style: text.headlineMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  context.l10n('SCORE ', 'PUAN '),
                  style: SoluTheme.labelCaps(context),
                ),
                Text(
                  '${day.score}',
                  style: SoluTheme.dataMono(context, size: 14, color: moss),
                ),
                Text(
                  ' / 100',
                  style: SoluTheme.dataMono(
                    context,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Eyleme dönük çıkarım — bu sayfanın asıl değer katmanı.
            _TakeawayBanner(
              text: buildScoreTakeaway(
                day,
                ephemeris,
                fmt,
                turkish: context.isTurkish,
              ),
            ),
            const SizedBox(height: 18),
            for (final f in day.factors) ...[
              _FactorRow(factor: f),
              const SizedBox(height: 14),
            ],
            Text(
              day.usedWeather
                  ? context.l10n(
                      'Astronomy is computed on-device, offline; live pressure is included today.',
                      'Astronomi cihazda ve çevrimdışı hesaplanır; bugün canlı basınç dahildir.',
                    )
                  : context.l10n(
                      'Astronomy is computed on-device, offline. Weather is not included in this score.',
                      'Astronomi cihazda ve çevrimdışı hesaplanır. Bu skora hava dahil değildir.',
                    ),
              style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TakeawayBanner extends StatelessWidget {
  const _TakeawayBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: moss.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: moss.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined, size: 18, color: moss),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});
  final ScoreFactor factor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final moss = SoluPalette.of(context).neonMoss;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              TodayFormat.factorLabel(factor.key, turkish: context.isTurkish),
              style: text.bodyMedium,
            ),
            Text(
              '+${factor.contribution.round()}',
              style: SoluTheme.dataMono(context, size: 14, color: moss),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: factor.raw.clamp(0, 1),
            minHeight: 6,
            color: scheme.tertiary,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

/// O güne özgü, eyleme dönük tek satır. Gerçek periyot/alacakaranlık verisinden
/// türetilir — "balık kesin ısırır" demez, timing tavsiyesi verir.
String buildScoreTakeaway(
  SolunarDay day,
  DayEphemeris ephemeris,
  TodayFormat fmt, {
  bool turkish = false,
}) {
  final primeMajors = day.majorPeriods.where((p) => p.overlapsTwilight).toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  if (primeMajors.isNotEmpty) {
    final p = primeMajors.first;
    final window = '${fmt.time(p.start)}–${fmt.time(p.end)}';
    final isDawn = _isBeforeSolarNoon(p.peak, ephemeris);
    final when = isDawn
        ? (turkish ? 'şafakla' : 'dawn')
        : (turkish ? 'alacakaranlıkla' : 'dusk');
    return turkish
        ? 'En güçlü zaman: $window ana dönemi $when çakışıyor — günün en iyi penceresi bu.'
        : 'Best bet: the $window major window overlaps $when — the strongest time to fish today.';
  }

  if (day.majorPeriods.isNotEmpty) {
    final sorted = [...day.majorPeriods]
      ..sort((a, b) => a.start.compareTo(b.start));
    final first = sorted.first;
    final window = '${fmt.time(first.start)}–${fmt.time(first.end)}';
    return turkish
        ? 'Ana dönemler ($window ile başlayan) aktiviteyi topluyor; hiçbiri şafak/alacakaranlıkla çakışmadığından zamanlama daha esnek.'
        : 'The major periods (starting $window) concentrate activity; none overlap dawn or dusk, so timing is flexible.';
  }

  return turkish
      ? 'Bugün yalnız ikincil dönemler var — kısa ve ölçülü aktivite bekleyin.'
      : 'Only minor periods today — expect brief, modest activity.';
}

bool _isBeforeSolarNoon(DateTime peakUtc, DayEphemeris ephemeris) {
  final noon = ephemeris.solarNoon;
  if (noon != null) return peakUtc.isBefore(noon);
  // Güneş öğlesi yoksa (kutup) yerel öğleni ölçü al.
  final localPeak = peakUtc.add(ephemeris.utcOffset);
  return localPeak.hour < 12;
}
