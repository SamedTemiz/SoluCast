import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/core.dart';
import '../best_window/best_window_card.dart';
import '../best_window/best_window_providers.dart';
import '../day_detail/period_presentation.dart';
import '../settings/settings_providers.dart';
import '../shared/score_explanation_sheet.dart';
import '../weather/weather_providers.dart';
import 'today_format.dart';
import 'today_providers.dart';
import '../shared/widgets/fish_rating.dart';
import '../shared/widgets/moon_phase_icon.dart';
import 'widgets/period_timeline.dart';
import '../shared/widgets/reveal.dart';

/// Bugün sekmesinin gövdesi (Scaffold'u HomeShell verir). Stitch "Bugün (Ana
/// Ekran)" tasarımına göre kurulmuştur.
class TodayView extends ConsumerStatefulWidget {
  const TodayView({super.key});

  @override
  ConsumerState<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends ConsumerState<TodayView> {
  late DateTime _now = DateTime.now().toUtc();

  Future<void> _onRefresh() async {
    await refreshWeather(ref, ref.read(activeLocationProvider));
    // "Şimdi" tarama anında donduğu için geçmişte kalan pencereleri ayıkla.
    ref.invalidate(bestWindowsProvider);
    setState(() => _now = DateTime.now().toUtc());
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(todayScoredProvider);
    final fmt = TodayFormat(
      result.ephemeris.utcOffset,
      use24h: ref.watch(use24hProvider),
      turkish: context.isTurkish,
    );
    // Ağ yoksa ve cache de boşsa hava çözülemez; ama solunar/astronomi cihazda
    // hesaplandığından geçerlidir — kullanıcıya bunu açıkça söyle.
    final weatherAsync = ref.watch(activeWeatherProvider);
    final isOffline = !weatherAsync.isLoading && weatherAsync.asData?.value == null;

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Reveal(child: _TodayDateHeader(result: result)),
            const SizedBox(height: 16),
            Reveal(
              delay: const Duration(milliseconds: 60),
              child: _ConditionCard(
                result: result,
                use24h: ref.watch(use24hProvider),
              ),
            ),
            const SizedBox(height: 12),
            Reveal(
              delay: const Duration(milliseconds: 100),
              child: const BestWindowCard(),
            ),
            const SizedBox(height: 12),
            Reveal(
              delay: const Duration(milliseconds: 140),
              child: _TimelineCard(result: result, fmt: fmt, now: _now),
            ),
            const SizedBox(height: 12),
            if (isOffline) ...[
              Reveal(
                delay: const Duration(milliseconds: 180),
                child: const _OfflineReassuranceBanner(),
              ),
              const SizedBox(height: 12),
            ],
            Reveal(
              delay: const Duration(milliseconds: 200),
              child: const _WeatherRow(),
            ),
            const SizedBox(height: 12),
            Reveal(
              delay: const Duration(milliseconds: 260),
              child: _SolunarCard(result: result, fmt: fmt),
            ),
          ],
        ),
      ),
    );
  }
}

Color _ratingColor(BuildContext context, int rating) {
  final scheme = Theme.of(context).colorScheme;
  final moss = SoluPalette.of(context).neonMoss;
  if (rating >= 4) return moss;
  if (rating == 3) return scheme.tertiary;
  if (rating == 2) return scheme.onSurfaceVariant;
  return scheme.outline;
}

/// Çevrimdışıyken görünen güven bandı — en savunulabilir teknik farkımızı
/// (cihazda hesaplanan astronomi) tam gerektiği anda kullanıcıya gösterir.
class _OfflineReassuranceBanner extends StatelessWidget {
  const _OfflineReassuranceBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: moss.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: moss.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: moss),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n(
                'You are offline, but the solunar times below are computed on this device and remain accurate. Weather refreshes when you reconnect.',
                'Çevrimdışısınız, ancak aşağıdaki solunar saatleri bu cihazda hesaplanır ve geçerlidir. Hava, bağlantı gelince güncellenir.',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _TodayDateHeader extends StatelessWidget {
  const _TodayDateHeader({required this.result});
  final DayResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        TodayFormat.longDate(
          result.localDate,
          turkish: context.isTurkish,
        ).toUpperCase(),
        textAlign: TextAlign.center,
        style: SoluTheme.labelCaps(context),
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({required this.result, required this.use24h});
  final DayResult result;
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final solunar = result.solunar;
    final statusColor = _ratingColor(context, solunar.fishRating);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.96),
            scheme.surfaceContainer,
            scheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(color: statusColor.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                isLight
                    ? 'assets/images/fishing_condition_light_bg.png'
                    : 'assets/images/fishing_condition_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      scheme.surface.withValues(alpha: isLight ? 0.92 : 0.78),
                      scheme.surface.withValues(alpha: isLight ? 0.70 : 0.60),
                      scheme.primaryContainer.withValues(
                        alpha: isLight ? 0.08 : 0.18,
                      ),
                    ],
                    stops: const [0, 0.50, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _ConditionBackdropPainter(
                  accent: statusColor,
                  rating: solunar.fishRating,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n(
                            'FISHING CONDITION',
                            'BALIKÇILIK KOŞULU',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SoluTheme.labelCaps(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SOLUNAR ${solunar.score}',
                        style: SoluTheme.dataMono(
                          context,
                          size: 11,
                          color: scheme.onSurfaceVariant,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: solunar.fishRating.toDouble(),
                        ),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) =>
                            Text('${v.round()}', style: text.displayLarge),
                      ),
                      Text(
                        ' / 5',
                        style: text.headlineMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    TodayFormat.ratingLabel(
                      solunar.fishRating,
                      turkish: context.isTurkish,
                    ),
                    style: text.headlineMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FishRating(rating: solunar.fishRating, size: 30),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => showScoreExplanation(
                      context,
                      day: solunar,
                      ephemeris: result.ephemeris,
                      use24h: use24h,
                    ),
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.onSurface,
                      side: BorderSide(color: scheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    label: Text(
                      context.l10n('WHY?', 'NEDEN?'),
                      style: SoluTheme.labelCaps(
                        context,
                      ).copyWith(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skor kartının arka planındaki radar/dalga dokusu. Saf çizim olduğu için
/// tema rengine ve ekran boyutuna uyum sağlar; ek görsel indirmez.
class _ConditionBackdropPainter extends CustomPainter {
  const _ConditionBackdropPainter({required this.accent, required this.rating});

  final Color accent;
  final int rating;

  @override
  void paint(Canvas canvas, Size size) {
    final glowCenter = Offset(size.width * 0.84, size.height * 0.18);
    final glowRadius = size.width * 0.52;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.19),
            accent.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0, 0.48, 1],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    final radarPaint = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(glowCenter, 26.0 * i, radarPaint);
    }
    canvas.drawLine(
      Offset(glowCenter.dx - 82, glowCenter.dy),
      Offset(size.width + 12, glowCenter.dy),
      radarPaint,
    );
    canvas.drawLine(
      glowCenter,
      Offset(size.width + 10, glowCenter.dy + 56),
      radarPaint,
    );

    final wavePaint = Paint()
      ..color = accent.withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var wave = 0; wave < 3; wave++) {
      final path = Path();
      final baseY = size.height - 24 + wave * 9.0;
      for (var x = 0.0; x <= size.width; x += 8) {
        final y = baseY + math.sin((x / size.width) * math.pi * 2 + wave) * 3;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, wavePaint);
    }

    final dotPaint = Paint()..color = accent.withValues(alpha: 0.52);
    for (var i = 0; i < rating; i++) {
      canvas.drawCircle(Offset(17 + i * 10.0, 16), 1.4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ConditionBackdropPainter old) =>
      old.accent != accent || old.rating != rating;
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.result,
    required this.fmt,
    required this.now,
  });
  final DayResult result;
  final TodayFormat fmt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final next = result.solunar.nextPeriodAfter(now);
    return _SectionCard(
      title: context.l10n('ACTIVITY TIMELINE', 'ETKİNLİK ZAMAN ÇİZELGESİ'),
      trailing: next == null
          ? null
          : InkWell(
              onTap: () => _showPeriodDetail(context, next, fmt),
              child: Text(
                context.isTurkish
                    ? '${TodayFormat.periodLabel(next.type, turkish: true)} ${TodayFormat.countdown(next.start.difference(now), turkish: true)} başlıyor'
                    : '${TodayFormat.periodLabel(next.type)} starts ${TodayFormat.countdown(next.start.difference(now))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: scheme.tertiary),
              ),
            ),
      child: PeriodTimeline(
        day: result.solunar,
        ephemeris: result.ephemeris,
        offset: result.ephemeris.utcOffset,
        localDate: result.localDate,
        now: now,
        onPeriodTap: (p) => _showPeriodDetail(context, p, fmt),
      ),
    );
  }
}

void _showPeriodDetail(
  BuildContext context,
  SolunarPeriod period,
  TodayFormat fmt,
) {
  final scheme = Theme.of(context).colorScheme;
  final moss = SoluPalette.of(context).neonMoss;
  final isMajor = period.type == SolunarPeriodType.major;
  final accent = isMajor ? moss : scheme.tertiary;
  final presentation = PeriodPresentation.of(
    period,
    fmt.offset,
    turkish: context.isTurkish,
  );

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(presentation.icon, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    presentation.label,
                    style: Theme.of(sheetContext).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${isMajor ? context.l10n('MAJOR', 'ANA') : context.l10n('MINOR', 'İKİNCİL')} · ${fmt.time(period.start)}–${fmt.time(period.end)}',
              style: SoluTheme.dataMono(
                sheetContext,
                size: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < presentation.stars ? Icons.star : Icons.star_border,
                  size: 18,
                  color: i < presentation.stars
                      ? accent
                      : scheme.outlineVariant,
                ),
              ),
            ),
            if (period.overlapsTwilight) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.wb_twilight, size: 16, color: accent),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n(
                        'Overlaps dawn/dusk — a prime-time bonus is applied.',
                        'Şafak/alacakaranlıkla çakışıyor — en iyi zaman bonusu uygulanır.',
                      ),
                      style: Theme.of(sheetContext).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _WeatherRow extends ConsumerWidget {
  const _WeatherRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeWeatherProvider);
    final imperial = ref.watch(unitsProvider) == UnitSystem.imperial;
    final scheme = Theme.of(context).colorScheme;

    final weather = async.asData?.value;
    final loading = async.isLoading;

    String temp = '—', wind = '—', pressure = '—';
    Widget? trailing;
    if (weather != null) {
      final t = imperial
          ? weather.temperatureC * 9 / 5 + 32
          : weather.temperatureC;
      temp = '${t.round()}°${imperial ? 'F' : 'C'}';
      final w = imperial ? weather.windSpeedKmh / 1.609 : weather.windSpeedKmh;
      wind = '${w.round()} ${imperial ? 'mph' : 'kmh'}';
      final p = imperial ? weather.pressureHpa / 33.864 : weather.pressureHpa;
      pressure = imperial ? p.toStringAsFixed(2) : p.round().toString();
      trailing = _PressureArrow(trend: weather.pressureTrend);
    }

    return _SectionCard(
      title: context.l10n('WEATHER', 'HAVA'),
      trailing: loading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onSurfaceVariant,
              ),
            )
          : (weather == null && !loading
                ? Text(
                    context.l10n('offline', 'çevrimdışı'),
                    style: SoluTheme.labelCaps(context),
                  )
                : weather == null
                ? null
                : Text(
                    _weatherAgeLabel(context, weather.fetchedAt),
                    style: SoluTheme.labelCaps(context),
                  )),
      child: Row(
        children: [
          Expanded(
            child: _WeatherCell(
              icon: Icons.thermostat,
              label: context.l10n('TEMP', 'SICAKLIK'),
              value: temp,
            ),
          ),
          const _CellDivider(),
          Expanded(
            child: _WeatherCell(
              icon: Icons.air,
              label: context.l10n('WIND', 'RÜZGÂR'),
              value: wind,
            ),
          ),
          const _CellDivider(),
          Expanded(
            child: _WeatherCell(
              icon: Icons.speed,
              label: context.l10n('PRESSURE', 'BASINÇ'),
              value: pressure,
              trailing: trailing,
            ),
          ),
        ],
      ),
    );
  }
}

String _weatherAgeLabel(BuildContext context, DateTime fetchedAt) {
  final minutes = DateTime.now()
      .toUtc()
      .difference(fetchedAt.toUtc())
      .inMinutes;
  if (minutes < 2) return context.l10n('LIVE', 'CANLI');
  if (minutes < 60) {
    return context.l10nTemplate(
      'weather_minutes_ago',
      english: '{value}m ago',
      turkish: '{value} dk önce',
      values: {'value': '$minutes'},
    );
  }
  final hours = minutes ~/ 60;
  return context.l10nTemplate(
    'weather_hours_ago',
    english: '{value}h ago',
    turkish: '{value} sa önce',
    values: {'value': '$hours'},
  );
}

/// Basınç trend oku — balıkçı için kritik (düşen = yeşil/aktif, screens.md).
class _PressureArrow extends StatelessWidget {
  const _PressureArrow({required this.trend});
  final PressureTrend trend;

  @override
  Widget build(BuildContext context) {
    final palette = SoluPalette.of(context);
    late final IconData icon;
    late final Color color;
    switch (trend) {
      case PressureTrend.fallingFast:
      case PressureTrend.falling:
        icon = Icons.south_east;
        color = palette.pressureDown; // düşüş → aktivite ↑ (olumlu)
        break;
      case PressureTrend.steady:
        icon = Icons.trending_flat;
        color = Theme.of(context).colorScheme.onSurfaceVariant;
        break;
      case PressureTrend.rising:
      case PressureTrend.risingFast:
        icon = Icons.north_east;
        color = palette.pressureUp;
        break;
    }
    return Icon(icon, size: 14, color: color);
  }
}

class _WeatherCell extends StatelessWidget {
  const _WeatherCell({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SoluTheme.dataMono(context, size: 15),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 2), trailing!],
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: SoluTheme.labelCaps(context)),
      ],
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 40,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
  );
}

class _SolunarCard extends StatelessWidget {
  const _SolunarCard({required this.result, required this.fmt});
  final DayResult result;
  final TodayFormat fmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = result.ephemeris;
    return _SectionCard(
      title: context.l10n('SOLUNAR DATA', 'SOLUNAR VERİLERİ'),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    color: scheme.tertiary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SunRow(up: true, time: fmt.time(e.sunrise)),
                      const SizedBox(height: 4),
                      _SunRow(up: false, time: fmt.time(e.sunset)),
                    ],
                  ),
                ],
              ),
            ),
            const _CellDivider(),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  MoonPhaseIcon(
                    illumination: e.moonIllumination,
                    ageFraction: e.moonAgeFraction,
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          TodayFormat.moonPhaseLabel(
                            e.moonPhase,
                            turkish: context.isTurkish,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(e.moonIllumination * 100).round()}% ${context.l10n('ILLUM', 'AYDINLIK')}',
                          style: SoluTheme.labelCaps(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SunRow extends StatelessWidget {
  const _SunRow({required this.up, required this.time});
  final bool up;
  final String time;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.north_east : Icons.south_east,
          size: 14,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(time, style: SoluTheme.dataMono(context, size: 14)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SoluTheme.labelCaps(context),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: trailing!,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
