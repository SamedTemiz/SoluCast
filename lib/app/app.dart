import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_providers.dart';
import 'localization.dart';
import 'theme.dart';

class AnglerPulseApp extends ConsumerWidget {
  const AnglerPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // İlk açılışta onboarding (screens.md §1); tamamlanınca kalıcı olarak Home.
    final onboarded = ref.watch(onboardingDoneProvider);
    final themePreference = ref.watch(themePreferenceProvider);
    final language = ref.watch(languagePreferenceProvider);
    final themeMode = switch (themePreference) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.light => ThemeMode.light,
    };

    return MaterialApp(
      title: 'AnglerPulse',
      debugShowCheckedModeBanner: false,
      theme: SoluTheme.light(),
      darkTheme: SoluTheme.dark(),
      themeMode: themeMode,
      locale: language.locale,
      supportedLocales: AppLanguage.values.map((language) => language.locale),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Telefon-öncelikli düzen: geniş viewport'ta (web önizleme, tablet)
      // içeriği telefon genişliğine sabitle — kartlar aşırı gerilmez,
      // SegmentedButton benzeri kontroller taşmaz. Gerçek telefonda etkisiz.
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child!,
          ),
        ),
      ),
      home: onboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
