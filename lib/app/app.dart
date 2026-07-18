import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'theme.dart';

class SoluCastApp extends ConsumerWidget {
  const SoluCastApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // İlk açılışta onboarding (screens.md §1); tamamlanınca kalıcı olarak Home.
    final onboarded = ref.watch(onboardingDoneProvider);

    return MaterialApp(
      title: 'SoluCast',
      debugShowCheckedModeBanner: false,
      theme: SoluTheme.dark(), // dark-first ürün (Stitch)
      // Telefon-öncelikli düzen: geniş viewport'ta (web önizleme, tablet)
      // içeriği telefon genişliğine sabitle — kartlar aşırı gerilmez,
      // SegmentedButton benzeri kontroller taşmaz. Gerçek telefonda etkisiz.
      builder: (context, child) => ColoredBox(
        color: SoluPalette.stitch.midnight,
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
