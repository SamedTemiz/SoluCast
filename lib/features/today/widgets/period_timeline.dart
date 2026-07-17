import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/core.dart';

/// 24 saatlik yatay şerit: major periyotlar koyu, minor açık bant; gün doğumu/
/// batımı işaretleri; şimdiki zaman imleci (screens.md "timeline").
class PeriodTimeline extends StatelessWidget {
  const PeriodTimeline({
    super.key,
    required this.day,
    required this.ephemeris,
    required this.offset,
    required this.localDate,
    required this.now,
    this.onPeriodTap,
  });

  final SolunarDay day;
  final DayEphemeris ephemeris;
  final Duration offset;
  final DateTime localDate;
  final DateTime now; // UTC

  /// Bir bant üzerine dokununca ilgili periyotla çağrılır (etkileşim).
  final void Function(SolunarPeriod)? onPeriodTap;

  double? _frac(DateTime? utc) {
    if (utc == null) return null;
    final local = utc.add(offset);
    final startOfDay = DateTime(local.year, local.month, local.day);
    final f = local.difference(startOfDay).inSeconds / 86400.0;
    if (f < 0 || f > 1) return null;
    return f;
  }

  void _handleTap(double xFraction) {
    final cb = onPeriodTap;
    if (cb == null) return;
    for (final p in [...day.majorPeriods, ...day.minorPeriods]) {
      final s = _frac(p.start);
      final e = _frac(p.end);
      if (s != null && e != null && xFraction >= s && xFraction <= e) {
        cb(p);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bands = <_Band>[
      for (final p in day.majorPeriods)
        _Band(_frac(p.start), _frac(p.end), true),
      for (final p in day.minorPeriods)
        _Band(_frac(p.start), _frac(p.end), false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) =>
                  _handleTap(details.localPosition.dx / constraints.maxWidth),
              child: CustomPaint(
                size: Size.infinite,
                painter: _TimelinePainter(
                  bands: bands,
                  sunrise: _frac(ephemeris.sunrise),
                  sunset: _frac(ephemeris.sunset),
                  now: _frac(now),
                  scheme: scheme,
                  palette: SoluPalette.of(context),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        DefaultTextStyle(
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: scheme.onSurfaceVariant,
              ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00'),
              Text('06'),
              Text('12'),
              Text('18'),
              Text('24'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Band {
  _Band(this.start, this.end, this.major);
  final double? start;
  final double? end;
  final bool major;
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.bands,
    required this.sunrise,
    required this.sunset,
    required this.now,
    required this.scheme,
    required this.palette,
  });

  final List<_Band> bands;
  final double? sunrise;
  final double? sunset;
  final double? now;
  final ColorScheme scheme;
  final SoluPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    const trackTop = 12.0;
    final trackH = h - 20;

    // Zemin track (Stitch: midnight, hafif yuvarlak)
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackTop, w, trackH),
      const Radius.circular(4),
    );
    canvas.drawRRect(trackRect, Paint()..color = palette.midnight);

    canvas.save();
    canvas.clipRRect(trackRect);

    // Gündüz aydınlatması (gün doğumu → batımı)
    if (sunrise != null && sunset != null) {
      final dayRect = Rect.fromLTWH(sunrise! * w, trackTop,
          (sunset! - sunrise!).clamp(0, 1) * w, trackH);
      canvas.drawRect(
          dayRect, Paint()..color = scheme.primary.withValues(alpha: 0.06));
    }

    // Minor bantlar: slate-teal diagonal hatch (Stitch)
    for (final b in bands.where((b) => !b.major)) {
      if (b.start == null || b.end == null) continue;
      final rect = Rect.fromLTWH(
          b.start! * w, trackTop, (b.end! - b.start!).clamp(0, 1) * w, trackH);
      canvas.drawRect(
          rect, Paint()..color = scheme.tertiary.withValues(alpha: 0.14));
      _hatch(canvas, rect, scheme.tertiary.withValues(alpha: 0.5));
    }

    // Major bantlar: solid teal (Stitch)
    for (final b in bands.where((b) => b.major)) {
      if (b.start == null || b.end == null) continue;
      final rect = Rect.fromLTWH(
          b.start! * w, trackTop, (b.end! - b.start!).clamp(0, 1) * w, trackH);
      canvas.drawRect(rect, Paint()..color = scheme.tertiary);
    }
    canvas.restore();

    // Gün doğumu / batımı çentikleri
    void tick(double? f) {
      if (f == null) return;
      canvas.drawCircle(Offset(f * w, trackTop + trackH / 2), 2.5,
          Paint()..color = scheme.onSurfaceVariant);
    }

    tick(sunrise);
    tick(sunset);

    // Şimdi imleci — neon-moss "NOW" (Stitch)
    if (now != null) {
      final x = now! * w;
      final p = Paint()
        ..color = palette.neonMoss
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, 2), Offset(x, h - 2), p);

      final tp = TextPainter(
        text: TextSpan(
          text: 'NOW',
          style: TextStyle(
            color: palette.midnight,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final tagW = tp.width + 8;
      final tagX = (x - tagW / 2).clamp(0.0, w - tagW);
      final tagRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(tagX, 0, tagW, 12), const Radius.circular(3));
      canvas.drawRRect(tagRect, Paint()..color = palette.neonMoss);
      tp.paint(canvas, Offset(tagX + 4, 2));
    }
  }

  void _hatch(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    const gap = 6.0;
    canvas.save();
    canvas.clipRect(rect);
    for (double x = rect.left - rect.height; x < rect.right; x += gap) {
      canvas.drawLine(
          Offset(x, rect.bottom), Offset(x + rect.height, rect.top), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TimelinePainter old) => true;
}
