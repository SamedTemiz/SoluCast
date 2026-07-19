import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:angler_pulse/data/location/saved_location.dart';
import 'package:angler_pulse/data/prefs/preferences.dart';
import 'package:angler_pulse/features/today/today_providers.dart';

/// `replaceActive` (free-tier GPS "tek hakkı güncelle" akışı) ve isim-anahtarlı
/// kenar durumları — Codex incelemesinde eksik bulunan test kapsamı.
void main() {
  const gps = SavedLocation(
    name: 'Trabzon, Türkiye',
    latitude: 41.0,
    longitude: 39.72,
    timeZoneId: 'Europe/Istanbul',
    isDeviceLocation: true,
  );

  Future<ProviderContainer> makeContainer(SharedPreferences sp) async =>
      ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      );

  test(
    'replaceActive aktif kaydı değiştirir, liste uzunluğu sabit kalır',
    () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final c = await makeContainer(sp);
      addTearDown(c.dispose);

      expect(c.read(locationsProvider).locations, hasLength(1)); // demo
      c.read(locationsProvider.notifier).replaceActive(gps);

      final state = c.read(locationsProvider);
      expect(state.locations, hasLength(1));
      expect(state.activeName, gps.name);
      expect(state.active.isDeviceLocation, isTrue);
      expect(
        state.locations.any((l) => l.name == 'İstanbul'),
        isFalse,
        reason: 'eski aktif kayıt yerinde güncellenmiş olmalı',
      );
    },
  );

  test('replaceActive kalıcıdır (restart sonrası korunur)', () async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();

    final c1 = await makeContainer(sp);
    c1.read(locationsProvider.notifier).replaceActive(gps);
    c1.dispose();

    final c2 = await makeContainer(sp);
    addTearDown(c2.dispose);
    final state = c2.read(locationsProvider);
    expect(state.activeName, gps.name);
    expect(
      state.active.isDeviceLocation,
      isTrue,
      reason: 'isDeviceLocation JSON round-trip ile korunmalı',
    );
  });

  test(
    'replaceActive isim çakışmasında kopyayı düşürür (belirsizlik olmaz)',
    () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final c = await makeContainer(sp);
      addTearDown(c.dispose);

      final controller = c.read(locationsProvider.notifier);
      // Pro senaryosu: ikinci bir kayıt ekle, adı GPS sonucuyla çakışacak.
      controller.add(
        const SavedLocation(
          name: 'Trabzon, Türkiye',
          latitude: 40.9,
          longitude: 39.7,
          timeZoneId: 'Europe/Istanbul',
        ),
      );
      // Aktif hâlâ demo (İstanbul); GPS aynı adı üretti → aktif değişir,
      // çakışan eski kayıt listeden düşer.
      controller.replaceActive(gps);

      final state = c.read(locationsProvider);
      final matches = state.locations.where((l) => l.name == gps.name).toList();
      expect(matches, hasLength(1), reason: 'aynı isimden tek kayıt kalmalı');
      expect(
        matches.single.isDeviceLocation,
        isTrue,
        reason: 'kalan kayıt GPS (yeni) olan olmalı',
      );
      expect(state.activeName, gps.name);
    },
  );

  test('add mevcut isimle no-op kalır (mevcut davranış belgelendi)', () async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final c = await makeContainer(sp);
    addTearDown(c.dispose);

    final controller = c.read(locationsProvider.notifier);
    controller.add(SavedLocation.demo); // aynı isim
    expect(c.read(locationsProvider).locations, hasLength(1));
  });
}
