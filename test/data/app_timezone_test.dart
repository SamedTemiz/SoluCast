import 'package:flutter_test/flutter_test.dart';
import 'package:angler_pulse/data/timezone/app_timezone.dart';

/// IANA tz doğruluğu (T2 önlemi — "rakiplerin 'saatler yanlış' şikâyetinin
/// ana nedeni" budur). Kuzey/Güney yarıküre DST'sinin ters yönlü olduğunu ve
/// DST uygulamayan bölgelerin (Türkiye, 2016'dan beri) sabit kaldığını
/// doğrular — hemisfer varsayımı hardcode edilmiş olsaydı bu testler yakalardı.
void main() {
  group('offsetForLocalDate — DST doğruluğu', () {
    test('New York: kışın EST (UTC-5), yazın EDT (UTC-4)', () {
      final winter = AppTimeZone.offsetForLocalDate(
        'America/New_York',
        DateTime(2026, 1, 15),
      );
      final summer = AppTimeZone.offsetForLocalDate(
        'America/New_York',
        DateTime(2026, 7, 15),
      );
      expect(winter, const Duration(hours: -5));
      expect(summer, const Duration(hours: -4));
    });

    test('Los Angeles: kışın PST (UTC-8), yazın PDT (UTC-7)', () {
      final winter = AppTimeZone.offsetForLocalDate(
        'America/Los_Angeles',
        DateTime(2026, 1, 15),
      );
      final summer = AppTimeZone.offsetForLocalDate(
        'America/Los_Angeles',
        DateTime(2026, 7, 15),
      );
      expect(winter, const Duration(hours: -8));
      expect(summer, const Duration(hours: -7));
    });

    test(
      'İstanbul: Türkiye 2016dan beri DST uygulamıyor → yıl boyu +3 sabit',
      () {
        final winter = AppTimeZone.offsetForLocalDate(
          'Europe/Istanbul',
          DateTime(2026, 1, 15),
        );
        final summer = AppTimeZone.offsetForLocalDate(
          'Europe/Istanbul',
          DateTime(2026, 7, 15),
        );
        expect(winter, const Duration(hours: 3));
        expect(summer, const Duration(hours: 3));
      },
    );

    test('Oslo (Tromsø tz\'si): AB DST kuralına göre kışın +1, yazın +2', () {
      final winter = AppTimeZone.offsetForLocalDate(
        'Europe/Oslo',
        DateTime(2026, 1, 15),
      );
      final summer = AppTimeZone.offsetForLocalDate(
        'Europe/Oslo',
        DateTime(2026, 7, 15),
      );
      expect(winter, const Duration(hours: 1));
      expect(summer, const Duration(hours: 2));
    });

    test(
      'Sydney: Güney yarıküre — Ocak (yaz) +11 DST, Temmuz (kış) +10 — TERS yönlü',
      () {
        final januarySummer = AppTimeZone.offsetForLocalDate(
          'Australia/Sydney',
          DateTime(2026, 1, 15),
        );
        final julyWinter = AppTimeZone.offsetForLocalDate(
          'Australia/Sydney',
          DateTime(2026, 7, 15),
        );
        // Kuzey yarıkürenin tersi: DST burada Ocak'ta aktif, Temmuz'da değil.
        expect(januarySummer, const Duration(hours: 11));
        expect(julyWinter, const Duration(hours: 10));
      },
    );
  });

  group(
    'DST geçiş günleri — motor çökmeden/anlamsız veri üretmeden çalışır',
    () {
      test('New York bahar-ileri (2026-03-08, saat 02:00→03:00)', () {
        // Geçiş gününün öğlen ofseti zaten yeni (EDT) taraftadır.
        final offset = AppTimeZone.offsetForLocalDate(
          'America/New_York',
          DateTime(2026, 3, 8),
        );
        expect(offset, const Duration(hours: -4));
      });

      test('New York güz-geri (2026-11-01, saat 02:00→01:00)', () {
        final offset = AppTimeZone.offsetForLocalDate(
          'America/New_York',
          DateTime(2026, 11, 1),
        );
        expect(offset, const Duration(hours: -5));
      });
    },
  );

  group('nowInZone', () {
    test(
      'farklı tz kimlikleri farklı duvar saatleri döndürür (tutarlılık)',
      () {
        final ny = AppTimeZone.nowInZone('America/New_York');
        final sydney = AppTimeZone.nowInZone('Australia/Sydney');
        // Aynı anda farklı yerel saat — en az birkaç saat fark olmalı.
        expect(ny.timeZoneOffset, isNot(sydney.timeZoneOffset));
      },
    );
  });
}
