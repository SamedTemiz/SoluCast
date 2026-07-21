import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/core.dart';
import '../../data/location/saved_location.dart';
import '../../data/prefs/preferences.dart';
import '../settings/settings_providers.dart';
import '../shared/score_explanation_sheet.dart';
import '../shared/widgets/fish_rating.dart';
import '../today/today_providers.dart';
import '../weather/weather_providers.dart';
import 'spot_comparison.dart';

/// Pro-only saved-spot ranking. The astronomy calculations run locally; live
/// weather is applied only when the selected date is that spot's current day.
class SpotCompareScreen extends ConsumerStatefulWidget {
  const SpotCompareScreen({super.key});

  @override
  ConsumerState<SpotCompareScreen> createState() => _SpotCompareScreenState();
}

class _SpotCompareScreenState extends ConsumerState<SpotCompareScreen> {
  DateTime? _selectedDate;
  late TimeOfDay _preferredTime;

  @override
  void initState() {
    super.initState();
    final minutes = ref
        .read(sharedPreferencesProvider)
        .getInt(PrefKeys.spotCompareTimeMinutes);
    final value = (minutes ?? 360).clamp(0, 1439);
    _preferredTime = TimeOfDay(hour: value ~/ 60, minute: value % 60);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationsProvider);
    final anchorToday = localToday(state.active);
    final selectedDate = _selectedDate ?? anchorToday;
    final comparison = _comparisonFor(state.locations, selectedDate);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(context.l10n('Compare spots', 'Noktaları karşılaştır')),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Text(
              context.l10n(
                'Find the strongest saved spot before you head out.',
                'Yola çıkmadan önce en güçlü kayıtlı noktayı bulun.',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _DatePickerCard(
              date: selectedDate,
              onTap: () => _pickDate(anchorToday),
            ),
            const SizedBox(height: 10),
            _TimePickerCard(time: _preferredTime, onTap: _pickTime),
            const SizedBox(height: 16),
            if (state.locations.length < 2)
              _NeedMoreSpotsCard(onAddSpot: () => Navigator.of(context).pop())
            else ...[
              _WinnerCard(
                comparison: comparison,
                preferredTime: _preferredTime,
                onExplain: () =>
                    _explainSpot(comparison.best!, selectedDate),
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < comparison.entries.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SpotRankCard(
                    entry: comparison.entries[index],
                    rank: index + 1,
                    activeName: state.activeName,
                    preferredTime: _preferredTime,
                    onExplain: () => _explainSpot(
                      comparison.entries[index],
                      selectedDate,
                    ),
                    onUse: () {
                      ref
                          .read(locationsProvider.notifier)
                          .selectActive(
                            comparison.entries[index].location.name,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n(
                              '${comparison.entries[index].location.name} is now your active spot.',
                              '${comparison.entries[index].location.name} etkin konumunuz oldu.',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 4),
              const _MethodNote(),
            ],
          ],
        ),
      ),
    );
  }

  SpotComparison _comparisonFor(
    List<SavedLocation> locations,
    DateTime selectedDate,
  ) {
    final engine = ref.watch(solunarEngineProvider);
    return SpotComparison.fromDays([
      for (final location in locations)
        _comparisonSource(location, selectedDate, engine),
    ]);
  }

  ({SavedLocation location, SolunarDay day, Duration utcOffset})
  _comparisonSource(
    SavedLocation location,
    DateTime selectedDate,
    SolunarEngine engine,
  ) {
    final result = ref.watch(
      solunarForDateProvider((location: location, localDate: selectedDate)),
    );
    final weather = ref.watch(weatherProvider(location)).asData?.value;
    final hasLiveWeather = _isSameDate(selectedDate, localToday(location));
    if (hasLiveWeather && weather != null) {
      return (
        location: location,
        day: engine.evaluate(result.ephemeris, weather: weather.toScoreInput()),
        utcOffset: result.ephemeris.utcOffset,
      );
    }
    return (
      location: location,
      day: result.solunar,
      utcOffset: result.ephemeris.utcOffset,
    );
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate(DateTime anchorToday) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? anchorToday,
      firstDate: anchorToday,
      lastDate: anchorToday.add(const Duration(days: 13)),
      helpText: context.l10n(
        'Choose comparison date',
        'Karşılaştırma günü seçin',
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _preferredTime,
      helpText: context.l10n(
        'When do you plan to fish?',
        'Ne zaman balık tutacaksınız?',
      ),
    );
    if (picked != null && mounted) {
      ref
          .read(sharedPreferencesProvider)
          .setInt(
            PrefKeys.spotCompareTimeMinutes,
            picked.hour * 60 + picked.minute,
          );
      setState(() => _preferredTime = picked);
    }
  }

  /// Bir noktanın skorunu açıklar. Kartta gösterilen [SolunarDay] doğrudan
  /// kullanılır (canlı hava varsa dahil); efemeris provider'dan okunur.
  void _explainSpot(SpotComparisonEntry entry, DateTime selectedDate) {
    final result = ref.read(
      solunarForDateProvider((
        location: entry.location,
        localDate: selectedDate,
      )),
    );
    showScoreExplanation(
      context,
      day: entry.day,
      ephemeris: result.ephemeris,
      use24h: ref.read(use24hProvider),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  const _DatePickerCard({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: scheme.tertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n('COMPARISON DATE', 'KARŞILAŞTIRMA TARİHİ'),
                      style: SoluTheme.labelCaps(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MaterialLocalizations.of(context).formatMediumDate(date),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  const _TimePickerCard({required this.time, required this.onTap});
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.schedule_outlined, color: scheme.tertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n(
                        'PLANNED FISHING TIME',
                        'PLANLANAN BALIK ZAMANI',
                      ),
                      style: SoluTheme.labelCaps(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MaterialLocalizations.of(context).formatTimeOfDay(time),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({
    required this.comparison,
    required this.preferredTime,
    required this.onExplain,
  });
  final SpotComparison comparison;
  final TimeOfDay preferredTime;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;
    final best = comparison.best!;
    final lead = comparison.lead!;
    final advantage = comparison.strongestAdvantage;
    final runnerUp = comparison.entries[1];

    final reason = lead == 0
        ? context.l10n(
            'It is tied with ${runnerUp.location.name}; use the period times to choose.',
            '${runnerUp.location.name} ile eşit; seçim için dönem saatlerine bakın.',
          )
        : advantage == null
        ? context.l10n(
            '$lead points ahead of ${runnerUp.location.name}.',
            '${runnerUp.location.name} konumunun $lead puan önünde.',
          )
        : context.l10n(
            '$lead points ahead — ${_factorLabel(context, advantage.factorKey)} is +${advantage.roundedPoints} points stronger.',
            '$lead puan önde — ${_factorLabel(context, advantage.factorKey)} +${advantage.roundedPoints} puan daha güçlü.',
          );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onExplain,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                moss.withValues(alpha: 0.24),
                scheme.tertiary.withValues(alpha: 0.13),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: moss.withValues(alpha: 0.65)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n('BEST BET', 'EN İYİ SEÇİM'),
                    style: SoluTheme.labelCaps(context).copyWith(color: moss),
                  ),
                  const Spacer(),
                  Icon(Icons.info_outline, size: 16, color: moss),
                ],
              ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  best.location.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Text(
                '${best.day.score}',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(color: moss),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FishRating(rating: best.day.fishRating, size: 20, animate: false),
          const SizedBox(height: 10),
          Text(
            reason,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (_nearestMajor(best, preferredTime) case final period?) ...[
            const SizedBox(height: 8),
            Text(
              context.l10nTemplate(
                'spot_compare_best_window',
                english: 'Best major window near your plan: {window}',
                turkish: 'Planınıza en yakın ana dönem: {window}',
                values: {'window': _formatPeriod(period, best.utcOffset)},
              ),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: moss),
            ),
          ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotRankCard extends StatelessWidget {
  const _SpotRankCard({
    required this.entry,
    required this.rank,
    required this.activeName,
    required this.preferredTime,
    required this.onExplain,
    required this.onUse,
  });
  final SpotComparisonEntry entry;
  final int rank;
  final String activeName;
  final TimeOfDay preferredTime;
  final VoidCallback onExplain;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = entry.location.name == activeName;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onExplain,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: rank == 1
                  ? SoluPalette.of(context).neonMoss.withValues(alpha: 0.75)
                  : scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: SoluTheme.dataMono(context, weight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.location.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                FishRating(
                  rating: entry.day.fishRating,
                  size: 14,
                  animate: false,
                ),
                if (_nearestMajor(entry, preferredTime) case final period?) ...[
                  const SizedBox(height: 3),
                  Text(
                    context.l10nTemplate(
                      'spot_compare_major_window',
                      english: 'Major {window}',
                      turkish: 'Ana dönem {window}',
                      values: {
                        'window': _formatPeriod(period, entry.utcOffset),
                      },
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.day.score}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                isActive
                    ? context.l10n('ACTIVE', 'ETKİN')
                    : context.l10n('USE', 'KULLAN'),
                style: SoluTheme.labelCaps(context).copyWith(
                  color: isActive ? scheme.onSurfaceVariant : scheme.tertiary,
                ),
              ),
            ],
          ),
          if (!isActive)
            IconButton(
              tooltip: context.l10n('Use this spot', 'Bu konumu kullan'),
              onPressed: onUse,
              icon: const Icon(Icons.check_circle_outline),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedMoreSpotsCard extends StatelessWidget {
  const _NeedMoreSpotsCard({required this.onAddSpot});
  final VoidCallback onAddSpot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        const Icon(Icons.add_location_alt_outlined, size: 32),
        const SizedBox(height: 10),
        Text(
          context.l10n(
            'Add one more spot to compare.',
            'Karşılaştırmak için bir nokta daha ekleyin.',
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onAddSpot,
          child: Text(context.l10n('Back to locations', 'Konumlara dön')),
        ),
      ],
    ),
  );
}

class _MethodNote extends StatelessWidget {
  const _MethodNote();

  @override
  Widget build(BuildContext context) => Text(
    context.l10n(
      'Scores use the same on-device solunar model as your forecast. Live pressure is included only when this is each spot’s current local day.',
      'Skorlar, tahmininizdeki aynı cihaz içi solunar modeli kullanır. Canlı basınç yalnızca ilgili konumun yerel bugünü için hesaba katılır.',
    ),
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

String _factorLabel(BuildContext context, String key) => switch (key) {
  'moon_phase' => context.l10n('moon phase', 'ay fazı'),
  'twilight_overlap' => context.l10n(
    'dawn/dusk overlap',
    'şafak/alacakaranlık çakışması',
  ),
  'pressure_trend' => context.l10n('pressure trend', 'basınç eğilimi'),
  'seasonal' => context.l10n('seasonal daylight', 'mevsimsel gün ışığı'),
  _ => context.l10n('solunar conditions', 'solunar koşullar'),
};

SolunarPeriod? _nearestMajor(SpotComparisonEntry entry, TimeOfDay time) {
  final periods = [...entry.day.majorPeriods]
    ..sort((a, b) => a.peak.compareTo(b.peak));
  if (periods.isEmpty) return null;

  final requestedMinutes = time.hour * 60 + time.minute;
  int distanceTo(SolunarPeriod period) {
    final localPeak = period.peak.add(entry.utcOffset);
    final difference =
        (localPeak.hour * 60 + localPeak.minute - requestedMinutes).abs();
    // A planned time near midnight should compare correctly with a window just
    // after/before midnight instead of treating the day boundary as 24 hours.
    return difference > 720 ? 1440 - difference : difference;
  }

  return periods.reduce(
    (best, candidate) =>
        distanceTo(candidate) < distanceTo(best) ? candidate : best,
  );
}

String _formatPeriod(SolunarPeriod period, Duration utcOffset) {
  String clock(DateTime utc) {
    final local = utc.add(utcOffset);
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  return '${clock(period.start)}–${clock(period.end)}';
}
