import 'package:flutter_test/flutter_test.dart';
import 'package:solucast/data/notifications/notification_plan.dart';

void main() {
  final today = DateTime(2026, 7, 16);
  final nowLocal = DateTime(2026, 7, 16, 9, 0); // bugün 09:00

  List<NotifiableDay> days({List<int> ratings = const [3, 5, 2]}) => [
        for (var i = 0; i < ratings.length; i++)
          NotifiableDay(
            localDate: today.add(Duration(days: i)),
            fishRating: ratings[i],
            firstMajorWindow: '06:40–08:40',
          ),
      ];

  test('günlük özet her gün seçilen saatte planlanır', () {
    final plan = planNotifications(
      days: days(),
      nowLocal: nowLocal,
      dailySummaryEnabled: true,
      highScoreAlertEnabled: false,
      summaryHour: 7,
    );
    final summaries =
        plan.where((p) => p.kind == PlannedKind.dailySummary).toList();
    // Bugünün 07:00'ı geçmiş (now=09:00) → atlanır; yarın + öbür gün kalır.
    expect(summaries, hasLength(2));
    expect(summaries.first.scheduledLocal, DateTime(2026, 7, 17, 7));
    expect(summaries.first.title, contains('/5'));
  });

  test('geçmiş zamana bildirim kurulmaz', () {
    final plan = planNotifications(
      days: days(ratings: [3]), // yalnız bugün
      nowLocal: nowLocal, // 09:00 > 07:00
      dailySummaryEnabled: true,
      highScoreAlertEnabled: false,
    );
    expect(plan, isEmpty);
  });

  test('yüksek skorlu gün (≥4) bir önceki akşam uyarı üretir', () {
    final plan = planNotifications(
      days: days(ratings: [3, 5, 2]), // index 1 = yarın, 5/5
      nowLocal: nowLocal,
      dailySummaryEnabled: false,
      highScoreAlertEnabled: true,
    );
    expect(plan, hasLength(1));
    final alert = plan.first;
    expect(alert.kind, PlannedKind.highScoreAlert);
    // Yarın (17 Tem) 5/5 → uyarı bugün (16 Tem) 18:00'de
    expect(alert.scheduledLocal, DateTime(2026, 7, 16, 18));
    expect(alert.title, contains('5/5'));
  });

  test('düşük skorlu günler uyarı üretmez', () {
    final plan = planNotifications(
      days: days(ratings: [2, 3, 1]),
      nowLocal: nowLocal,
      dailySummaryEnabled: false,
      highScoreAlertEnabled: true,
    );
    expect(plan, isEmpty);
  });

  test('tercihler kapalıyken hiç bildirim planlanmaz', () {
    final plan = planNotifications(
      days: days(ratings: [5, 5, 5]),
      nowLocal: nowLocal,
      dailySummaryEnabled: false,
      highScoreAlertEnabled: false,
    );
    expect(plan, isEmpty);
  });

  test('id\'ler stabil ve türler arası çakışmaz (yeniden planlama güvenli)', () {
    final plan = planNotifications(
      days: days(ratings: [5, 5]),
      nowLocal: nowLocal,
      dailySummaryEnabled: true,
      highScoreAlertEnabled: true,
    );
    final ids = plan.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'id\'ler benzersiz olmalı');

    // Aynı girdiyle tekrar planla → aynı id'ler (replace, duplicate değil).
    final again = planNotifications(
      days: days(ratings: [5, 5]),
      nowLocal: nowLocal,
      dailySummaryEnabled: true,
      highScoreAlertEnabled: true,
    );
    expect(again.map((p) => p.id).toList(), ids);
  });

  test('sonuç zamana göre sıralı döner', () {
    final plan = planNotifications(
      days: days(ratings: [3, 5, 4]),
      nowLocal: nowLocal,
      dailySummaryEnabled: true,
      highScoreAlertEnabled: true,
    );
    for (var i = 1; i < plan.length; i++) {
      expect(
        plan[i].scheduledLocal.isBefore(plan[i - 1].scheduledLocal),
        isFalse,
        reason: 'sıralama bozuk',
      );
    }
  });

  test('major penceresi yoksa özet gövdesi güvenli metne düşer', () {
    final plan = planNotifications(
      days: [
        NotifiableDay(
            localDate: today.add(const Duration(days: 1)), fishRating: 3),
      ],
      nowLocal: nowLocal,
      dailySummaryEnabled: true,
      highScoreAlertEnabled: false,
    );
    expect(plan.first.body, contains('solunar periods'));
  });
}
