/// Bildirim planlama — **saf mantık** (plugin/IO yok) → tam test edilebilir.
/// Servis katmanı bu planı alıp cihazda zamanlar (F5).
library;

enum PlannedKind { dailySummary, highScoreAlert }

/// Zamanlanacak tek bir bildirim. [scheduledLocal] konumun yerel duvar saati;
/// servis onu konumun IANA tz'sinde TZDateTime'a çevirir (DST doğru).
class PlannedNotification {
  final int id;
  final PlannedKind kind;
  final DateTime scheduledLocal;
  final String title;
  final String body;

  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.scheduledLocal,
    required this.title,
    required this.body,
  });
}

/// Planlayıcıya verilen tek günlük özet (UI/motor katmanından derlenir).
class NotifiableDay {
  final DateTime localDate;
  final int fishRating; // 1..5
  final String? firstMajorWindow; // "06:40–08:40" (yoksa null)

  const NotifiableDay({
    required this.localDate,
    required this.fishRating,
    this.firstMajorWindow,
  });
}

/// Kimlik aralıkları — yeniden planlamada çakışmayı önler (stabil id).
const dailySummaryIdBase = 1000;
const highScoreIdBase = 2000;

/// IDs owned by the rolling forecast scheduler. Period reminders use a
/// different range and must survive an automatic forecast refresh.
Iterable<int> managedForecastNotificationIds({int days = 14}) sync* {
  for (var i = 0; i < days; i++) {
    yield dailySummaryIdBase + i;
    yield highScoreIdBase + i;
  }
}

/// [days] için bildirimleri planlar.
///
/// - Günlük özet: her gün [summaryHour]:[summaryMinute]'de (F5.1).
/// - Yüksek skor uyarısı: derece ≥ [highScoreThreshold] olan günden **bir önceki
///   akşam** [alertHour]'da (F5.2 "akşam önce").
/// - [nowLocal]'dan önceki zamanlar atlanır (geçmişe bildirim kurulmaz).
List<PlannedNotification> planNotifications({
  required List<NotifiableDay> days,
  required DateTime nowLocal,
  required bool dailySummaryEnabled,
  required bool highScoreAlertEnabled,
  int summaryHour = 7,
  int summaryMinute = 0,
  int alertHour = 18,
  int highScoreThreshold = 4,
  bool turkish = false,
}) {
  final planned = <PlannedNotification>[];

  for (var i = 0; i < days.length; i++) {
    final day = days[i];

    if (dailySummaryEnabled) {
      final at = DateTime(
        day.localDate.year,
        day.localDate.month,
        day.localDate.day,
        summaryHour,
        summaryMinute,
      );
      if (at.isAfter(nowLocal)) {
        final window = day.firstMajorWindow;
        planned.add(
          PlannedNotification(
            id: dailySummaryIdBase + i,
            kind: PlannedKind.dailySummary,
            scheduledLocal: at,
            title: turkish
                ? 'Bugün: ${day.fishRating}/5'
                : 'Today: ${day.fishRating}/5',
            body: window == null
                ? (turkish
                      ? 'Bugünün solunar dönemlerini görmek için dokunun.'
                      : 'Tap to see today\'s solunar periods.')
                : (turkish
                      ? 'En iyi aralık — ana dönem $window'
                      : 'Best window — major $window'),
          ),
        );
      }
    }

    if (highScoreAlertEnabled && day.fishRating >= highScoreThreshold) {
      // Yüksek skorlu günden bir önceki akşam haber ver.
      final eve = DateTime(
        day.localDate.year,
        day.localDate.month,
        day.localDate.day,
        alertHour,
      ).subtract(const Duration(days: 1));
      if (eve.isAfter(nowLocal)) {
        planned.add(
          PlannedNotification(
            id: highScoreIdBase + i,
            kind: PlannedKind.highScoreAlert,
            scheduledLocal: eve,
            title: turkish
                ? 'Yarın iyi görünüyor: ${day.fishRating}/5'
                : 'Tomorrow looks good: ${day.fishRating}/5',
            body: turkish
                ? 'Planınızı yapın — koşullar yarın uyumlu.'
                : 'Plan your trip — conditions line up tomorrow.',
          ),
        );
      }
    }
  }

  planned.sort((a, b) => a.scheduledLocal.compareTo(b.scheduledLocal));
  return planned;
}
