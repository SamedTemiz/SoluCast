import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/theme.dart';
import '../../data/prefs/preferences.dart';
import '../notifications/notification_providers.dart';
import '../paywall/paywall_screen.dart';
import '../settings/settings_providers.dart';

/// Onboarding tamamlandı mı? Kalıcı — app açılış rotası buna göre seçilir.
class OnboardingDone extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(PrefKeys.onboardingDone) ??
      false;

  void complete() {
    state = true;
    ref.read(sharedPreferencesProvider).setBool(PrefKeys.onboardingDone, true);
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingDone, bool>(
  OnboardingDone.new,
);

/// İlk açılış akışı (screens.md §1): 3 adım + soft paywall.
/// Hesap/kayıt YOK — izinler "neden istiyoruz" açıklamasıyla, reddedilebilir
/// şekilde istenir (uygulama izinsiz de çalışır; İstanbul demo konumu hazır).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishWithPaywall();
    }
  }

  Future<void> _finishWithPaywall() async {
    // Soft paywall: kapatılabilir, onboarding'i bloklamaz.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(fromOnboarding: true),
      ),
    );
    if (mounted) ref.read(onboardingDoneProvider.notifier).complete();
  }

  Future<void> _requestLocation() async {
    try {
      final p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {
      // Platform kanalı yoksa (test/web) sessizce geç — izin akışları
      // uygulama içinde gerektiğinde yeniden tetiklenir.
    }
    _next();
  }

  Future<void> _requestNotifications() async {
    try {
      final service = ref.read(notificationServiceProvider);
      await service.initialize();
      final granted = await service.requestPermissions();
      if (granted) {
        ref.read(notificationSettingsProvider.notifier).setDailySummary(true);
        ref.read(notificationSettingsProvider.notifier).setHighScoreAlert(true);
      }
    } catch (_) {}
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _OnboardPage(
                    icon: Icons.set_meal,
                    title: 'Know the best time to fish',
                    body:
                        'Solunar periods, moon phases and sunrise windows — '
                        'computed on your device, anywhere, even offline.',
                    cta: 'Get started',
                    onCta: _next,
                  ),
                  _OnboardPage(
                    icon: Icons.my_location,
                    title: 'Forecasts for your spot',
                    body:
                        'Allow location access to get solunar times for '
                        'exactly where you fish. Your location never leaves '
                        'this device.',
                    cta: 'Allow location',
                    onCta: _requestLocation,
                    skipLabel: 'Maybe later',
                    onSkip: _next,
                  ),
                  _OnboardPage(
                    icon: Icons.notifications_active_outlined,
                    title: 'Never miss a 5-star day',
                    body:
                        'Get a heads-up the evening before conditions line '
                        'up, plus an optional daily summary.',
                    cta: 'Enable notifications',
                    onCta: _requestNotifications,
                    skipLabel: 'Maybe later',
                    onSkip: _next,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pageCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? scheme.tertiary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.cta,
    required this.onCta,
    this.skipLabel,
    this.onSkip,
  });

  final IconData icon;
  final String title;
  final String body;
  final String cta;
  final VoidCallback onCta;
  final String? skipLabel;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final moss = SoluPalette.of(context).neonMoss;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 72, color: scheme.tertiary),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: moss,
                  foregroundColor: scheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onCta,
                child: Text(
                  cta,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(
                height: 44,
                child: skipLabel == null
                    ? null
                    : TextButton(
                        onPressed: onSkip,
                        child: Text(
                          skipLabel!,
                          style: text.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
