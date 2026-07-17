import 'package:flutter_test/flutter_test.dart';
import 'package:solucast/features/shared/entitlement.dart';

void main() {
  final today = DateTime(2026, 7, 15);

  group('isDateLocked (F4.3)', () {
    test('bugün her zaman açık', () {
      expect(
          isDateLocked(candidateLocalDate: today, todayLocalDate: today, isPro: false),
          isFalse);
    });

    test('yarın ücretsizde açık', () {
      final tomorrow = today.add(const Duration(days: 1));
      expect(
          isDateLocked(candidateLocalDate: tomorrow, todayLocalDate: today, isPro: false),
          isFalse);
    });

    test('2 gün sonrası ücretsizde kilitli', () {
      final dayAfterTomorrow = today.add(const Duration(days: 2));
      expect(
          isDateLocked(
              candidateLocalDate: dayAfterTomorrow, todayLocalDate: today, isPro: false),
          isTrue);
    });

    test('geçmiş günler kilitli değil', () {
      final yesterday = today.subtract(const Duration(days: 1));
      expect(
          isDateLocked(candidateLocalDate: yesterday, todayLocalDate: today, isPro: false),
          isFalse);
    });

    test('Pro iken hiçbir gün kilitli değil', () {
      final farFuture = today.add(const Duration(days: 30));
      expect(
          isDateLocked(candidateLocalDate: farFuture, todayLocalDate: today, isPro: true),
          isFalse);
    });
  });

  group('isLocationAddLocked (F1.3)', () {
    test('ücretsizde 1 konum sonrası kilitli', () {
      expect(isLocationAddLocked(currentCount: 1, isPro: false), isTrue);
      expect(isLocationAddLocked(currentCount: 0, isPro: false), isFalse);
    });

    test('Pro iken hiç kilitli değil', () {
      expect(isLocationAddLocked(currentCount: 5, isPro: true), isFalse);
    });
  });
}
