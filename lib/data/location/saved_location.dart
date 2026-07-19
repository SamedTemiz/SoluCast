/// Kayıtlı/aktif bir konum. [timeZoneId] IANA zaman dilimi kimliğidir (ör.
/// `Europe/Istanbul`); gerçek geocoding akışında Open-Meteo'nun döndürdüğü
/// tz'den gelir. Ofset buradan **statik olarak saklanmaz** — DST'yi doğru
/// yansıtmak için her sorguda [AppTimeZone] ile o güne göre çözülür (T2 önlemi).
class SavedLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String timeZoneId;
  final bool isDeviceLocation;

  const SavedLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timeZoneId,
    this.isDeviceLocation = false,
  });

  /// Kalıcılık için JSON. GPS/geocoding ile eklenen özel konumlar da böylece
  /// preset'e bağlı kalmadan saklanır.
  Map<String, dynamic> toJson() => {
    'name': name,
    'lat': latitude,
    'lon': longitude,
    'tz': timeZoneId,
    'isDeviceLocation': isDeviceLocation,
  };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
    name: json['name'] as String,
    latitude: (json['lat'] as num).toDouble(),
    longitude: (json['lon'] as num).toDouble(),
    timeZoneId: json['tz'] as String,
    isDeviceLocation: json['isDeviceLocation'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      other is SavedLocation &&
      other.name == name &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.timeZoneId == timeZoneId &&
      other.isDeviceLocation == isDeviceLocation;

  @override
  int get hashCode =>
      Object.hash(name, latitude, longitude, timeZoneId, isDeviceLocation);

  /// Demo/örnek konum — konum izni gelmeden boş ekran yerine canlı önizleme
  /// (screens.md "İstanbul/örnek konumla demo veri" kuralı). Not: Türkiye
  /// 2016'dan beri DST uygulamıyor → yıl boyu sabit +3.
  static const demo = SavedLocation(
    name: 'İstanbul',
    latitude: 41.0082,
    longitude: 28.9784,
    timeZoneId: 'Europe/Istanbul',
  );

  /// Arama boşken gösterilen hızlı öneriler — gerçek IANA kimlikleriyle,
  /// DST'yi doğru yansıtır. Kuzey/Güney yarıküre + kutup kasıtlı çeşitlilikte.
  /// (GPS + serbest arama asıl akış; bunlar yalnız kısayol.)
  static const presets = [
    demo,
    SavedLocation(
      name: 'Miami',
      latitude: 25.7617,
      longitude: -80.1918,
      timeZoneId: 'America/New_York',
    ),
    SavedLocation(
      name: 'Lake Tahoe',
      latitude: 39.0968,
      longitude: -120.0324,
      timeZoneId: 'America/Los_Angeles',
    ),
    SavedLocation(
      name: 'Chesapeake Bay',
      latitude: 37.5,
      longitude: -76.2,
      timeZoneId: 'America/New_York',
    ),
    SavedLocation(
      name: 'Sydney',
      latitude: -33.8688,
      longitude: 151.2093,
      timeZoneId: 'Australia/Sydney',
    ),
    SavedLocation(
      name: 'Tromsø',
      latitude: 69.6492,
      longitude: 18.9553,
      timeZoneId: 'Europe/Oslo',
    ),
  ];
}
