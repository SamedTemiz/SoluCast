/// Bir gözlemci konumu.
///
/// [longitude] **doğu-pozitif** (standart GPS / coğrafi gösterim). Astronomi
/// motoru içeride Meeus'un batı-pozitif geleneğine çevirir; dış API doğu-pozitif
/// kalır ki cihazdan gelen GPS değeri doğrudan kullanılabilsin.
class GeoPosition {
  /// Enlem, derece. Kuzey pozitif. [-90, 90].
  final double latitude;

  /// Boylam, derece. **Doğu pozitif**. [-180, 180].
  final double longitude;

  const GeoPosition({required this.latitude, required this.longitude});

  @override
  String toString() =>
      'GeoPosition(${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
}
