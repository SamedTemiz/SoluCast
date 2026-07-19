import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/core.dart';
import '../notifications/notification_providers.dart';
import '../shared/entitlement.dart';
import '../shared/widgets/reveal.dart';
import '../today/today_format.dart';
import 'settings_providers.dart';

const _privacyPolicyUrl =
    'https://github.com/SamedTemiz/AnglerPulse/blob/main/docs/privacy-policy.md';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProPreviewProvider);
    final use24h = ref.watch(use24hProvider);
    final units = ref.watch(unitsProvider);
    final notif = ref.watch(notificationSettingsProvider);
    final themeMode = ref.watch(themePreferenceProvider);
    final language = ref.watch(languagePreferenceProvider);
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;

    Future<void> setNotification(bool enabled, void Function() update) async {
      if (!enabled) {
        update();
        return;
      }
      final service = ref.read(notificationServiceProvider);
      await service.initialize();
      final granted = await service.requestPermissions();
      if (granted) {
        update();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n(
                'Notifications are not enabled. This alert will stay off.',
                'Bildirim izni verilmedi. Bu uyarı kapalı kalacak.',
              ),
            ),
            action: SnackBarAction(
              label: context.l10n('Open settings', 'Ayarları aç'),
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
    }

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Reveal(
            child: Text(
              context.l10n('Settings', 'Ayarlar'),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 24),
            ),
          ),
          const SizedBox(height: 16),
          Reveal(
            delay: const Duration(milliseconds: 40),
            child: _SectionCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: moss,
                title: Text(context.l10n('Pro Preview', 'Pro Önizleme')),
                subtitle: Text(
                  isPro
                      ? context.l10n(
                          'Pro-only features are unlocked for testing.',
                          'Pro işlevleri test için açık.',
                        )
                      : context.l10n(
                          'Local test switch; subscriptions are added later.',
                          'Yerel test anahtarı; abonelikler daha sonra eklenecek.',
                        ),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                value: isPro,
                onChanged: (value) =>
                    ref.read(isProPreviewProvider.notifier).set(value),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 80),
            child: _SectionCard(
              title: context.l10n('UNITS & FORMAT', 'BİRİMLER VE BİÇİM'),
              child: Column(
                children: [
                  _PrefRow(
                    title: context.l10n('Units', 'Birimler'),
                    subtitle: context.l10n(
                      'Applied to temperature, wind and pressure.',
                      'Sıcaklık, rüzgâr ve basınç değerlerine uygulanır.',
                    ),
                    control: SegmentedButton<UnitSystem>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: UnitSystem.imperial,
                          label: Text('°F'),
                        ),
                        ButtonSegment(
                          value: UnitSystem.metric,
                          label: Text('°C'),
                        ),
                      ],
                      selected: {units},
                      onSelectionChanged: (selection) =>
                          ref.read(unitsProvider.notifier).set(selection.first),
                    ),
                  ),
                  const Divider(height: 24),
                  _PrefRow(
                    title: context.l10n('Time format', 'Saat biçimi'),
                    subtitle:
                        '${context.l10n('Example', 'Örnek')}: ${TodayFormat(Duration.zero, use24h: use24h).time(DateTime.utc(2026, 1, 1, 17, 5))}',
                    control: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(value: false, label: Text('12h')),
                        ButtonSegment(value: true, label: Text('24h')),
                      ],
                      selected: {use24h},
                      onSelectionChanged: (selection) => ref
                          .read(use24hProvider.notifier)
                          .set(selection.first),
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
              title: context.l10n('NOTIFICATIONS', 'BİLDİRİMLER'),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: scheme.tertiary,
                    title: Text(context.l10n('Daily summary', 'Günlük özet')),
                    subtitle: Text(
                      context.l10n(
                        'Scheduled daily at 07:00 for the active location.',
                        'Etkin konum için her gün 07:00’ye programlanır.',
                      ),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    value: notif.dailySummary,
                    onChanged: (value) => setNotification(
                      value,
                      () => ref
                          .read(notificationSettingsProvider.notifier)
                          .setDailySummary(value),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: scheme.tertiary,
                    title: Text(
                      context.l10n(
                        'High-score day alert',
                        'Yüksek skorlu gün uyarısı',
                      ),
                    ),
                    subtitle: Text(
                      context.l10n(
                        'Alerts at 18:00 before a 4–5 star day.',
                        '4–5 yıldızlı günden önce 18:00’de uyarır.',
                      ),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    value: notif.highScoreAlert,
                    onChanged: (value) => setNotification(
                      value,
                      () => ref
                          .read(notificationSettingsProvider.notifier)
                          .setHighScoreAlert(value),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      context.l10n('Period reminders', 'Dönem hatırlatıcıları'),
                    ),
                    subtitle: Text(
                      isPro
                          ? context.l10n(
                              'Choose a period from day details.',
                              'Gün detayından bir dönem seçin.',
                            )
                          : 'Pro',
                      style: TextStyle(
                        color: isPro ? scheme.onSurfaceVariant : moss,
                        fontWeight: isPro ? null : FontWeight.w700,
                      ),
                    ),
                    trailing: Icon(
                      isPro ? Icons.check_circle : Icons.lock_outline,
                      color: isPro ? moss : scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            delay: const Duration(milliseconds: 160),
            child: _SectionCard(
              title: context.l10n('APPEARANCE & LANGUAGE', 'GÖRÜNÜM VE DİL'),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.palette_outlined),
                    title: Text(context.l10n('Theme', 'Tema')),
                    subtitle: Text(_themeLabel(context, themeMode)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemePicker(context, ref, themeMode),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language),
                    title: Text(context.l10n('Language', 'Dil')),
                    subtitle: Text(language.nativeName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguagePicker(context, ref, language),
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
                title: Text(
                  context.l10n(
                    'How is the score calculated?',
                    'Puan nasıl hesaplanıyor?',
                  ),
                ),
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
                    enabled: false,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      context.l10n(
                        'Restore purchases',
                        'Satın alımları geri yükle',
                      ),
                    ),
                    subtitle: Text(
                      context.l10n(
                        'Available when subscriptions launch.',
                        'Abonelikler yayımlandığında kullanılabilir.',
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(
                      context.l10n('Privacy policy', 'Gizlilik politikası'),
                    ),
                    subtitle: Text(
                      context.l10n(
                        'Opens the current policy on GitHub.',
                        'GitHub’daki güncel politikayı açar.',
                      ),
                    ),
                    trailing: const Icon(Icons.open_in_new, size: 19),
                    onTap: () => _openPrivacyPolicy(context),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      context.l10n('About AnglerPulse', 'AnglerPulse hakkında'),
                    ),
                    subtitle: Text(
                      context.l10n(
                        'Version 1.0.0 · Weather by Open-Meteo',
                        'Sürüm 1.0.0 · Hava verisi: Open-Meteo',
                      ),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
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

String _themeLabel(BuildContext context, AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => context.l10n('System', 'Sistem'),
  AppThemeMode.dark => context.l10n('Dark', 'Koyu'),
  AppThemeMode.light => context.l10n('Light', 'Açık'),
};

Future<void> _showThemePicker(
  BuildContext context,
  WidgetRef ref,
  AppThemeMode selected,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              title: Text(context.l10n('Theme', 'Tema')),
              titleTextStyle: Theme.of(context).textTheme.titleLarge,
            ),
            for (final mode in AppThemeMode.values)
              ListTile(
                leading: Icon(
                  mode == selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(_themeLabel(context, mode)),
                onTap: () {
                  ref.read(themePreferenceProvider.notifier).set(mode);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showLanguagePicker(
  BuildContext context,
  WidgetRef ref,
  AppLanguage selected,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              title: Text(context.l10n('Language', 'Dil')),
              titleTextStyle: Theme.of(context).textTheme.titleLarge,
            ),
            for (final language in AppLanguage.values)
              ListTile(
                leading: Icon(
                  selected == language
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(language.nativeName),
                onTap: () {
                  ref.read(languagePreferenceProvider.notifier).set(language);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _openPrivacyPolicy(BuildContext context) async {
  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(_privacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            'The privacy policy could not be opened.',
            'Gizlilik politikası açılamadı.',
          ),
        ),
      ),
    );
  }
}

void _showScoreExplainer(BuildContext context) {
  const weights = ScoreWeights.defaults;
  final rows = [
    (
      context.l10n('Moon phase', 'Ay evresi'),
      weights.moonPhase,
      context.l10n(
        'Peaks at new and full moon.',
        'Yeni ay ve dolunayda yükselir.',
      ),
    ),
    (
      context.l10n('Dawn / dusk overlap', 'Şafak / alacakaranlık çakışması'),
      weights.twilightOverlap,
      context.l10n(
        'Bonus when a major period overlaps twilight.',
        'Ana dönem alacakaranlıkla çakıştığında ek puan verir.',
      ),
    ),
    (
      context.l10n('Pressure trend', 'Basınç eğilimi'),
      weights.pressureTrend,
      context.l10n(
        'Falling pressure ahead of a front boosts activity.',
        'Cephe öncesi düşen basınç etkinliği artırır.',
      ),
    ),
    (
      context.l10n('Season', 'Mevsim'),
      weights.seasonal,
      context.l10n(
        'Longer daylight raises the baseline.',
        'Uzun gün ışığı taban puanı yükseltir.',
      ),
    ),
  ];

  showModalBottomSheet<void>(
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
              context.l10n(
                'How is the score calculated?',
                'Puan nasıl hesaplanıyor?',
              ),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n(
                'Each day receives a 0–100 score from four weighted factors. Astronomy is calculated on the device.',
                'Her gün dört ağırlıklı etkenden 0–100 puan alır. Astronomi cihazda hesaplanır.',
              ),
            ),
            const SizedBox(height: 16),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.$1,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          '${(row.$2 * 100).round()}%',
                          style: SoluTheme.dataMono(context, size: 13),
                        ),
                      ],
                    ),
                    Text(
                      row.$3,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              context.l10n(
                'If weather is unavailable, its weight is redistributed across the astronomy factors.',
                'Hava verisi yoksa ağırlığı astronomi etkenlerine dağıtılır.',
              ),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({required this.title, required this.control, this.subtitle});
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
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
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
  Widget build(BuildContext context) => Card(
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
