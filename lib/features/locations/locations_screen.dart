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
import '../today/today_providers.dart';

/// Konumlar sekmesi (Stitch "My Locations"): kayıtlı konum listesi, aktif
/// seçim, swipe-sil, preset ekleme. Free tier: 1 konum sınırı.
class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationsProvider);
    final isPro = ref.watch(isProPreviewProvider);
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Reveal(
            child: Row(
              children: [
                Icon(Icons.location_on, size: 18, color: scheme.tertiary),
                const SizedBox(width: 6),
                Text(state.active.name,
                    style: Theme.of(context).textTheme.titleMedium),
                Icon(Icons.expand_more, size: 20, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Reveal(
            delay: const Duration(milliseconds: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Locations',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 24)),
                IconButton.filled(
                  onPressed: () {
                    if (isLocationAddLocked(
                        currentCount: state.locations.length, isPro: isPro)) {
                      showUpgradeTeaser(context, ref, feature: 'Multiple locations');
                      return;
                    }
                    showAddLocationSheet(context, ref);
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: moss,
                    foregroundColor: scheme.surface,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < state.locations.length; i++)
            Reveal(
              delay: Duration(milliseconds: 100 + i * 60),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LocationCard(
                  location: state.locations[i],
                  isActive: state.locations[i].name == state.activeName,
                ),
              ),
            ),
          if (!isPro) ...[
            const SizedBox(height: 8),
            Reveal(
              delay: const Duration(milliseconds: 260),
              child: _UpgradeCard(
                onTap: () =>
                    showUpgradeTeaser(context, ref, feature: 'Unlimited locations'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationCard extends ConsumerWidget {
  const _LocationCard({required this.location, required this.isActive});
  final SavedLocation location;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;
    final today = localToday(location);
    final isPro = ref.watch(isProPreviewProvider);
    final isLocked = !isPro && !isActive;
    final result =
        ref.watch(solunarForDateProvider((location: location, localDate: today)));

    final card = InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (isLocked) {
          showUpgradeTeaser(context, ref, feature: 'Multiple locations');
          return;
        }
        ref.read(locationsProvider.notifier).selectActive(location.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to ${location.name}')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: scheme.tertiary, width: 1.5)
              : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(location.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: moss.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('ACTIVE',
                              style: SoluTheme.dataMono(context,
                                  size: 9, color: moss, weight: FontWeight.w700)),
                        ),
                      ],
                      if (isLocked) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.lock_outline,
                            size: 16, color: scheme.outline),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.cloud_outlined,
                          size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('Weather pending',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FishRating(
                          rating: result.solunar.fishRating,
                          size: 16,
                          animate: false),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          if (isLocked) {
                            showUpgradeTeaser(context, ref,
                                feature: 'Multiple locations');
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DayDetailScreen(
                                  location: location, localDate: today),
                            ),
                          );
                        },
                        child: Text(isLocked ? 'PRO' : 'DETAILS',
                            style: SoluTheme.labelCaps(context)
                                .copyWith(color: scheme.tertiary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isActive) return card; // aktif konum silinemez → swipe yok

    return Dismissible(
      key: ValueKey(location.name),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) =>
          ref.read(locationsProvider.notifier).remove(location.name),
      child: card,
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, color: scheme.onSurfaceVariant, size: 28),
          const SizedBox(height: 10),
          Text('Unlock Unlimited Locations',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Track conditions across all your favorite spots with Pro access.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: moss,
              side: BorderSide(color: moss),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('UPGRADE TO PRO'),
          ),
        ],
      ),
    );
  }
}
