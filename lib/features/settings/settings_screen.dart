import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/core.dart';
import '../shared/entitlement.dart';
import '../shared/widgets/reveal.dart';
import '../today/today_format.dart';
import 'settings_providers.dart';

/// Ayarlar sekmesi (screens.md §6). Bazı satırlar gerçekten çalışır (24s
/// formatı, Pro preview, bildirim aç/kapa durumu); bazıları henüz veri
/// katmanı olmadığı için stub'dır — bu açıkça alt metinlerde belirtilir.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProPreviewProvider);
    final use24h = ref.watch(use24hProvider);
    final units = ref.watch(unitsProvider);
    final notif = ref.watch(notificationSettingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Reveal(
            child: Text('Settings',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 24)),
          ),
          const SizedBox(height: 16),
          Reveal(
            delay: const Duration(milliseconds: 40),
            child: _SectionCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: moss,
                title: const Text('Pro Preview'),
                subtitle: Text(
                  isPro
                      ? 'All Pro gates unlocked for testing.'
                      : 'Purchases aren\'t wired up yet — this is a local dev toggle.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                value: isPro,
                onChanged: (v) => ref.read(isProPreviewProvider.notifier).set(v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 80),
            child: _SectionCard(
              title: 'UNITS & FORMAT',
              child: Column(
                children: [
                  _PrefRow(
                    title: 'Units',
                    subtitle: 'Wired once the weather layer lands',
                    control: SegmentedButton<UnitSystem>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 14)),
                      ),
                      segments: const [
                        ButtonSegment(
                            value: UnitSystem.imperial, label: Text('°F')),
                        ButtonSegment(
                            value: UnitSystem.metric, label: Text('°C')),
                      ],
                      selected: {units},
                      onSelectionChanged: (s) =>
                          ref.read(unitsProvider.notifier).set(s.first),
                    ),
                  ),
                  const Divider(height: 24),
                  _PrefRow(
                    title: 'Time format',
                    subtitle:
                        'Example: ${TodayFormat(Duration.zero, use24h: use24h).time(DateTime.utc(2026, 1, 1, 17, 5))}',
                    control: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 14)),
                      ),
                      segments: const [
                        ButtonSegment(value: false, label: Text('12h')),
                        ButtonSegment(value: true, label: Text('24h')),
                      ],
                      selected: {use24h},
                      onSelectionChanged: (s) =>
                          ref.read(use24hProvider.notifier).set(s.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 120),
            child: _SectionCard(
              title: 'NOTIFICATIONS',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: scheme.tertiary,
                    title: const Text('Daily summary'),
                    subtitle: Text('Scheduling arrives with the notification layer',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    value: notif.dailySummary,
                    onChanged: (v) => ref
                        .read(notificationSettingsProvider.notifier)
                        .setDailySummary(v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: scheme.tertiary,
                    title: const Text('High-score day alert'),
                    value: notif.highScoreAlert,
                    onChanged: (v) => ref
                        .read(notificationSettingsProvider.notifier)
                        .setHighScoreAlert(v),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Period reminders'),
                    subtitle: Text('Pro',
                        style: TextStyle(color: moss, fontWeight: FontWeight.w700)),
                    trailing: Icon(isPro ? Icons.check_circle : Icons.lock_outline,
                        color: isPro ? moss : scheme.outline),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 160),
            child: _SectionCard(
              title: 'APPEARANCE & LANGUAGE',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Theme'),
                    trailing: Text('Dark (MVP)',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Language'),
                    trailing: Text('English',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 200),
            child: _SectionCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.analytics_outlined, color: scheme.tertiary),
                title: const Text('How is the score calculated?'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showScoreExplainer(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 240),
            child: _SectionCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Restore purchases'),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No purchases to restore yet.'))),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Privacy policy'),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy page coming before launch.'))),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('About SoluCast'),
                    subtitle: Text('Weather data by Open-Meteo.com',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showScoreExplainer(BuildContext context) {
  const w = ScoreWeights.defaults;
  final rows = [
    ('Moon phase', w.moonPhase, 'Peaks at new and full moon.'),
    ('Dawn / dusk overlap', w.twilightOverlap,
        'Bonus when a major period lines up with twilight.'),
    ('Pressure trend', w.pressureTrend,
        'Falling pressure ahead of a front boosts activity.'),
    ('Season', w.seasonal, 'Longer daylight raises the baseline.'),
  ];

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How is the score calculated?',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'Every day gets a 0–100 score from four weighted factors, '
            'computed entirely on-device from astronomy — no internet required.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.$1, style: Theme.of(context).textTheme.titleSmall),
                      Text('${(r.$2 * 100).round()}%',
                          style: SoluTheme.dataMono(context, size: 13)),
                    ],
                  ),
                  Text(r.$3,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          Text(
            'When weather data is unavailable, the pressure weight is '
            'redistributed across the other three factors.',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    ),
  );
}

/// Sol başlık+alt metin, sağda kontrol. `ListTile.trailing`'in dar kısıtları
/// SegmentedButton etiketlerini sarmalıyordu; bu düzen kontrole doğal
/// genişliğini verir, uzun alt metin sola sıkışmadan sarar.
class _PrefRow extends StatelessWidget {
  const _PrefRow(
      {required this.title, required this.control, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        control,
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title});
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: SoluTheme.labelCaps(context)),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
