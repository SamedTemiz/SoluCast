import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/location/saved_location.dart';
import '../day_detail/day_detail_screen.dart';
import '../shared/entitlement.dart';
import '../shared/location_switcher_sheet.dart';
import '../shared/upgrade_sheet.dart';
import '../shared/widgets/fish_rating.dart';
import '../shared/widgets/reveal.dart';
import '../today/today_format.dart';
import '../today/today_providers.dart';

/// Takvim & Tahmin sekmesi (Stitch "Takvim & Tahmin"): 7 günlük şerit + aylık
/// grid. Gerçek skorlarla, dokunulabilir — ücretsizde bugün+yarın açık.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _displayedMonth;
  bool _initialized = false;

  void _ensureInit(DateTime today) {
    if (_initialized) return;
    _displayedMonth = DateTime(today.year, today.month);
    _initialized = true;
  }

  void _shiftMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta);
    });
  }

  void _openDay(SavedLocation location, DateTime day, DateTime today, bool isPro) {
    if (isDateLocked(candidateLocalDate: day, todayLocalDate: today, isPro: isPro)) {
      showUpgradeTeaser(context, ref, feature: '14-day forecasts');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DayDetailScreen(location: location, localDate: day),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(activeLocationProvider);
    final isPro = ref.watch(isProPreviewProvider);
    final today = localToday(location);
    _ensureInit(today);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Reveal(child: _LocationHeader(location: location)),
          const SizedBox(height: 16),
          Reveal(
            delay: const Duration(milliseconds: 60),
            child: _WeekStrip(
              location: location,
              today: today,
              isPro: isPro,
              onTapDay: (d) => _openDay(location, d, today, isPro),
            ),
          ),
          const SizedBox(height: 20),
          Reveal(
            delay: const Duration(milliseconds: 120),
            child: _MonthHeader(
              month: _displayedMonth,
              onPrev: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
            ),
          ),
          const SizedBox(height: 8),
          Reveal(
            delay: const Duration(milliseconds: 160),
            child: _MonthGrid(
              location: location,
              month: _displayedMonth,
              today: today,
              isPro: isPro,
              onTapDay: (d) => _openDay(location, d, today, isPro),
            ),
          ),
          if (!isPro) ...[
            const SizedBox(height: 16),
            const _AdPlaceholder(),
          ],
        ],
      ),
    );
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader({required this.location});
  final SavedLocation location;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer(
      builder: (context, ref, _) => InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => showLocationSwitcher(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 18, color: scheme.tertiary),
              const SizedBox(width: 6),
              Text(location.name, style: Theme.of(context).textTheme.titleMedium),
              Icon(Icons.expand_more, size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({
    required this.location,
    required this.today,
    required this.isPro,
    required this.onTapDay,
  });

  final SavedLocation location;
  final DateTime today;
  final bool isPro;
  final void Function(DateTime) onTapDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Forecast',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 22)),
            Text('NEXT 7 DAYS', style: SoluTheme.labelCaps(context)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final day = today.add(Duration(days: i));
              final locked = isDateLocked(
                  candidateLocalDate: day, todayLocalDate: today, isPro: isPro);
              final label = i == 0
                  ? 'Today'
                  : i == 1
                      ? 'Tomorrow'
                      : TodayFormat.shortWeekday(day);

              return _DayStripCard(
                label: label,
                day: day,
                location: location,
                locked: locked,
                highlighted: i == 0,
                onTap: () => onTapDay(day),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayStripCard extends ConsumerWidget {
  const _DayStripCard({
    required this.label,
    required this.day,
    required this.location,
    required this.locked,
    required this.highlighted,
    required this.onTap,
  });

  final String label;
  final DateTime day;
  final SavedLocation location;
  final bool locked;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;

    Widget body;
    if (locked) {
      body = Icon(Icons.lock_outline, color: scheme.onSurfaceVariant, size: 22);
    } else {
      final result = ref.watch(
          solunarForDateProvider((location: location, localDate: day)));
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${result.solunar.fishRating}/5',
              style: SoluTheme.dataMono(context, size: 13, color: moss)),
          const SizedBox(height: 4),
          FishRating(rating: result.solunar.fishRating, size: 12, animate: false),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: highlighted
              ? Border.all(color: scheme.tertiary, width: 1.5)
              : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: 36, child: Center(child: body)),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader(
      {required this.month, required this.onPrev, required this.onNext});
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _names = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Text('${_names[month.month - 1]} ${month.year}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.location,
    required this.month,
    required this.today,
    required this.isPro,
    required this.onTapDay,
  });

  final SavedLocation location;
  final DateTime month;
  final DateTime today;
  final bool isPro;
  final void Function(DateTime) onTapDay;

  static const _weekdayHeaders = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Pazar=0 .. Cumartesi=6 (ABD konvansiyonu, Stitch tasarımı).
    final leadingBlanks = firstOfMonth.weekday % 7;

    return Column(
      children: [
        Row(
          children: [
            for (final h in _weekdayHeaders)
              Expanded(
                child: Center(
                  child: Text(h,
                      style: SoluTheme.labelCaps(context)
                          .copyWith(color: scheme.onSurfaceVariant)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leadingBlanks + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();
            final dayNum = index - leadingBlanks + 1;
            final date = DateTime(month.year, month.month, dayNum);
            return _MonthDayCell(
              date: date,
              location: location,
              isToday: _isSameDay(date, today),
              locked: isDateLocked(
                  candidateLocalDate: date, todayLocalDate: today, isPro: isPro),
              onTap: () => onTapDay(date),
            );
          },
        ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MonthDayCell extends ConsumerWidget {
  const _MonthDayCell({
    required this.date,
    required this.location,
    required this.isToday,
    required this.locked,
    required this.onTap,
  });

  final DateTime date;
  final SavedLocation location;
  final bool isToday;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;

    Color bg = scheme.surfaceContainer;
    Widget indicator = const SizedBox.shrink();

    if (locked) {
      indicator = Icon(Icons.lock_outline, size: 11, color: scheme.outline);
    } else {
      final result = ref.watch(
          solunarForDateProvider((location: location, localDate: date)));
      final rating = result.solunar.fishRating;
      if (rating >= 4) {
        bg = moss.withValues(alpha: 0.18);
      } else if (rating == 3) {
        bg = scheme.tertiary.withValues(alpha: 0.14);
      }
      indicator = Icon(Icons.set_meal,
          size: 11, color: rating >= 4 ? moss : scheme.tertiary);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: isToday ? Border.all(color: scheme.tertiary, width: 1.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${date.day}',
                style: SoluTheme.dataMono(context,
                    size: 12, color: locked ? scheme.outline : scheme.onSurface)),
            const SizedBox(height: 2),
            indicator,
          ],
        ),
      ),
    );
  }
}

class _AdPlaceholder extends StatelessWidget {
  const _AdPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Text('ADVERTISEMENT · SPONSORED GEAR',
          style: SoluTheme.labelCaps(context)),
    );
  }
}
