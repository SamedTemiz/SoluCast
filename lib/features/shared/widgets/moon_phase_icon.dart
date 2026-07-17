import 'package:flutter/material.dart';

/// Ay fazını aydınlanma oranı ve yaşına göre çizen ikon. [ageFraction] < 0.5
/// artan (bright limb sağda), > 0.5 azalan (solda). Terminatör bir bezier ile
/// yaklaşık çizilir — ikon ölçeğinde yeterli, hesap çekirdekte doğrulanmıştır.
class MoonPhaseIcon extends StatelessWidget {
  const MoonPhaseIcon({
    super.key,
    required this.illumination,
    required this.ageFraction,
    this.size = 48,
  });

  final double illumination; // 0..1
  final double ageFraction; // 0..1
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.square(size),
      painter: _MoonPainter(
        illumination: illumination.clamp(0.0, 1.0),
        ageFraction: ageFraction,
        lit: scheme.onSurface,
        dark: scheme.surfaceContainerHighest,
        outline: scheme.outlineVariant,
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({
    required this.illumination,
    required this.ageFraction,
    required this.lit,
    required this.dark,
    required this.outline,
  });

  final double illumination;
  final double ageFraction;
  final Color lit;
  final Color dark;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final f = illumination;

    canvas.drawCircle(c, r, Paint()..color = dark);

    if (f > 0.005) {
      final waxing = ageFraction < 0.5;
      final gibbous = f > 0.5;
      final bright = waxing ? 1.0 : -1.0;
      final term = (1 - 2 * f).abs() * r; // terminatör yatay yarıçapı
      final ctrlX = (gibbous ? -bright : bright) * term;

      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..arcToPoint(
          Offset(c.dx, c.dy + r),
          radius: Radius.circular(r),
          clockwise: waxing,
        )
        ..quadraticBezierTo(c.dx + ctrlX, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(path, Paint()..color = lit..isAntiAlias = true);
    }

    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outline,
    );
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.illumination != illumination || old.ageFraction != ageFraction;
}
