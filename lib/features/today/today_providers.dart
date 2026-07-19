import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core.dart';
import '../../data/location/saved_location.dart';
import '../../data/prefs/preferences.dart';
import '../../data/timezone/app_timezone.dart';

/// Efemeris kaynağı — tek örnek (const, durumsuz).
final ephemerisSourceProvider = Provider<EphemerisSource>(
  (ref) => const AstronomiaEphemeris(),
);

/// Solunar motoru — varsayılan ağırlıklarla.
final solunarEngineProvider = Provider<SolunarEngine>(
  (ref) => const SolunarEngine(),
);

/// Kayıtlı konumlar + aktif seçim. Data-fazında GPS/geocoding buraya bağlanır;
/// şimdilik demo konum + preset ekleme (screens.md canlı önizleme kuralı).
class LocationsState {
  final List<SavedLocation> locations;
  final String activeName;

  const LocationsState({required this.locations, required this.activeName});

  SavedLocation get active => locations.firstWhere(
    (l) => l.name == activeName,
    orElse: () => locations.first,
  );

  LocationsState copyWith({
    List<SavedLocation>? locations,
    String? activeName,
  }) => LocationsState(
    locations: locations ?? this.locations,
    activeName: activeName ?? this.activeName,
  );
}

class LocationsController extends Notifier<LocationsState> {
  @override
  LocationsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(PrefKeys.locations);
    if (raw == null) {
      return LocationsState(
        locations: [SavedLocation.demo],
        activeName: SavedLocation.demo.name,
      );
    }
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => SavedLocation.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isEmpty) throw const FormatException('boş konum listesi');
      final active = prefs.getString(PrefKeys.activeLocation);
      return LocationsState(
        locations: list,
        activeName: list.any((l) => l.name == active)
            ? active!
            : list.first.name,
      );
    } catch (_) {
      // Bozuk veri → demo'ya güvenli düşüş.
      return LocationsState(
        locations: [SavedLocation.demo],
        activeName: SavedLocation.demo.name,
      );
    }
  }

  void _persist() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(
      PrefKeys.locations,
      jsonEncode(state.locations.map((l) => l.toJson()).toList()),
    );
    prefs.setString(PrefKeys.activeLocation, state.activeName);
  }

  void selectActive(String name) {
    if (state.locations.any((l) => l.name == name)) {
      state = state.copyWith(activeName: name);
      _persist();
    }
  }

  void add(SavedLocation location) {
    if (state.locations.any((l) => l.name == location.name)) return;
    state = state.copyWith(locations: [...state.locations, location]);
    _persist();
  }

  /// Aktif kaydı GPS'ten gelen konumla günceller. Böylece ücretsiz plandaki
  /// tek favori konum sınırı, "mevcut konumum" kullanımını engellemez.
  ///
  /// Konumlar `name` ile anahtarlandığından, yeni ad başka bir kayıtla
  /// çakışırsa (ör. GPS adı bir preset'le aynı) kopya isim seçim/silmeyi
  /// belirsizleştirir — çakışan diğer kayıtlar listeden düşürülür.
  void replaceActive(SavedLocation location) {
    final index = state.locations.indexWhere((l) => l.name == state.activeName);
    if (index < 0) return;

    final replaced = [...state.locations]..[index] = location;
    final deduped = <SavedLocation>[
      for (var i = 0; i < replaced.length; i++)
        if (i == index || replaced[i].name != location.name) replaced[i],
    ];
    state = LocationsState(locations: deduped, activeName: location.name);
    _persist();
  }

  void remove(String name) {
    if (name == state.activeName) return; // aktif konum silinemez
    state = state.copyWith(
      locations: state.locations.where((l) => l.name != name).toList(),
    );
    _persist();
  }
}

final locationsProvider = NotifierProvider<LocationsController, LocationsState>(
  LocationsController.new,
);

/// Aktif konum — çoğu ekranın okuduğu kısayol.
final activeLocationProvider = Provider<SavedLocation>(
  (ref) => ref.watch(locationsProvider).active,
);

/// Bir konum + gün için tam solunar sonucu: efemeris + skor.
class DayResult {
  final SavedLocation location;
  final DateTime localDate;
  final DayEphemeris ephemeris;
  final SolunarDay solunar;

  const DayResult({
    required this.location,
    required this.localDate,
    required this.ephemeris,
    required this.solunar,
  });
}

/// Konum + yerel takvim günü anahtarıyla solunar sonucu hesaplar. Saf, offline,
/// senkron. Takvim/Gün Detayı ekranları bugünden farklı günler için bunu kullanır.
final solunarForDateProvider =
    Provider.family<DayResult, ({SavedLocation location, DateTime localDate})>((
      ref,
      key,
    ) {
      final eph = ref.watch(ephemerisSourceProvider);
      final engine = ref.watch(solunarEngineProvider);

      // O günün gerçek ofseti IANA tz'den çözülür — DST dahil (T2 önlemi).
      final offset = AppTimeZone.offsetForLocalDate(
        key.location.timeZoneId,
        key.localDate,
      );

      final ephemeris = eph.computeDay(
        year: key.localDate.year,
        month: key.localDate.month,
        day: key.localDate.day,
        position: GeoPosition(
          latitude: key.location.latitude,
          longitude: key.location.longitude,
        ),
        utcOffset: offset,
      );

      return DayResult(
        location: key.location,
        localDate: DateTime(
          key.localDate.year,
          key.localDate.month,
          key.localDate.day,
        ),
        ephemeris: ephemeris,
        solunar: engine.evaluate(ephemeris),
      );
    });

/// Aktif konumun *bugünkü* yerel takvim günü (IANA tz'ye göre).
DateTime localToday(SavedLocation location) {
  final now = AppTimeZone.nowInZone(location.timeZoneId);
  return DateTime(now.year, now.month, now.day);
}

/// Aktif konum için bugünün solunar sonucu — ilk ekran render'ı için ağ
/// BEKLENMEZ; hava katmanı ayrı provider'dan gelip yeniden hesaplatacak.
final todayResultProvider = Provider<DayResult>((ref) {
  final location = ref.watch(activeLocationProvider);
  return ref.watch(
    solunarForDateProvider((
      location: location,
      localDate: localToday(location),
    )),
  );
});
