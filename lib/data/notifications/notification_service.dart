import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../timezone/app_timezone.dart';
import 'notification_plan.dart';

/// Bildirim zamanlayıcı arayüzü — test/web'de [NoopNotificationScheduler] ile
/// değiştirilebilir (platform kanalı olmayan ortamlarda çalışmaz).
abstract interface class NotificationScheduler {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> reschedule({
    required List<PlannedNotification> plan,
    required String timeZoneId,
  });
  Future<void> cancelAll();
}

/// Platform kanalı olmayan ortamlar (birim test, web) için sessiz uygulama.
class NoopNotificationScheduler implements NotificationScheduler {
  const NoopNotificationScheduler();

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermissions() async => false;
  @override
  Future<void> reschedule({
    required List<PlannedNotification> plan,
    required String timeZoneId,
  }) async {}
  @override
  Future<void> cancelAll() async {}
}

/// Yerel bildirimleri cihazda zamanlar (F5) — **push sunucusu yok**.
/// Planlama mantığı [planNotifications]'ta (saf, testli); burası yalnız
/// platform sarmalayıcısı.
///
/// Zamanlama konumun IANA tz'sinde [tz.TZDateTime] ile yapılır → DST geçişinde
/// bildirim kaymaz (T2/T4 önlemi).
///
/// **Savunmacı:** bildirimler kritik değil — plugin/platform hatası uygulamayı
/// çökertmez, sessizce yutulur (uygulama bildirimsiz çalışmaya devam eder).
class NotificationService implements NotificationScheduler {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'solunar_daily';
  static const _channelName = 'Fishing forecast';
  static const _channelDescription =
      'Daily solunar summary and high-score day alerts';

  @override
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      AppTimeZone.ensureInitialized();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.initialize atlandı: $e');
    }
  }

  /// Android 13+ bildirim izni + tam alarm izni. Kullanıcı reddederse
  /// uygulama çalışmaya devam eder (bildirim yok).
  @override
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;
      final granted = await android.requestNotificationsPermission() ?? false;
      // Tam alarm izni (Android 14+): reddedilirse inexact'e düşeriz.
      await android.requestExactAlarmsPermission();
      return granted;
    } catch (e) {
      debugPrint('NotificationService.requestPermissions atlandı: $e');
      return false;
    }
  }

  /// Planı cihazda kurar. Her açılışta çağrılır → **self-healing** (T4):
  /// önce hepsi iptal, sonra güncel plan yazılır (mükerrer olmaz).
  @override
  Future<void> reschedule({
    required List<PlannedNotification> plan,
    required String timeZoneId,
  }) async {
    if (kIsWeb) return;
    try {
      await initialize();
      if (!_initialized) return; // platform yok → sessizce çık
      await _plugin.cancelAll();
      if (plan.isEmpty) return;

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final exactAllowed =
          await android?.canScheduleExactNotifications() ?? false;
      final mode = exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      final location = tz.getLocation(timeZoneId);
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );

      for (final p in plan) {
        final when = tz.TZDateTime(
          location,
          p.scheduledLocal.year,
          p.scheduledLocal.month,
          p.scheduledLocal.day,
          p.scheduledLocal.hour,
          p.scheduledLocal.minute,
        );
        // Yarış koşulu: plan üretimi ile kurulum arasında zaman geçmiş olabilir.
        if (!when.isAfter(tz.TZDateTime.now(location))) continue;

        await _plugin.zonedSchedule(
          id: p.id,
          title: p.title,
          body: p.body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: mode,
        );
      }
    } catch (e) {
      debugPrint('NotificationService.reschedule atlandı: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService.cancelAll atlandı: $e');
    }
  }

  /// Kurulu bildirimler — cihaz testinde doğrulama için.
  Future<List<PendingNotificationRequest>> pending() async {
    if (kIsWeb) return const [];
    return _plugin.pendingNotificationRequests();
  }
}
