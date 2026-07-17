import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/core.dart';
import '../../data/location/saved_location.dart';
import '../settings/settings_providers.dart';
import '../shared/entitlement.dart';
import '../shared/upgrade_sheet.dart';
import '../today/today_format.dart';
import '../today/today_providers.dart';
import '../shared/widgets/reveal.dart';
import 'day_summary.dart';
import 'period_presentation.dart';

/// Takvimden bir gün seçilince açılan ayrıntı ekranı (Stitch "Gün Detayı").
/// [localDate] o konumun yerel takvim günüdür (saat bileşeni önemsiz).
class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({
    super.key,
    required this.location,
    required this.localDate,
  });

  final SavedLocation location;
  final DateTime localDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(
      solunarForDateProvider((location: location, localDate: localDate)),
    );
    final fmt = TodayFormat(result.ephemeris.utcOffset, use24h: ref.watch(use24hProvider));
    final isPro = ref.watch(isProPreviewProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    TodayFormat.longDateFull(result.localDate),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 48), // geri butonuyla dengelemek için
              ],
            ),
            const SizedBox(height: 8),
            Reveal(child: _HeroSummaryCard(result: result)),
            const SizedBox(height: 12),
            Reveal(
              delay: const Duration(milliseconds: 80),
              child: _ActivityChartCard(day: result.solunar),
            ),
            const SizedBox(height: 12),
            Reveal(
              delay: const Duration(milliseconds: 140),
              child: _PeriodsCard(result: result, fmt: fmt),
            ),
            const SizedBox(height: 12),
            Reveal(
              delay: const Duration(milliseconds: 200),
              child: const _HourlyWeatherCard(),
            ),
            const SizedBox(height: 16),
            Reveal(
              delay: const Duration(milliseconds: 260),
              child: _ReminderButton(isPro: isPro),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({required this.result});
  final DayResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;
    final day = result.solunar;
    final statusColor = day.fishRating >= 4
        ? moss
        : day.fishRating == 3
            ? scheme.tertiary
            : scheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.primaryContainer.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${day.fishRating}',
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(color: statusColor, fontSize: 44)),
              Text('/5',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(width: 10),
              Text(
                TodayFormat.ratingLabel(day.fishRating),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            buildDaySummary(day, result.ephemeris),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ActivityChartCard extends StatelessWidget {
  const _ActivityChartCard({required this.day});
  final SolunarDay day;

  @override
  Widget build(BuildContext context) {
    final palette = SoluPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final curve = hourlyActivityCurve(day);

    return _SectionCard(
      title: 'Hourly Activity',
      titleIcon: Icons.show_chart,
      child: SizedBox(
        height: 140,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 1,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  interval: 6,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(value.toInt().toString().padLeft(2, '0'),
                        style: SoluTheme.dataMono(context,
                            size: 10, color: scheme.onSurfaceVariant)),
                  ),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => scheme.surfaceContainerHighest,
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                        '${(s.y * 100).round()}%',
                        TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600)))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < curve.length; i++)
                    FlSpot(i * 24.0 / (curve.length - 1), curve[i])
                ],
                isCurved: true,
                curveSmoothness: 0.25,
                color: palette.chartLine,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.chartLine.withValues(alpha: 0.25),
                      palette.chartLine.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodsCard extends StatelessWidget {
  const _PeriodsCard({required this.result, required this.fmt});
  final DayResult result;
  final TodayFormat fmt;

  @override
  Widget build(BuildContext context) {
    final periods = result.solunar.allPeriods;
    return _SectionCard(
      title: 'Solunar Periods',
      child: Column(
        children: [
          for (final p in periods)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PeriodRow(period: p, fmt: fmt),
            ),
          if (periods.isEmpty)
            Text('No solunar periods today at this location.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.period, required this.fmt});
  final SolunarPeriod period;
  final TodayFormat fmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;
    final isMajor = period.type == SolunarPeriodType.major;
    final accent = isMajor ? moss : scheme.tertiary;
    final presentation = PeriodPresentation.of(period, fmt.offset);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(presentation.icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(isMajor ? 'MAJOR' : 'MINOR',
                        style: SoluTheme.dataMono(context,
                            size: 11, color: accent, weight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('${fmt.time(period.start)}–${fmt.time(period.end)}',
                        style: SoluTheme.dataMono(context, size: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(presentation.label,
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < presentation.stars ? Icons.star : Icons.star_border,
                size: 14,
                color: i < presentation.stars ? accent : scheme.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyWeatherCard extends StatelessWidget {
  const _HourlyWeatherCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SectionCard(
      title: 'Hourly Weather',
      child: SizedBox(
        height: 76,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            const labels = ['00:00', '06:00', '12:00', '18:00'];
            return Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(labels[i], style: SoluTheme.dataMono(context, size: 10)),
                  Icon(Icons.cloud_queue,
                      size: 18, color: scheme.onSurfaceVariant),
                  Text('—', style: SoluTheme.dataMono(context, size: 13)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReminderButton extends ConsumerWidget {
  const _ReminderButton({required this.isPro});
  final bool isPro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: moss,
          foregroundColor: scheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          if (!isPro) {
            showUpgradeTeaser(context, ref, feature: 'Period reminders');
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reminder scheduling arrives with the notification layer.'),
          ));
        },
        icon: const Icon(Icons.notifications_active_outlined),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
            if (!isPro) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('PRO',
                    style: SoluTheme.dataMono(context, size: 10, color: moss)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.titleIcon});
  final String title;
  final Widget child;
  final IconData? titleIcon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (titleIcon != null) ...[
                  const Spacer(),
                  Icon(titleIcon,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
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
