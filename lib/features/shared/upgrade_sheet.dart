import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../paywall/paywall_screen.dart';

/// Kilitli bir Pro özelliğine dokunulduğunda gösterilen hafif teaser sheet.
/// Monetizasyon hunisi: teaser → tam [PaywallScreen] (fiyat/karşılaştırma
/// orada). Satın alma RevenueCat gelene kadar paywall içinde Pro-preview
/// olarak şeffafça işaretlenir.
void showUpgradeTeaser(BuildContext context, WidgetRef ref,
    {required String feature}) {
  final scheme = Theme.of(context).colorScheme;
  final moss = SoluPalette.of(context).neonMoss;
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    // Küçük/yatay ekranlarda içerik sığmazsa taşmak yerine kaydırılır.
    isScrollControlled: true,
    builder: (sheetContext) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: moss, size: 32),
          const SizedBox(height: 12),
          Text('$feature is a Pro feature',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Unlock unlimited locations, 14-day forecasts, period reminders '
            'and an ad-free experience with SoluCast Pro.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: moss,
                foregroundColor: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final navigator = Navigator.of(sheetContext);
                navigator.pop();
                navigator.push(MaterialPageRoute(
                  builder: (_) => const PaywallScreen(),
                ));
              },
              child: const Text('See Pro plans'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: Text('Not now',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    ),
  );
}
