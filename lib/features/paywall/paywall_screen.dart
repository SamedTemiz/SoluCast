import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../shared/entitlement.dart';
import '../shared/widgets/reveal.dart';

/// Soft paywall (screens.md §7): "Fish smarter with Pro", Free/Pro
/// karşılaştırma, yıllık öne çıkan fiyat kartı, 7 gün deneme vurgusu,
/// görünür kapatma — dark pattern yok (Play politika + yorum riski).
///
/// **RevenueCat henüz bağlı değil:** CTA şimdilik Pro-preview bayrağını açar
/// ve bunu kullanıcıya açıkça söyler. Satın alma katmanı geldiğinde yalnız
/// [_startTrial] gövdesi değişecek; UI ve tetik noktaları sabit kalır.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.fromOnboarding = false});

  /// Onboarding sonunda gösterilirken Skip daha belirgin olur.
  final bool fromOnboarding;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

enum _Plan { yearly, monthly }

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  _Plan _selected = _Plan.yearly;

  void _startTrial() {
    // RevenueCat gelene kadar: yerel Pro-preview, şeffaf etiketle.
    ref.read(isProPreviewProvider.notifier).set(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Purchases arrive with RevenueCat — Pro preview enabled for now.',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final moss = SoluPalette.of(context).neonMoss;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Görünür kapatma — asla gizlenmez.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: widget.fromOnboarding
                    ? TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Skip',
                          style: text.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                      ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                children: [
                  Reveal(
                    child: Column(
                      children: [
                        Icon(Icons.set_meal, size: 44, color: moss),
                        const SizedBox(height: 10),
                        Text(
                          'Fish smarter with Pro',
                          textAlign: TextAlign.center,
                          style: text.headlineLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Plan every trip with the full 14-day forecast.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Reveal(
                    delay: const Duration(milliseconds: 80),
                    child: _ComparisonTable(),
                  ),
                  const SizedBox(height: 20),
                  Reveal(
                    delay: const Duration(milliseconds: 160),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PlanCard(
                            title: 'Yearly',
                            price: '\$23.99',
                            per: '/year',
                            badge: '2 MONTHS FREE',
                            selected: _selected == _Plan.yearly,
                            onTap: () =>
                                setState(() => _selected = _Plan.yearly),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PlanCard(
                            title: 'Monthly',
                            price: '\$3.99',
                            per: '/month',
                            selected: _selected == _Plan.monthly,
                            onTap: () =>
                                setState(() => _selected = _Plan.monthly),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Sabit alt CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: moss,
                        foregroundColor: scheme.surface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _startTrial,
                      child: const Text(
                        'Start 7-day free trial',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '7-day free trial, then ${_selected == _Plan.yearly ? '\$23.99/year' : '\$3.99/month'} · Cancel anytime',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  static const _rows = [
    ('Today + tomorrow forecast', true, true),
    ('Full 14-day forecast', false, true),
    ('Saved locations', false, true), // free: 1 — hücrede yazıyla gösterilir
    ('Solunar period reminders', false, true),
    ('Ad-free experience', false, true),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final moss = SoluPalette.of(context).neonMoss;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 52,
                child: Text(
                  'FREE',
                  textAlign: TextAlign.center,
                  style: SoluTheme.labelCaps(context),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  'PRO',
                  textAlign: TextAlign.center,
                  style: SoluTheme.labelCaps(context).copyWith(color: moss),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final (label, free, pro) in _rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: text.bodySmall)),
                  SizedBox(
                    width: 52,
                    child: label == 'Saved locations'
                        ? Text(
                            '1',
                            textAlign: TextAlign.center,
                            style: SoluTheme.dataMono(
                              context,
                              size: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          )
                        : Icon(
                            free ? Icons.check : Icons.remove,
                            size: 16,
                            color: free
                                ? scheme.onSurfaceVariant
                                : scheme.outlineVariant,
                          ),
                  ),
                  SizedBox(
                    width: 52,
                    child: label == 'Saved locations'
                        ? Text(
                            '∞',
                            textAlign: TextAlign.center,
                            style: SoluTheme.dataMono(
                              context,
                              size: 13,
                              color: moss,
                            ),
                          )
                        : Icon(
                            pro ? Icons.check : Icons.remove,
                            size: 16,
                            color: moss,
                          ),
                  ),
                ],
              ),
            ),
            if (label != _rows.last.$1)
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.per,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String per;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final moss = SoluPalette.of(context).neonMoss;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: selected
              ? moss.withValues(alpha: 0.10)
              : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? moss
                : scheme.outlineVariant.withValues(alpha: 0.4),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
              child: badge == null
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: moss,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge!,
                        style: SoluTheme.dataMono(
                          context,
                          size: 9,
                          color: scheme.surface,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(title, style: text.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                Text(
                  price,
                  style: text.titleLarge?.copyWith(
                    color: selected ? moss : scheme.onSurface,
                  ),
                ),
                Text(
                  per,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
