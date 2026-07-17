import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solucast/core/astro/astronomia_ephemeris.dart';
import 'package:solucast/core/astro/geo_position.dart';

/// USNO ground-truth validasyonu (T1 önlemi — pazarlıksız).
///
/// Efemeris motorunu U.S. Naval Observatory tablolarına karşı ±2 dk toleransla
/// doğrular. Bu testler yeşil kalmadıkça yayın yapılmaz — "saatler yanlış"
/// şikâyeti bu uygulamada olmayacak.
void main() {
  const eph = AstronomiaEphemeris();
  const toleranceMinutes = 2.0;

  final file = File('test/validation/snapshots/usno_rise_set.json');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final snapshots = (data['snapshots'] as List).cast<Map<String, dynamic>>();

  group('USNO rise/set/transit validation (±2 min)', () {
    for (final snap in snapshots) {
      test(snap['name'] as String, () {
        final parts = (snap['date'] as String).split('-').map(int.parse).toList();
        final tzHours = (snap['tzHours'] as num).toDouble();
        final offset = Duration(minutes: (tzHours * 60).round());

        final result = eph.computeDay(
          year: parts[0],
          month: parts[1],
          day: parts[2],
          position: GeoPosition(
            latitude: (snap['lat'] as num).toDouble(),
            longitude: (snap['lon'] as num).toDouble(),
          ),
          utcOffset: offset,
        );

        // --- Güneş (tekil olaylar) ---
        final sun = snap['sun'] as Map<String, dynamic>?;
        if (sun != null) {
          _checkSingle(sun, 'civilDawn', result.civilDawn, offset, toleranceMinutes);
          _checkSingle(sun, 'sunrise', result.sunrise, offset, toleranceMinutes);
          _checkSingle(sun, 'transit', result.solarNoon, offset, toleranceMinutes);
          _checkSingle(sun, 'sunset', result.sunset, offset, toleranceMinutes);
          _checkSingle(sun, 'civilDusk', result.civilDusk, offset, toleranceMinutes);
        }

        // --- Ay (çoklu olaylar) ---
        final moon = snap['moon'] as Map<String, dynamic>?;
        if (moon != null) {
          _checkMulti(moon, 'rise', result.moonrises, offset, toleranceMinutes);
          _checkMulti(moon, 'set', result.moonsets, offset, toleranceMinutes);
          _checkMulti(moon, 'upperTransit', result.moonUpperTransits, offset, toleranceMinutes);
          _checkMulti(moon, 'lowerTransit', result.moonLowerTransits, offset, toleranceMinutes);

          if (moon.containsKey('illumPct')) {
            final expected = (moon['illumPct'] as num).toDouble();
            final actual = result.moonIllumination * 100.0;
            expect((actual - expected).abs(), lessThanOrEqualTo(3.0),
                reason: 'aydınlanma: beklenen ~$expected%, gerçek '
                    '${actual.toStringAsFixed(1)}%');
          }
        }
      });
    }
  });
}

/// Tekil bir güneş olayını doğrular. `null` beklenen → motor da null olmalı;
/// key yoksa atlanır.
void _checkSingle(
  Map<String, dynamic> group,
  String key,
  DateTime? actualUtc,
  Duration offset,
  double tol,
) {
  if (!group.containsKey(key)) return;
  final expected = group[key] as String?;

  if (expected == null) {
    expect(actualUtc, isNull,
        reason: '$key: bu gün gerçekleşmemeli (kutup), motor değer döndü: '
            '${_local(actualUtc, offset)}');
    return;
  }

  expect(actualUtc, isNotNull, reason: '$key: beklenen $expected, motor null döndü');
  final diff = _diffMinutes(actualUtc!, offset, expected);
  expect(diff, lessThanOrEqualTo(tol),
      reason: '$key: beklenen $expected, gerçek ${_local(actualUtc, offset)} '
          '(fark ${diff.toStringAsFixed(2)} dk)');
}

/// Çoklu ay olaylarını doğrular: sayı eşleşmeli, her referans için toleransta
/// bir eşleşme bulunmalı.
void _checkMulti(
  Map<String, dynamic> group,
  String key,
  List<DateTime> actualUtc,
  Duration offset,
  double tol,
) {
  if (!group.containsKey(key)) return;
  final expected = (group[key] as List).cast<String>();

  expect(actualUtc.length, expected.length,
      reason: '$key: ${expected.length} olay beklendi, motor '
          '${actualUtc.length} buldu (${actualUtc.map((d) => _local(d, offset)).toList()})');

  for (final exp in expected) {
    final match = actualUtc.any((a) => _diffMinutes(a, offset, exp) <= tol);
    expect(match, isTrue,
        reason: '$key: $exp için toleransta eşleşme yok — motor: '
            '${actualUtc.map((d) => _local(d, offset)).toList()}');
  }
}

/// UTC anını yerel dakikaya çevirip referans "HH:MM" ile farkı (dk) verir.
/// Gün sınırını (00:00 civarı) dolanarak en küçük farkı alır.
double _diffMinutes(DateTime utc, Duration offset, String expected) {
  final local = utc.add(offset);
  final actualMin = local.hour * 60 + local.minute + local.second / 60.0;
  final parts = expected.split(':').map(int.parse).toList();
  final expMin = parts[0] * 60.0 + parts[1];
  var d = (actualMin - expMin).abs();
  if (d > 720) d = 1440 - d; // 24h sarma
  return d;
}

String _local(DateTime? utc, Duration offset) {
  if (utc == null) return '—';
  final l = utc.add(offset);
  return '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}:'
      '${l.second.toString().padLeft(2, '0')}';
}
