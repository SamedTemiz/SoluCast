import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'saved_location.dart';

/// GPS ile kullanıcının **mevcut konumu** (F1.1). Koordinat geolocator'dan;
/// zaman dilimi cihazın IANA kimliğinden (kullanıcı fiziksel olarak orada
/// olduğu için cihaz tz'si = konumun tz'si → DST doğru). İsim reverse-geocoding
/// yerine şimdilik "Current Location" (v1.1'de yer adına çevrilebilir).
///
/// Konum cihaz dışına çıkmaz, sunucuya gönderilmez (F1.4 gizlilik).
class LocationService {
  const LocationService();

  /// İzin akışı + konum. Servis kapalı / izin reddedilirse [LocationFailure]
  /// fırlatır (çağıran manuel aramaya yönlendirir).
  Future<SavedLocation> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        LocationFailureReason.serviceDisabled,
        'Location services are turned off.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationFailure(
        permission == LocationPermission.deniedForever
            ? LocationFailureReason.permissionDeniedForever
            : LocationFailureReason.permissionDenied,
        'Location permission was not granted.',
      );
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    final tz = await FlutterTimezone.getLocalTimezone();
    final name = await _displayNameFor(pos);

    return SavedLocation(
      name: name,
      latitude: pos.latitude,
      longitude: pos.longitude,
      timeZoneId: tz.identifier,
      isDeviceLocation: true,
    );
  }

  Future<String> _displayNameFor(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = _firstPopulated([
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
        ]);
        final country = place.country?.trim();
        final parts = [locality, country]
            .whereType<String>()
            .where((part) => part.isNotEmpty)
            .toSet()
            .toList();
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (_) {
      // Platform geocoder kullanılamıyorsa konum işlevi bozulmaz.
    }

    return _coordinateLabel(position.latitude, position.longitude);
  }

  String? _firstPopulated(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String _coordinateLabel(double latitude, double longitude) {
    final ns = latitude >= 0 ? 'N' : 'S';
    final ew = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}° $ns, '
        '${longitude.abs().toStringAsFixed(4)}° $ew';
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationFailure implements Exception {
  final LocationFailureReason reason;
  final String message;
  const LocationFailure(this.reason, this.message);
  @override
  String toString() => 'LocationFailure: $message';
}
