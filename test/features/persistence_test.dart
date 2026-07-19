import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:angler_pulse/data/location/saved_location.dart';
import 'package:angler_pulse/data/prefs/preferences.dart';
import 'package:angler_pulse/features/settings/settings_providers.dart';
import 'package:angler_pulse/features/shared/entitlement.dart';
import 'package:angler_pulse/features/today/today_providers.dart';

/// Kalıcılık (#24): konumlar, ayarlar ve Pro durumu uygulama yeniden
/// başladığında korunmalı. "Restart" = aynı prefs örneğiyle yeni bir
/// ProviderContainer. Test kullanıcısının ilk fark edeceği state-kaybı
/// kusuruna karşı güvence.
void main() {
  Future<ProviderContainer> makeContainer(SharedPreferences sp) async {
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
    );
  }

  test('eklenen konum + aktif seçim restart sonrası korunur', () async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();

    final c1 = await makeContainer(sp);
    const sydney = SavedLocation(
      name: 'Sydney',
      latitude: -33.87,
      longitude: 151.2,
      timeZoneId: 'Australia/Sydney',
    );
    c1.read(locationsProvider.notifier).add(sydney);
    c1.read(locationsProvider.notifier).selectActive('Sydney');
    expect(c1.read(locationsProvider).activeName, 'Sydney');
    c1.dispose();

    // Restart: aynı prefs, yeni container.
    final c2 = await makeContainer(sp);
    final state = c2.read(locationsProvider);
    expect(
      state.locations.map((l) => l.name),
      containsAll(['İstanbul', 'Sydney']),
    );
    expect(state.activeName, 'Sydney');
    expect(state.active.timeZoneId, 'Australia/Sydney');
    c2.dispose();
  });

  test('ayarlar (24s, Pro) restart sonrası korunur', () async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();

    final c1 = await makeContainer(sp);
    c1.read(use24hProvider.notifier).set(false);
    c1.read(isProPreviewProvider.notifier).set(true);
    c1.dispose();

    final c2 = await makeContainer(sp);
    expect(c2.read(use24hProvider), isFalse);
    expect(c2.read(isProPreviewProvider), isTrue);
    c2.dispose();
  });

  test('bozuk konum JSON\'u demo konuma güvenli düşer (çökme yok)', () async {
    SharedPreferences.setMockInitialValues({
      PrefKeys.locations: 'this-is-not-json',
    });
    final sp = await SharedPreferences.getInstance();

    final c = await makeContainer(sp);
    final state = c.read(locationsProvider);
    expect(state.locations, hasLength(1));
    expect(state.active.name, 'İstanbul');
    c.dispose();
  });
}
