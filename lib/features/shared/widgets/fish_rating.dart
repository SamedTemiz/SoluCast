import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// 1–5 balık ikonu. Renk körlüğü dostu: dolu vs. dış-hat ikonla ifade, yalnız
/// renge dayanmaz (requirements erişilebilirlik). Dolu = Stitch neon-moss.
/// Dolu ikonlar hafif gecikmeli "pop" ile belirir.
class FishRating extends StatelessWidget {
  const FishRating({
    super.key,
    required this.rating,
    this.size = 34,
    this.animate = true,
  });

  final int rating; // 1..5
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moss = SoluPalette.of(context).neonMoss;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        final icon = Icon(
          filled ? Icons.set_meal : Icons.set_meal_outlined,
          size: size,
          color: filled ? moss : scheme.outlineVariant,
        );
        // Boşluk ikon boyutuyla orantılı — küçük rozetlerde (ör. takvim
        // hücresi) satır taşmasını önler, büyük kartlarda görünüm aynı kalır.
        final hPad = size * 0.06;
        if (!filled || !animate) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: icon,
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 260 + i * 90),
            curve: Curves.elasticOut,
            builder: (context, v, child) =>
                Transform.scale(scale: v.clamp(0, 1.0), child: child),
            child: icon,
          ),
        );
      }),
    );
  }
}
