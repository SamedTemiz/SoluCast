import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/localization.dart';
import '../../../app/theme.dart';
import '../../../core/core.dart';

/// Günün solunar pencerelerini, aktivite eğrisini, gün ışığını ve "şimdi"
/// işaretini aynı bağlamda gösteren 24 saatlik etkileşimli zaman çizelgesi.
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
  final DateTime now;
  final void Function(SolunarPeriod)? onPeriodTap;

  double? _frac(DateTime? utc) {
    if (utc == null) return null;
    final local = utc.add(offset);
    final startOfDay = DateTime(local.year, local.month, local.day);
    final fraction = local.difference(startOfDay).inSeconds / 86400.0;
    if (fraction < 0 || fraction > 1) return null;
    return fraction;
  }

  void _handleTap(double xFraction) {
    final callback = onPeriodTap;
    if (callback == null) return;
    for (final period in [...day.majorPeriods, ...day.minorPeriods]) {
      final start = _frac(period.start);
      final end = _frac(period.end);
      if (start != null &&
          end != null &&
          xFraction >= start &&
          xFraction <= end) {
        callback(period);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = SoluPalette.of(context);
    final bands = <_Band>[
      for (final period in day.majorPeriods)
        _Band(_frac(period.start), _frac(period.end), major: true),
      for (final period in day.minorPeriods)
        _Band(_frac(period.start), _frac(period.end), major: false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 84,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) =>
                  _handleTap(details.localPosition.dx / constraints.maxWidth),
              child: CustomPaint(
                size: Size.infinite,
                painter: _TimelinePainter(
                  bands: bands,
                  activityCurve: hourlyActivityCurve(day),
                  sunrise: _frac(ephemeris.sunrise),
                  sunset: _frac(ephemeris.sunset),
                  now: _frac(now),
                  scheme: scheme,
                  palette: palette,
                  turkish: context.isTurkish,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        DefaultTextStyle(
          style: Theme.of(
            context,
          ).textTheme.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
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
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _Legend(
              color: palette.neonMoss,
              label: context.l10n('Major window', 'Ana aralık'),
            ),
            _Legend(
              color: scheme.tertiary,
              label: context.l10n('Minor window', 'İkincil aralık'),
              hatched: true,
            ),
            _Legend(
              color: scheme.primary,
              label: context.l10n('Daylight', 'Gün ışığı'),
              outlined: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.hatched = false,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool hatched;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 8,
        decoration: BoxDecoration(
          color: (outlined || hatched) ? null : color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(2),
          border: outlined
              ? Border.all(color: color.withValues(alpha: 0.65))
              : null,
          gradient: hatched
              ? LinearGradient(
                  colors: [color.withValues(alpha: 0.85), Colors.transparent],
                  stops: const [0.35, 0.35],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  tileMode: TileMode.repeated,
                )
              : null,
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _Band {
  const _Band(this.start, this.end, {required this.major});
  final double? start;
  final double? end;
  final bool major;
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({
    required this.bands,
    required this.activityCurve,
    required this.sunrise,
    required this.sunset,
    required this.now,
    required this.scheme,
    required this.palette,
    required this.turkish,
  });

  final List<_Band> bands;
  final List<double> activityCurve;
  final double? sunrise;
  final double? sunset;
  final double? now;
  final ColorScheme scheme;
  final SoluPalette palette;
  final bool turkish;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    const curveTop = 7.0;
    const curveHeight = 20.0;
    const trackTop = 35.0;
    const trackHeight = 29.0;
    const trackRadius = Radius.circular(6);
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackTop, width, trackHeight),
      trackRadius,
    );

    // Saat ızgarası hem eğriyi hem periyot pencerelerini okunur yapar.
    final gridPaint = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.36)
      ..strokeWidth = 1;
    for (var hour = 0; hour <= 24; hour += 6) {
      final x = width * hour / 24;
      canvas.drawLine(
        Offset(x, curveTop),
        Offset(x, trackTop + trackHeight),
        gridPaint,
      );
    }

    _paintActivityCurve(canvas, width, curveTop, curveHeight);

    canvas.drawRRect(track, Paint()..color = palette.midnight);
    canvas.save();
    canvas.clipRRect(track);

    if (sunrise != null && sunset != null) {
      final daylight = Rect.fromLTWH(
        sunrise! * width,
        trackTop,
        (sunset! - sunrise!).clamp(0, 1) * width,
        trackHeight,
      );
      canvas.drawRect(
        daylight,
        Paint()..color = scheme.primary.withValues(alpha: 0.12),
      );
    }

    for (final band in bands.where((band) => !band.major)) {
      _paintBand(canvas, band, width, trackTop, trackHeight, major: false);
    }
    for (final band in bands.where((band) => band.major)) {
      _paintBand(canvas, band, width, trackTop, trackHeight, major: true);
    }
    canvas.restore();
    canvas.drawRRect(
      track,
      Paint()
        ..color = scheme.outlineVariant.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke,
    );

    _paintSunMarker(canvas, sunrise, width, trackTop, trackHeight, '↑');
    _paintSunMarker(canvas, sunset, width, trackTop, trackHeight, '↓');
    _paintNowMarker(canvas, width, trackTop, trackHeight);
  }

  void _paintActivityCurve(
    Canvas canvas,
    double width,
    double top,
    double height,
  ) {
    if (activityCurve.isEmpty) return;
    final line = Path();
    for (var i = 0; i < activityCurve.length; i++) {
      final x = width * i / (activityCurve.length - 1);
      final y = top + (1 - activityCurve[i]) * height;
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }

    final area = Path.from(line)
      ..lineTo(width, top + height)
      ..lineTo(0, top + height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, top + height), [
          palette.chartLine.withValues(alpha: 0.30),
          Colors.transparent,
        ]),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = palette.chartLine.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintBand(
    Canvas canvas,
    _Band band,
    double width,
    double top,
    double height, {
    required bool major,
  }) {
    if (band.start == null || band.end == null) return;
    final rect = Rect.fromLTWH(
      band.start! * width,
      top,
      (band.end! - band.start!).clamp(0, 1) * width,
      height,
    );
    if (major) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [
            scheme.tertiary,
            palette.neonMoss.withValues(alpha: 0.9),
          ]),
      );
      if (rect.width >= 42) {
        _paintText(
          canvas,
          turkish ? 'ANA' : 'MAJOR',
          rect.center,
          palette.midnight,
          size: 7,
        );
      }
      return;
    }

    canvas.drawRect(
      rect,
      Paint()..color = scheme.tertiary.withValues(alpha: 0.18),
    );
    final hatch = Paint()
      ..color = scheme.tertiary.withValues(alpha: 0.62)
      ..strokeWidth = 1;
    canvas.save();
    canvas.clipRect(rect);
    for (var x = rect.left - rect.height; x < rect.right; x += 5) {
      canvas.drawLine(
        Offset(x, rect.bottom),
        Offset(x + rect.height, rect.top),
        hatch,
      );
    }
    canvas.restore();
  }

  void _paintSunMarker(
    Canvas canvas,
    double? fraction,
    double width,
    double top,
    double height,
    String symbol,
  ) {
    if (fraction == null) return;
    final center = Offset(fraction * width, top + height / 2);
    canvas.drawCircle(
      center,
      3,
      Paint()..color = scheme.primary.withValues(alpha: 0.85),
    );
    _paintText(
      canvas,
      symbol,
      Offset(center.dx, top - 4),
      scheme.primary,
      size: 9,
    );
  }

  void _paintNowMarker(Canvas canvas, double width, double top, double height) {
    if (now == null) return;
    final x = now! * width;
    final linePaint = Paint()
      ..color = palette.neonMoss
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, 1), Offset(x, top + height + 4), linePaint);

    final painter = TextPainter(
      text: TextSpan(
        text: turkish ? 'ŞİMDİ' : 'NOW',
        style: TextStyle(
          color: palette.midnight,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final tagWidth = painter.width + 8;
    final tagX = (x - tagWidth / 2).clamp(0.0, width - tagWidth);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tagX, 0, tagWidth, 12),
        const Radius.circular(3),
      ),
      Paint()..color = palette.neonMoss,
    );
    painter.paint(canvas, Offset(tagX + 4, 2));
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    Color color, {
    required double size,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) => true;
}
