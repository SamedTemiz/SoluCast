import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama açılışında [main] tarafından önceden yüklenip
/// [ProviderScope.overrides] ile sağlanır. Böylece Notifier'lar `build()`
/// içinde senkron okuyabilir (tercihler ekran ilk kareden önce hazır).
///
/// Konum verisi cihazda kalır, sunucuya gönderilmez (F1.4 gizlilik).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider main() içinde override edilmeli',
  ),
);

/// Kalıcılık anahtarları — tek yerde toplanır.
class PrefKeys {
  PrefKeys._();
  static const locations = 'locations_json';
  static const activeLocation = 'active_location_name';
  static const use24h = 'use_24h';
  static const units = 'units';
  static const proPreview = 'pro_preview';
  static const notifDailySummary = 'notif_daily_summary';
  static const notifHighScore = 'notif_high_score';
  static const notifSmartAlert = 'notif_smart_alert';
  static const notifSmartMinRating = 'notif_smart_min_rating';
  static const notifSmartLeadMinutes = 'notif_smart_lead_minutes';
  static const spotCompareTimeMinutes = 'spot_compare_time_minutes';
  static const onboardingDone = 'onboarding_done';
  static const themeMode = 'theme_mode';
  static const language = 'language';
}
