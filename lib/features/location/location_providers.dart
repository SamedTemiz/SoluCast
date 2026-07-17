import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/location/geocoding_repository.dart';
import '../../data/location/location_service.dart';
import '../../data/location/saved_location.dart';

/// Şehir arama kaynağı (Open-Meteo geocoding, sağlayıcı-bağımsız arayüz).
final geocodingRepositoryProvider = Provider<GeocodingRepository>(
  (ref) => OpenMeteoGeocodingRepository(),
);

/// GPS konum servisi.
final locationServiceProvider =
    Provider<LocationService>((ref) => const LocationService());

/// Arama sorgusuna göre konum sonuçları (debounce çağıran tarafta).
final geocodingSearchProvider =
    FutureProvider.family<List<SavedLocation>, String>((ref, query) async {
  if (query.trim().length < 2) return const [];
  return ref.watch(geocodingRepositoryProvider).search(query);
});
