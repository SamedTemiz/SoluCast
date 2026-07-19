import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/core.dart';
import '../../data/location/saved_location.dart';
import '../settings/settings_providers.dart';
import '../notifications/notification_providers.dart';
import '../shared/entitlement.dart';
import '../shared/upgrade_sheet.dart';
import '../today/today_format.dart';
import '../today/today_providers.dart';
import '../shared/widgets/reveal.dart';
import '../weather/weather_providers.dart';
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
    final fmt = TodayFormat(
      result.ephemeris.utcOffset,
      use24h: ref.watch(use24hProvider),
      turkish: context.isTurkish,
    );
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
                    TodayFormat.longDateFull(
                      result.localDate,
                      turkish: context.isTurkish,
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
              child: _HourlyWeatherCard(
                location: location,
                localDate: result.localDate,
              ),
            ),
            const SizedBox(height: 16),
            Reveal(
              delay: const Duration(milliseconds: 260),
              child: _ReminderButton(
                isPro: isPro,
                result: result,
                location: location,
                fmt: fmt,
              ),
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
              Text(
                '${day.fishRating}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: statusColor,
                  fontSize: 44,
                ),
              ),
              Text(
                '/5',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  TodayFormat.ratingLabel(
                    day.fishRating,
                    turkish: context.isTurkish,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            buildDaySummary(day, result.ephemeris, turkish: context.isTurkish),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
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
      title: context.l10n('Hourly Activity', 'Saatlik Etkinlik'),
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
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  interval: 6,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      value.toInt().toString().padLeft(2, '0'),
                      style: SoluTheme.dataMono(
                        context,
                        size: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => scheme.surfaceContainerHighest,
                getTooltipItems: (spots) => spots
                    .map(
                      (s) => LineTooltipItem(
                        '${(s.y * 100).round()}%',
                        TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < curve.length; i++)
                    FlSpot(i * 24.0 / (curve.length - 1), curve[i]),
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
      title: context.l10n('Solunar Periods', 'Solunar Dönemleri'),
      child: Column(
        children: [
          for (final p in periods)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PeriodRow(period: p, fmt: fmt),
            ),
          if (periods.isEmpty)
            Text(
              context.l10n(
                'No solunar periods today at this location.',
                'Bu konumda bugün solunar dönemi yok.',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
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
    final presentation = PeriodPresentation.of(
      period,
      fmt.offset,
      turkish: context.isTurkish,
    );

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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Text(
                      isMajor
                          ? context.l10n('MAJOR', 'ANA')
                          : context.l10n('MINOR', 'İKİNCİL'),
                      style: SoluTheme.dataMono(
                        context,
                        size: 11,
                        color: accent,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${fmt.time(period.start)}–${fmt.time(period.end)}',
                      style: SoluTheme.dataMono(context, size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  presentation.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
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

class _HourlyWeatherCard extends ConsumerWidget {
  const _HourlyWeatherCard({required this.location, required this.localDate});

  final SavedLocation location;
  final DateTime localDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final units = ref.watch(unitsProvider);
    final forecast = ref.watch(
      hourlyWeatherProvider((location: location, localDate: localDate)),
    );
    final hours = forecast.asData?.value ?? const [];
    final selected = hours
        .where((entry) => const [0, 6, 12, 18].contains(entry.localTime.hour))
        .toList();

    return _SectionCard(
      title: context.l10n('Hourly Weather', 'Saatlik Hava'),
      child: forecast.isLoading
          ? const SizedBox(
              height: 88,
              child: Center(child: CircularProgressIndicator()),
            )
          : selected.isEmpty
          ? SizedBox(
              height: 72,
              child: Center(
                child: Text(
                  context.l10n(
                    'Hourly forecast is unavailable for this date.',
                    'Bu tarih için saatlik tahmin kullanılamıyor.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selected.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final weather = selected[index];
                  final metric = units == UnitSystem.metric;
                  final temperature = metric
                      ? weather.temperatureC
                      : weather.temperatureC * 9 / 5 + 32;
                  final wind = metric
                      ? weather.windSpeedKmh
                      : weather.windSpeedKmh * 0.621371;
                  return Container(
                    width: 78,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          '${weather.localTime.hour.toString().padLeft(2, '0')}:00',
                          style: SoluTheme.dataMono(context, size: 10),
                        ),
                        Icon(
                          _weatherIcon(weather.weatherCode),
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        Text(
                          '${temperature.round()}°${metric ? 'C' : 'F'}',
                          style: SoluTheme.dataMono(context, size: 13),
                        ),
                        Text(
                          '${wind.round()} ${metric ? 'km/h' : 'mph'} · ${weather.precipitationProbabilityPct}%',
                          maxLines: 1,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

IconData _weatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny_outlined;
  if (code <= 3) return Icons.cloud_outlined;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 71 && code <= 77 || code == 85 || code == 86) {
    return Icons.ac_unit;
  }
  if (code >= 95) return Icons.thunderstorm_outlined;
  return Icons.water_drop_outlined;
}

class _ReminderButton extends ConsumerWidget {
  const _ReminderButton({
    required this.isPro,
    required this.result,
    required this.location,
    required this.fmt,
  });
  final bool isPro;
  final DayResult result;
  final SavedLocation location;
  final TodayFormat fmt;

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          if (!isPro) {
            showUpgradeTeaser(
              context,
              ref,
              feature: context.l10n(
                'Period reminders',
                'Dönem hatırlatıcıları',
              ),
            );
            return;
          }
          _showReminderPicker(context, ref);
        },
        icon: const Icon(Icons.notifications_active_outlined),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n('Set Reminder', 'Hatırlatıcı Kur'),
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            if (!isPro) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRO',
                  style: SoluTheme.dataMono(context, size: 10, color: moss),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showReminderPicker(BuildContext context, WidgetRef ref) async {
    final periods = result.solunar.allPeriods;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n(
                  'Choose a solunar period',
                  'Bir solunar dönemi seçin',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n(
                  'You will be notified 15 minutes before it starts.',
                  'Başlamadan 15 dakika önce bildirim alırsınız.',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (periods.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    context.l10n(
                      'No solunar periods are available for this day.',
                      'Bu gün için solunar dönemi bulunmuyor.',
                    ),
                  ),
                ),
              for (final period in periods)
                _ReminderPeriodTile(
                  period: period,
                  fmt: fmt,
                  onTap:
                      period.start
                          .toUtc()
                          .subtract(const Duration(minutes: 15))
                          .isAfter(DateTime.now().toUtc())
                      ? () async {
                          final service = ref.read(notificationServiceProvider);
                          final periodLabel =
                              period.type == SolunarPeriodType.major
                              ? context.l10n('Major period', 'Ana dönem')
                              : context.l10n('Minor period', 'İkincil dönem');
                          final reminderTitle = context.l10n(
                            '$periodLabel starts in 15 minutes',
                            '$periodLabel 15 dakika içinde başlıyor',
                          );
                          await service.initialize();
                          final granted = await service.requestPermissions();
                          if (!granted) {
                            if (sheetContext.mounted) {
                              await _showNotificationSettingsDialog(
                                sheetContext,
                              );
                            }
                            return;
                          }
                          final id =
                              300000 +
                              (period.start.toUtc().millisecondsSinceEpoch ~/
                                      Duration.millisecondsPerMinute) %
                                  1000000000;
                          final scheduled = await service.schedulePeriodReminder(
                            id: id,
                            periodStartUtc: period.start,
                            timeZoneId: location.timeZoneId,
                            title: reminderTitle,
                            body:
                                '${location.name} · ${fmt.time(period.start)}–${fmt.time(period.end)}',
                          );
                          if (!context.mounted || !sheetContext.mounted) return;
                          if (scheduled) Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                scheduled
                                    ? context.l10n(
                                        'Reminder scheduled.',
                                        'Hatırlatıcı programlandı.',
                                      )
                                    : context.l10n(
                                        'This period has passed or notifications are unavailable.',
                                        'Bu dönem geçti veya bildirimler kullanılamıyor.',
                                      ),
                              ),
                            ),
                          );
                        }
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showNotificationSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.notifications_off_outlined),
      title: Text(context.l10n('Notifications are off', 'Bildirimler kapalı')),
      content: Text(
        context.l10n(
          'Allow notifications in system settings to schedule this reminder.',
          'Bu hatırlatıcıyı kurmak için sistem ayarlarından bildirim izni verin.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.l10n('Not now', 'Şimdi değil')),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            await Geolocator.openAppSettings();
          },
          child: Text(context.l10n('Open settings', 'Ayarları aç')),
        ),
      ],
    ),
  );
}

class _ReminderPeriodTile extends StatelessWidget {
  const _ReminderPeriodTile({
    required this.period,
    required this.fmt,
    required this.onTap,
  });

  final SolunarPeriod period;
  final TodayFormat fmt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final presentation = PeriodPresentation.of(
      period,
      fmt.offset,
      turkish: context.isTurkish,
    );
    final isMajor = period.type == SolunarPeriodType.major;
    return ListTile(
      enabled: onTap != null,
      contentPadding: EdgeInsets.zero,
      leading: Icon(presentation.icon),
      title: Text(presentation.label),
      subtitle: Text(
        '${isMajor ? context.l10n('MAJOR', 'ANA') : context.l10n('MINOR', 'İKİNCİL')} · ${fmt.time(period.start)}–${fmt.time(period.end)}',
      ),
      trailing: onTap == null
          ? Text(context.l10n('Passed', 'Geçti'))
          : const Icon(Icons.notifications_active_outlined),
      onTap: onTap,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.titleIcon,
  });
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
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (titleIcon != null) ...[
                  const Spacer(),
                  Icon(
                    titleIcon,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
