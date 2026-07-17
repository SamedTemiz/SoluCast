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
const _dailySummaryIdBase = 1000;
const _highScoreIdBase = 2000;

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
}) {
  final planned = <PlannedNotification>[];

  for (var i = 0; i < days.length; i++) {
    final day = days[i];

    if (dailySummaryEnabled) {
      final at = DateTime(day.localDate.year, day.localDate.month,
          day.localDate.day, summaryHour, summaryMinute);
      if (at.isAfter(nowLocal)) {
        final window = day.firstMajorWindow;
        planned.add(PlannedNotification(
          id: _dailySummaryIdBase + i,
          kind: PlannedKind.dailySummary,
          scheduledLocal: at,
          title: 'Today: ${day.fishRating}/5',
          body: window == null
              ? 'Tap to see today\'s solunar periods.'
              : 'Best window — major $window',
        ));
      }
    }

    if (highScoreAlertEnabled && day.fishRating >= highScoreThreshold) {
      // Yüksek skorlu günden bir önceki akşam haber ver.
      final eve = DateTime(day.localDate.year, day.localDate.month,
              day.localDate.day, alertHour)
          .subtract(const Duration(days: 1));
      if (eve.isAfter(nowLocal)) {
        planned.add(PlannedNotification(
          id: _highScoreIdBase + i,
          kind: PlannedKind.highScoreAlert,
          scheduledLocal: eve,
          title: 'Tomorrow looks good: ${day.fishRating}/5',
          body: 'Plan your trip — conditions line up tomorrow.',
        ));
      }
    }
  }

  planned.sort((a, b) => a.scheduledLocal.compareTo(b.scheduledLocal));
  return planned;
}
