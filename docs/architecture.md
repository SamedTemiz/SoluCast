# Mimari

## 1. Genel yaklaşım

**Sunucusuz (backend'siz) Flutter uygulaması.** Nisteia ile aynı felsefe:
çekirdek hesaplar saf Dart'ta cihazda, dış bağımlılık yalnız hava durumu API'si.
Bakım maliyeti ≈ 0; ölçek maliyeti ≈ API abonelik ücreti.

```
┌─────────────────────────────────────────────┐
│                 Flutter App                 │
│                                             │
│  UI (features/)                             │
│   today | calendar | locations | settings   │
│   paywall | onboarding                      │
│         │                                   │
│  State (Riverpod providers)                 │
│         │                                   │
│  ┌──────┴───────────────────────────────┐   │
│  │ core/  — SAF DART, %100 offline      │   │
│  │  astro/   güneş-ay efemeris (Meeus)  │   │
│  │  solunar/ periyot + skor motoru      │   │
│  └──────┬───────────────────────────────┘   │
│         │                                   │
│  data/                                      │
│   weather_repo ──HTTP──► Open-Meteo API     │
│   geocoding_repo ─HTTP─► Open-Meteo Geocode │
│   local_store (drift/shared_prefs)          │
│   purchases (RevenueCat)                    │
│   ads (AdMob)                               │
│   notifications (local, planlı)             │
│   widget_bridge (home_widget)               │
└─────────────────────────────────────────────┘
```

## 2. Katmanlar

### core/ — hesap motoru (uygulamanın kalesi)
- `core/astro/` — Jean Meeus "Astronomical Algorithms" tabanlı:
  - güneş doğuş/batış + alacakaranlık
  - ay doğuş/batış, transit (üst/alt meridyen geçişi), faz, aydınlanma
  - Hazır paket değerlendirmesi: pub.dev'de `astronomy` / `sweph` portları var;
    önce bunlar denenir, doğruluk yetmezse Meeus'tan kendimiz yazarız
    (Nisteia'da `paschalion.dart`'ı kendimiz yazdık, aynı yaklaşım).
- `core/solunar/` —
  - `periods.dart`: major (transit ±60 dk) / minor (doğuş-batış ±30 dk) hesaplama
  - `score.dart`: 0–100 skor motoru. Girdiler ve ağırlıklar:
    - ay fazı (yeni/dolunay pik) — %35
    - periyot ↔ şafak/akşam çakışması — %25
    - basınç trendi (düşüş öncesi pik) — %20 *(hava verisi varsa; yoksa ağırlık dağıtılır)*
    - mevsim/normalizasyon — %20
  - Ağırlıklar sabit dosyada (`score_weights.dart`) → A/B ya da ayar değişikliği kolay
- **Kural:** `core/` hiçbir Flutter/IO import'u içermez → saf birim test edilebilir

### data/
- `weather_repository.dart` — Open-Meteo forecast çağrısı; 1 saat TTL cache (drift tablosu);
  hata durumunda son cache + `staleness` bilgisi döner. API anahtarı yok (launch'ta
  ticari anahtar `--dart-define` ile).
- `geocoding_repository.dart` — Open-Meteo şehir araması (ücretsiz, anahtar yok);
  cihazın mevcut konumu için platform ters-geocoding'i yer adı çözümlemesi yapar,
  başarısız olursa koordinat etiketi kullanılır
- `location_store.dart` — kayıtlı konumlar (drift)
- `settings_store.dart` — shared_preferences
- `entitlement_service.dart` — RevenueCat (`purchases_flutter`); `isPro` stream'i
- `notification_scheduler.dart` — her gece + uygulama açılışında gelecek 7 günü hesaplar,
  lokal bildirimleri (yeniden) planlar
- `widget_service.dart` — `home_widget` ile Android widget'a veri yazar

### features/ (UI)
- `today/`, `calendar/`, `day_detail/`, `locations/`, `settings/`, `paywall/`, `onboarding/`
- Her feature: `*_screen.dart` + küçük widget'lar + provider'lar (Nisteia dizin düzeniyle aynı)

## 3. Paketler

| Amaç | Paket |
|---|---|
| State | `flutter_riverpod` |
| Model/immutable | `freezed` + `json_serializable` |
| DB/cache | `drift` (hava cache + konumlar) |
| Tercihler | `shared_preferences` |
| HTTP | `dio` |
| Konum | `geolocator` + `geocoding` |
| Bildirim | `flutter_local_notifications` + `timezone` |
| Widget | `home_widget` |
| Abonelik | `purchases_flutter` (RevenueCat) |
| Reklam | `google_mobile_ads` |
| Grafik | `fl_chart` (saatlik aktivite eğrisi) |
| i18n | Flutter gen-l10n (`l10n.yaml`, Nisteia ile aynı) |
| Analytics/Crash | `firebase_analytics` + `firebase_crashlytics` (minimal event seti) |

## 4. Kritik teknik kararlar

1. **Zaman dilimi doğruluğu:** Tüm hesaplar konumun IANA timezone'unda yapılır
   (`timezone` paketi + koordinattan tz çözümü — Open-Meteo geocoding tz döndürüyor).
   Rakiplerin "saatler yanlış" şikâyetinin ana nedeni bu; bizim ana test alanımız.
2. **DST geçişleri:** Bildirim planlama timezone-aware; test senaryosu zorunlu.
3. **Kutup/yüksek enlem:** Ay bazı günler doğmaz/batmaz — motor `null` dönebilmeli, UI
   "no moonrise today" gösterebilmeli (İskandinav pazarı için gerçek senaryo).
4. **Bildirimler tamamen lokal:** FCM/push sunucusu yok. Cihaz yeniden başlatılınca
   `BOOT_COMPLETED` receiver ile yeniden planlanır.
5. **Reklam ve satın alma soyutlaması:** `MonetizationGate` tek arayüz —
   `isPro == true` → reklam widget'ları hiç build edilmez.
6. **Konfigürasyon:** API uçları ve skor ağırlıkları tek `app_config.dart`'ta;
   ileride Remote Config'e taşınabilir ama MVP'de statik.

## 5. Test stratejisi (Nisteia modeli)

- `test/core/astro_test.dart` — USNO/timeanddate'ten alınan referans değerlerle
  **snapshot validasyonu**: 10+ konum (NY, Sydney, Tromsø, İstanbul, Anchorage…) ×
  4 mevsim × doğuş/batış/transit; tolerans ±2 dk.
  (Nisteia'daki `test/validation/snapshots/orthocal_*.json` yaklaşımının aynısı.)
- `test/core/solunar_test.dart` — periyot üretimi, skor sınır durumları
- `test/data/` — cache TTL, offline fallback
- Widget testleri: Bugün ekranı skeleton'u, paywall kilit akışı

## 6. Proje iskeleti

```
solucast/
├── lib/
│   ├── core/
│   │   ├── astro/        # efemeris (saf Dart)
│   │   └── solunar/      # periyot + skor
│   ├── data/             # repo'lar, store'lar, servisler
│   ├── features/
│   │   ├── today/  calendar/  day_detail/
│   │   ├── locations/  settings/
│   │   └── onboarding/  paywall/
│   ├── l10n/             # app_en.arb, app_tr.arb
│   └── main.dart
├── test/
│   ├── core/
│   └── validation/snapshots/   # USNO referans json'ları
├── android/  ios/  docs/
└── pubspec.yaml
```
