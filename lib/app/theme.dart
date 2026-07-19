import 'package:flutter/material.dart';

/// AnglerPulse görsel kimliği — Stitch tasarım sisteminden birebir taşındı.
/// "Scientific Professionalism + Rugged Utility": veri-yoğun, yüksek kontrast,
/// enstrüman hissi. Dark-first (açık hava/güneş yansıması için).
class SoluTheme {
  SoluTheme._();

  // --- Stitch renk token'ları ---
  static const _navy = Color(0xFF0A192F); // primary-container / marka
  static const _surface = Color(0xFF101415);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF155E75),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD7F2F6),
    onPrimaryContainer: Color(0xFF073B46),
    secondary: Color(0xFF475569),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE2E8F0),
    onSecondaryContainer: Color(0xFF1E293B),
    tertiary: Color(0xFF007F73),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB8F3E9),
    onTertiaryContainer: Color(0xFF003731),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF7F9F9),
    onSurface: Color(0xFF191C1D),
    onSurfaceVariant: Color(0xFF3F484A),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF0F4F4),
    surfaceContainer: Color(0xFFE9EFEF),
    surfaceContainerHigh: Color(0xFFE2E9E9),
    surfaceContainerHighest: Color(0xFFDAE3E3),
    surfaceDim: Color(0xFFD7DBDB),
    surfaceBright: Color(0xFFF7F9F9),
    outline: Color(0xFF6F797A),
    outlineVariant: Color(0xFFBEC8C9),
    inverseSurface: Color(0xFF2D3132),
    onInverseSurface: Color(0xFFEFF1F1),
    inversePrimary: Color(0xFF82D3E4),
    surfaceTint: Color(0xFF155E75),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB9C7E4),
    onPrimary: Color(0xFF233148),
    primaryContainer: _navy,
    onPrimaryContainer: Color(0xFF74829D),
    secondary: Color(0xFFB9C7DF),
    onSecondary: Color(0xFF233144),
    secondaryContainer: Color(0xFF3C4A5E),
    onSecondaryContainer: Color(0xFFABB9D1),
    tertiary: Color(0xFF3CDDC7), // teal accent
    onTertiary: Color(0xFF003731),
    tertiaryContainer: Color(0xFF001D19),
    onTertiaryContainer: Color(0xFF009282),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: _surface,
    onSurface: Color(0xFFE0E3E5),
    onSurfaceVariant: Color(0xFFC5C6CD),
    surfaceContainerLowest: Color(0xFF0B0F10),
    surfaceContainerLow: Color(0xFF191C1E),
    surfaceContainer: Color(0xFF1D2022),
    surfaceContainerHigh: Color(0xFF272A2C),
    surfaceContainerHighest: Color(0xFF323537),
    surfaceDim: _surface,
    surfaceBright: Color(0xFF363A3B),
    outline: Color(0xFF8F9097),
    outlineVariant: Color(0xFF44474D),
    inverseSurface: Color(0xFFE0E3E5),
    onInverseSurface: Color(0xFF2D3133),
    inversePrimary: Color(0xFF515F78),
    surfaceTint: Color(0xFFB9C7E4),
  );

  static ThemeData dark() => _build(_darkScheme);
  // Dark-first ürün; açık tema aynı token mantığıyla türetilir (MVP'de dark).
  static ThemeData light() => _build(_lightScheme);

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _textTheme(base.textTheme, scheme),
      extensions: [
        scheme.brightness == Brightness.dark
            ? SoluPalette.stitch
            : SoluPalette.daylight,
      ],
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Stitch: kart 8px
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.tertiary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(
            fontFamily: _body,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
    );
  }

  // Paketlenmiş variable font aileleri (pubspec.yaml `fonts:`).
  static const _display = 'HankenGrotesk'; // başlık / skor
  static const _body = 'Inter'; // gövde
  static const _mono = 'JetBrainsMono'; // sayısal readout

  /// Hanken Grotesk (başlık/skor) + Inter (gövde) + JetBrains Mono (veri).
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle d(double size, FontWeight w, {double? height, double? spacing}) =>
        TextStyle(
          fontFamily: _display,
          fontSize: size,
          fontWeight: w,
          height: height,
          letterSpacing: spacing,
        );
    TextStyle b(double size, [FontWeight w = FontWeight.w400]) =>
        TextStyle(fontFamily: _body, fontSize: size, fontWeight: w);

    return base
        .copyWith(
          displayLarge: d(56, FontWeight.w800, height: 1.0, spacing: -2),
          headlineLarge: d(32, FontWeight.w700),
          headlineMedium: d(24, FontWeight.w600),
          titleLarge: d(22, FontWeight.w700),
          titleMedium: d(16, FontWeight.w600),
          titleSmall: b(14, FontWeight.w600),
          bodyLarge: b(18),
          bodyMedium: b(16),
          bodySmall: b(14),
          labelLarge: b(14, FontWeight.w700),
          labelMedium: b(12, FontWeight.w600),
          labelSmall: b(12, FontWeight.w700),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }

  /// label-caps: bölüm başlıkları / metadata (Inter 12/700, harf aralığı geniş).
  static TextStyle labelCaps(BuildContext context) => TextStyle(
    fontFamily: _body,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  /// data-mono: sayısal readout'lar (basınç, koordinat, aydınlanma).
  static TextStyle dataMono(
    BuildContext context, {
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: _mono,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: 0.2,
    color: color ?? Theme.of(context).colorScheme.onSurface,
  );
}

/// ColorScheme'de karşılığı olmayan Stitch fonksiyonel renkleri.
@immutable
class SoluPalette extends ThemeExtension<SoluPalette> {
  final Color neonMoss; // yüksek skor / "Go" / dolu balık
  final Color pressureUp; // basınç yükseliyor
  final Color pressureDown; // basınç düşüyor
  final Color chartLine; // grafik çizgisi
  final Color midnight; // en derin zemin

  const SoluPalette({
    required this.neonMoss,
    required this.pressureUp,
    required this.pressureDown,
    required this.chartLine,
    required this.midnight,
  });

  static const stitch = SoluPalette(
    neonMoss: Color(0xFFA3E635),
    pressureUp: Color(0xFF22C55E),
    pressureDown: Color(0xFFEF4444),
    chartLine: Color(0xFF38BDF8),
    midnight: Color(0xFF020617),
  );

  static const daylight = SoluPalette(
    neonMoss: Color(0xFF4D7C0F),
    pressureUp: Color(0xFF15803D),
    pressureDown: Color(0xFFB91C1C),
    chartLine: Color(0xFF0369A1),
    midnight: Color(0xFF020617),
  );

  static SoluPalette of(BuildContext context) =>
      Theme.of(context).extension<SoluPalette>() ?? stitch;

  @override
  SoluPalette copyWith({
    Color? neonMoss,
    Color? pressureUp,
    Color? pressureDown,
    Color? chartLine,
    Color? midnight,
  }) => SoluPalette(
    neonMoss: neonMoss ?? this.neonMoss,
    pressureUp: pressureUp ?? this.pressureUp,
    pressureDown: pressureDown ?? this.pressureDown,
    chartLine: chartLine ?? this.chartLine,
    midnight: midnight ?? this.midnight,
  );

  @override
  SoluPalette lerp(SoluPalette? other, double t) {
    if (other == null) return this;
    return SoluPalette(
      neonMoss: Color.lerp(neonMoss, other.neonMoss, t)!,
      pressureUp: Color.lerp(pressureUp, other.pressureUp, t)!,
      pressureDown: Color.lerp(pressureDown, other.pressureDown, t)!,
      chartLine: Color.lerp(chartLine, other.chartLine, t)!,
      midnight: Color.lerp(midnight, other.midnight, t)!,
    );
  }
}
