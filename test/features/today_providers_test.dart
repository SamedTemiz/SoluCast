import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solucast/data/location/saved_location.dart';
import 'package:solucast/features/today/today_providers.dart';

/// Uçtan uca: IANA tz çözümü + efemeris + solunar motoru DST geçiş
/// günlerinde bile çökmeden, anlamlı sonuç üretir (T2 önlemi).
void main() {
  const newYork = SavedLocation(
    name: 'Test NY',
    latitude: 40.7128,
    longitude: -74.0060,
    timeZoneId: 'America/New_York',
  );

  test('DST bahar-ileri günü (2026-03-08) çökmeden geçerli sonuç üretir', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = container.read(solunarForDateProvider(
        (location: newYork, localDate: DateTime(2026, 3, 8))));

    expect(result.ephemeris.sunrise, isNotNull);
    expect(result.ephemeris.sunset, isNotNull);
    expect(result.ephemeris.utcOffset, const Duration(hours: -4));
    expect(result.solunar.score, inInclusiveRange(0, 100));
  });

  test('DST güz-geri günü (2026-11-01) çökmeden geçerli sonuç üretir', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = container.read(solunarForDateProvider(
        (location: newYork, localDate: DateTime(2026, 11, 1))));

    expect(result.ephemeris.sunrise, isNotNull);
    expect(result.ephemeris.sunset, isNotNull);
    expect(result.ephemeris.utcOffset, const Duration(hours: -5));
    expect(result.solunar.score, inInclusiveRange(0, 100));
  });

  test('Sydney (ters hemisfer) için de uçtan uca çalışır', () {
    const sydney = SavedLocation(
      name: 'Test Sydney',
      latitude: -33.8688,
      longitude: 151.2093,
      timeZoneId: 'Australia/Sydney',
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = container.read(solunarForDateProvider(
        (location: sydney, localDate: DateTime(2026, 1, 15))));

    expect(result.ephemeris.utcOffset, const Duration(hours: 11));
    expect(result.ephemeris.sunrise, isNotNull);
  });

  test('localToday konumun kendi tz\'sindeki güncel takvim gününü döner', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final today = localToday(newYork);
    expect(today.hour, 0); // saat bileşeni sıfırlanmış olmalı
  });
}
