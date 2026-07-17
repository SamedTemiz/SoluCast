import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/prefs/preferences.dart';

/// 24 saat formatı mı? Kalıcı (shared_preferences). Todayfmt bunu gerçekten
/// uygular.
class Use24h extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(PrefKeys.use24h) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(PrefKeys.use24h, value);
  }
}

final use24hProvider = NotifierProvider<Use24h, bool>(Use24h.new);

enum UnitSystem { imperial, metric }

/// F8.1 birim tercihi — kalıcı; hava katmanı gelince gerçek dönüşüm uygulanır.
class Units extends Notifier<UnitSystem> {
  @override
  UnitSystem build() {
    final v = ref.watch(sharedPreferencesProvider).getString(PrefKeys.units);
    return v == 'metric' ? UnitSystem.metric : UnitSystem.imperial;
  }

  void set(UnitSystem value) {
    state = value;
    ref
        .read(sharedPreferencesProvider)
        .setString(PrefKeys.units, value.name);
  }
}

final unitsProvider = NotifierProvider<Units, UnitSystem>(Units.new);

/// Bildirim tercihleri — F5. Zamanlama Hafta 3 kapsamı; durum kalıcı.
class NotificationPrefs {
  final bool dailySummary;
  final bool highScoreAlert;
  const NotificationPrefs(
      {this.dailySummary = true, this.highScoreAlert = true});

  NotificationPrefs copyWith({bool? dailySummary, bool? highScoreAlert}) =>
      NotificationPrefs(
        dailySummary: dailySummary ?? this.dailySummary,
        highScoreAlert: highScoreAlert ?? this.highScoreAlert,
      );
}

class NotificationSettings extends Notifier<NotificationPrefs> {
  @override
  NotificationPrefs build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return NotificationPrefs(
      dailySummary: prefs.getBool(PrefKeys.notifDailySummary) ?? true,
      highScoreAlert: prefs.getBool(PrefKeys.notifHighScore) ?? true,
    );
  }

  void setDailySummary(bool v) {
    state = state.copyWith(dailySummary: v);
    ref.read(sharedPreferencesProvider).setBool(PrefKeys.notifDailySummary, v);
  }

  void setHighScoreAlert(bool v) {
    state = state.copyWith(highScoreAlert: v);
    ref.read(sharedPreferencesProvider).setBool(PrefKeys.notifHighScore, v);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettings, NotificationPrefs>(
        NotificationSettings.new);
