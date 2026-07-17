import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/core.dart';
import '../day_detail/period_presentation.dart';
import '../settings/settings_providers.dart';
import '../shared/location_switcher_sheet.dart';
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
    ref.invalidate(activeWeatherProvider);
    await Future.delayed(const Duration(milliseconds: 350));
    setState(() => _now = DateTime.now().toUtc());
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(todayScoredProvider);
    final fmt = TodayFormat(result.ephemeris.utcOffset,
        use24h: ref.watch(use24hProvider));

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Reveal(child: _Header(result: result)),
            const SizedBox(height: 16),
            Reveal(
              delay: const Duration(milliseconds: 60),
              child: _ConditionCard(result: result),
            ),
            const SizedBox(height: 12),
            Reveal(
              delay: const Duration(milliseconds: 140),
              child: _TimelineCard(result: result, fmt: fmt, now: _now),
            ),
            const SizedBox(height: 12),
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

class _Header extends ConsumerWidget {
  const _Header({required this.result});
  final DayResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => showLocationSwitcher(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 18, color: scheme.tertiary),
                const SizedBox(width: 6),
                Text(result.location.name,
                    style: Theme.of(context).textTheme.titleMedium),
                Icon(Icons.expand_more, size: 20, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        Text(
          TodayFormat.longDate(result.localDate).toUpperCase(),
          style: SoluTheme.labelCaps(context),
        ),
      ],
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({required this.result});
  final DayResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final solunar = result.solunar;
    final statusColor = _ratingColor(context, solunar.fishRating);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          children: [
            Text('FISHING CONDITION', style: SoluTheme.labelCaps(context)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: solunar.fishRating.toDouble()),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text('${v.round()}',
                      style: text.displayLarge),
                ),
                Text(' / 5',
                    style: text.headlineMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              TodayFormat.ratingLabel(solunar.fishRating),
              style: text.headlineMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            FishRating(rating: solunar.fishRating, size: 30),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showFactors(context, solunar),
              icon: const Icon(Icons.analytics_outlined, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                side: BorderSide(color: scheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              label: Text('WHY?', style: SoluTheme.labelCaps(context)
                  .copyWith(color: scheme.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}

void _showFactors(BuildContext context, SolunarDay day) {
  final scheme = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;
  final moss = SoluPalette.of(context).neonMoss;
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why ${day.fishRating}/5?', style: text.headlineMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('SCORE ', style: SoluTheme.labelCaps(context)),
              Text('${day.score}',
                  style: SoluTheme.dataMono(context, size: 14, color: moss)),
              Text(' / 100',
                  style: SoluTheme.dataMono(
                      context, size: 14, color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          ...day.factors.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(TodayFormat.factorLabel(f.key),
                            style: text.bodyMedium),
                        Text('+${f.contribution.round()}',
                            style: SoluTheme.dataMono(context,
                                size: 14, color: moss)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: f.raw,
                        minHeight: 6,
                        color: scheme.tertiary,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          Text('Astronomy is computed on-device, offline.',
              style: text.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    ),
  );
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard(
      {required this.result, required this.fmt, required this.now});
  final DayResult result;
  final TodayFormat fmt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final next = result.solunar.nextPeriodAfter(now);
    return _SectionCard(
      title: 'ACTIVITY TIMELINE',
      trailing: next == null
          ? null
          : InkWell(
              onTap: () => _showPeriodDetail(context, next, fmt),
              child: Text(
                '${TodayFormat.periodLabel(next.type)} starts ${TodayFormat.countdown(next.start.difference(now))}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: scheme.tertiary),
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

void _showPeriodDetail(BuildContext context, SolunarPeriod period, TodayFormat fmt) {
  final scheme = Theme.of(context).colorScheme;
  final moss = SoluPalette.of(context).neonMoss;
  final isMajor = period.type == SolunarPeriodType.major;
  final accent = isMajor ? moss : scheme.tertiary;
  final presentation = PeriodPresentation.of(period, fmt.offset);

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(presentation.icon, color: accent),
              const SizedBox(width: 10),
              Text(presentation.label,
                  style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${isMajor ? 'MAJOR' : 'MINOR'} · ${fmt.time(period.start)}–${fmt.time(period.end)}',
            style: SoluTheme.dataMono(context, size: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < presentation.stars ? Icons.star : Icons.star_border,
                size: 18,
                color: i < presentation.stars ? accent : scheme.outlineVariant,
              ),
            ),
          ),
          if (period.overlapsTwilight) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.wb_twilight, size: 16, color: accent),
                const SizedBox(width: 6),
                Text('Overlaps dawn/dusk — a prime-time bonus is applied.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ],
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
      final t = imperial ? weather.temperatureC * 9 / 5 + 32 : weather.temperatureC;
      temp = '${t.round()}°${imperial ? 'F' : 'C'}';
      final w = imperial ? weather.windSpeedKmh / 1.609 : weather.windSpeedKmh;
      wind = '${w.round()} ${imperial ? 'mph' : 'kmh'}';
      final p = imperial ? weather.pressureHpa / 33.864 : weather.pressureHpa;
      pressure = imperial ? p.toStringAsFixed(2) : p.round().toString();
      trailing = _PressureArrow(trend: weather.pressureTrend);
    }

    return _SectionCard(
      title: 'WEATHER',
      trailing: loading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: scheme.onSurfaceVariant))
          : (weather == null && !loading
              ? Text('offline', style: SoluTheme.labelCaps(context))
              : null),
      child: Row(
        children: [
          Expanded(
            child: _WeatherCell(
                icon: Icons.thermostat, label: 'TEMP', value: temp),
          ),
          const _CellDivider(),
          Expanded(
            child: _WeatherCell(icon: Icons.air, label: 'WIND', value: wind),
          ),
          const _CellDivider(),
          Expanded(
            child: _WeatherCell(
                icon: Icons.speed,
                label: 'PRESSURE',
                value: pressure,
                trailing: trailing),
          ),
        ],
      ),
    );
  }
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
  const _WeatherCell(
      {required this.icon,
      required this.label,
      required this.value,
      this.trailing});
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
            Text(value, style: SoluTheme.dataMono(context, size: 15)),
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
      title: 'SOLUNAR DATA',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.wb_sunny_outlined,
                      color: scheme.tertiary, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SunRow(
                          up: true, time: fmt.time(e.sunrise)),
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
                        Text(TodayFormat.moonPhaseLabel(e.moonPhase),
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text('${(e.moonIllumination * 100).round()}% ILLUM',
                            style: SoluTheme.labelCaps(context)),
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
        Icon(up ? Icons.north_east : Icons.south_east,
            size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(time, style: SoluTheme.dataMono(context, size: 14)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.child, this.trailing});
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
                Text(title, style: SoluTheme.labelCaps(context)),
                ?trailing,
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
