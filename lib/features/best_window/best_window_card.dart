import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/core.dart';
import '../settings/settings_providers.dart';
import '../shared/entitlement.dart';
import '../shared/upgrade_sheet.dart';
import '../shared/widgets/fish_rating.dart';
import '../today/today_format.dart';
import 'best_window_finder.dart';
import 'best_window_providers.dart';

/// Bugün ekranındaki "Ne zaman gitmeli?" kartı — taramanın 1 numarasını
/// gösterir, dokununca ilk 3 pencereyi sheet olarak açar.
class BestWindowCard extends ConsumerWidget {
  const BestWindowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windows = ref.watch(bestWindowsProvider);
    if (windows.isEmpty) return const SizedBox.shrink();

    final top = windows.first;
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;
    final fmt = TodayFormat(top.utcOffset, use24h: ref.watch(use24hProvider));

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBestWindowsSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Icon(Icons.explore_outlined, color: moss),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n('WHEN TO GO', 'NE ZAMAN GİTMELİ'),
                      style: SoluTheme.labelCaps(context).copyWith(color: moss),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${MaterialLocalizations.of(context).formatMediumDate(top.localDate)} · ${top.location.name}',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Dar ekran + büyük yazıda taşmak yerine alt satıra sarar.
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _window(fmt, top.period),
                          style: SoluTheme.dataMono(
                            context,
                            weight: FontWeight.w700,
                          ),
                        ),
                        FishRating(
                          rating: top.day.fishRating,
                          size: 13,
                          animate: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

String _window(TodayFormat fmt, SolunarPeriod period) =>
    '${fmt.time(period.start)}–${fmt.time(period.end)}';

void _showBestWindowsSheet(BuildContext pageContext, WidgetRef ref) {
  showModalBottomSheet(
    context: pageContext,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(
      builder: (context, sheetRef, _) {
        final windows = sheetRef.watch(bestWindowsProvider);
        final isPro = sheetRef.watch(isProPreviewProvider);
        final use24h = sheetRef.watch(use24hProvider);
        final scheme = Theme.of(context).colorScheme;

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n(
                    'Best fishing windows',
                    'En iyi balıkçılık pencereleri',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  isPro
                      ? context.l10n(
                          'Next 14 days · all spots',
                          'Önümüzdeki 14 gün · tüm noktalar',
                        )
                      : context.l10n(
                          'Next 7 days · active spot',
                          'Önümüzdeki 7 gün · etkin nokta',
                        ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < windows.length; i++) ...[
                  _WindowRow(rank: i + 1, window: windows[i], use24h: use24h),
                  if (i != windows.length - 1) const SizedBox(height: 8),
                ],
                const SizedBox(height: 14),
                Text(
                  context.l10n(
                    'Ranked by the on-device astronomy model; live weather is not part of future-day rankings.',
                    'Sıralama cihaz içi astronomi modeliyle yapılır; ileri günlerde canlı hava sıralamaya dahil değildir.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (!isPro) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      showUpgradeTeaser(
                        pageContext,
                        ref,
                        feature: pageContext.l10n(
                          'Best windows across 14 days and all spots',
                          '14 gün ve tüm noktalarda en iyi pencereler',
                        ),
                      );
                    },
                    icon: const Icon(Icons.lock_outline, size: 16),
                    label: Text(
                      context.l10n(
                        'See 14 days and all spots with Pro',
                        'Pro ile 14 günü ve tüm noktaları gör',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _WindowRow extends StatelessWidget {
  const _WindowRow({
    required this.rank,
    required this.window,
    required this.use24h,
  });

  final int rank;
  final BestWindow window;
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;
    final fmt = TodayFormat(window.utcOffset, use24h: use24h);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: rank == 1
              ? moss.withValues(alpha: 0.7)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
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
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(window.localDate),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  window.location.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _window(fmt, window.period),
                style: SoluTheme.dataMono(context, weight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              FishRating(
                rating: window.day.fishRating,
                size: 12,
                animate: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
