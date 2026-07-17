import 'package:flutter/material.dart';

import '../features/home/home_shell.dart';
import 'theme.dart';

class SoluCastApp extends StatelessWidget {
  const SoluCastApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const HomeShell(),
    );
  }
}
