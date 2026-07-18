import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'entitlement.dart';

/// Kilitli bir Pro özelliğine dokunulduğunda gösterilen teaser sheet.
/// Gerçek satın alma akışı yok (RevenueCat Hafta 4) — burada yalnızca "Pro
/// Preview" dev-toggle'ını açmayı teklif eder, şeffafça etiketlenir.
void showUpgradeTeaser(BuildContext context, WidgetRef ref, {required String feature}) {
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
                ref.read(isProPreviewProvider.notifier).set(true);
                Navigator.of(sheetContext).pop();
              },
              child: const Text('Enable Pro Preview'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Purchases aren\'t wired up yet — this toggles a local preview flag.',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    ),
  );
}
