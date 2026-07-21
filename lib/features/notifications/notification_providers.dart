import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization.dart';
import '../../data/notifications/notification_plan.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/timezone/app_timezone.dart';
import '../settings/settings_providers.dart';
import '../shared/entitlement.dart';
import '../today/today_format.dart';
import '../today/today_providers.dart';

/// Testlerde/web'de [NoopNotificationScheduler] ile override edilebilir.
final notificationServiceProvider = Provider<NotificationScheduler>(
  (ref) => NotificationService(),
);

/// Önümüzdeki [days] gün için gerçek skorlardan bildirim planı üretir.
/// Astronomi offline hesaplandığı için plan ağ olmadan da doğrudur.
List<NotifiableDay> buildNotifiableDays(Ref ref, {int days = 7}) {
  final location = ref.watch(activeLocationProvider);
  final today = localToday(location);
  final use24h = ref.watch(use24hProvider);

  return List.generate(days, (i) {
    final date = today.add(Duration(days: i));
    final result = ref.watch(
      solunarForDateProvider((location: location, localDate: date)),
    );
    final fmt = TodayFormat(result.ephemeris.utcOffset, use24h: use24h);
    final majors = result.solunar.majorPeriods;
    return NotifiableDay(
      localDate: date,
      fishRating: result.solunar.fishRating,
      majorWindows: [
        for (final major in majors)
          NotifiableMajorWindow(
            startLocal: major.start.add(result.ephemeris.utcOffset),
            label: '${fmt.time(major.start)}-${fmt.time(major.end)}',
          ),
      ],
      firstMajorStartLocal: majors.isEmpty
          ? null
          : majors.first.start.add(result.ephemeris.utcOffset),
      firstMajorWindow: majors.isEmpty
          ? null
          : '${fmt.time(majors.first.start)}–${fmt.time(majors.first.end)}',
    );
  });
}

/// Güncel tercih + skorlara göre plan. Tercih ya da konum değişince yeniden
/// hesaplanır → [notificationSchedulerProvider] onu cihaza yazar.
final notificationPlanProvider = Provider<List<PlannedNotification>>((ref) {
  final prefs = ref.watch(notificationSettingsProvider);
  final language = ref.watch(languagePreferenceProvider);
  final location = ref.watch(activeLocationProvider);
  final smartAlertsAllowed = ref.watch(smartAlertsEntitlementProvider);

  // Plan zamanları konumun yerel duvar saatinde; "şimdi"yi de aynı tz'de al —
  // aktif konum başka bir zaman dilimindeyse cihaz saati yanlış olurdu.
  final nowLocal = AppTimeZone.nowInZone(location.timeZoneId);

  return planNotifications(
    days: buildNotifiableDays(ref),
    nowLocal: DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
      nowLocal.hour,
      nowLocal.minute,
    ),
    dailySummaryEnabled: prefs.dailySummary,
    highScoreAlertEnabled: prefs.highScoreAlert,
    smartAlertEnabled: smartAlertsAllowed && prefs.smartAlert,
    smartMinRating: prefs.smartMinRating,
    smartLeadMinutes: prefs.smartLeadMinutes,
    turkish: language == AppLanguage.turkish,
  );
});

/// Uygulama açılışında ve tercih/konum değişiminde bildirimleri yeniden kurar
/// (self-healing, T4). `main` bunu bir kez okur; sonrası otomatik.
final notificationSchedulerProvider = Provider<void>((ref) {
  final plan = ref.watch(notificationPlanProvider);
  final location = ref.watch(activeLocationProvider);
  final service = ref.watch(notificationServiceProvider);
  // Yan etki build fazında çalışmamalı. Özellikle Pro durumu değiştiğinde
  // provider grafiği eşzamanlı yeniden hesaplanır; planlamayı bir mikro göreve
  // bırakmak Riverpod'un "modified during build" korumasını ihlal etmez.
  Future<void>.microtask(
    () => service.reschedule(plan: plan, timeZoneId: location.timeZoneId),
  );
});
