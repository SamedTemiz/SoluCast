import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import 'settings_providers.dart';

/// Compact controls for the Pro smart-alert rule. The actual scheduling stays
/// in the notification planner, so preference changes immediately rebuild the
/// rolling local-notification plan.
class SmartAlertControls extends ConsumerWidget {
  const SmartAlertControls({super.key, required this.notif});

  final NotificationPrefs notif;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(notificationSettingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n('ALERT RULE', 'UYARI KURALI'),
            style: SoluTheme.labelCaps(context),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n('Minimum day score', 'Minimum gün skoru'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 3, label: Text('3/5')),
              ButtonSegment(value: 4, label: Text('4/5')),
              ButtonSegment(value: 5, label: Text('5/5')),
            ],
            selected: {notif.smartMinRating},
            onSelectionChanged: (value) =>
                controller.setSmartMinRating(value.first),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n(
              'Notify before the major window',
              'Ana dönemden önce bildir',
            ),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 15, label: Text('15m')),
              ButtonSegment(value: 30, label: Text('30m')),
              ButtonSegment(value: 60, label: Text('60m')),
            ],
            selected: {notif.smartLeadMinutes},
            onSelectionChanged: (value) =>
                controller.setSmartLeadMinutes(value.first),
          ),
        ],
      ),
    );
  }
}
