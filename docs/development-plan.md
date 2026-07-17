# Geliştirme Planı (Hızlı Yol — 6 Hafta)

*Hedef: ~6 haftada üretim yayını (Ağustos sonu – Eylül 2026).
Her haftanın içine ilgili risk önlemleri gömülüdür ([risks.md](risks.md) referanslarıyla).
Solo dev temposuna göre haftalar "odak blokları"dır — kayarsa sıra bozulmaz, süre uzar.*

> **Durum güncellemesi (18 Tem 2026):** Hafta 1–3 tamamlandı; Android debug APK
> gerçek cihazda derlenip yüklendi. `flutter analyze` temiz, 77 test yeşil. GPS,
> geocoding, IANA timezone, hava cache'i ve lokal bildirim altyapısı çalışır durumda.
> Son cihaz doğrulamasında konum seçici, ücretsiz/Pro konum sınırı ve küçük ekran
> taşması düzeltildi. Sıradaki ürün aşaması: monetizasyon.

## Hafta 1 — Çekirdek motor + kapalı test sayacını başlat 🔴

**Bu haftanın iki çıktısı pazarlıksız (S1 + T1 riskleri):**

- [x] Flutter projesi iskeleti (tema + dizin düzeni ✅; l10n altyapısı henüz yok)
- [x] `core/astro`: pub.dev paketleri denendi → **`astronomia` (MIT, Meeus portu)** seçildi;
      `sweph` AGPL nedeniyle elendi. `EphemerisSource` arayüzü arkasında değiştirilebilir.
- [x] Güneş/ay doğuş-batış-transit + faz hesabı çalışır durumda
- [x] **USNO validasyon snapshot'ları:** 9 konum-mevsim kombinasyonu (NY/İstanbul/Sydney/
      Singapore/Anchorage/Tromsø × solstis/ekinoks), testler yeşil (±2 dk) — T1 önlemi.
      Kapsam 10 konum × 4 mevsime genişletilebilir.
- [x] `core/solunar`: major/minor periyot üretimi + skor motoru v1 (ağırlıklar `score_weights.dart`'ta)
- [-] Play Console kapalı test süreci — **bu sürümün planı dışında**.
      Not: Kullandığın Play geliştirici hesabının üretim yayını için zorunlu tutması
      halinde, yayın öncesi yeniden planlanır.
- [x] Basit "Bugün" ekranı — plan aşıldı: gerçek Stitch tasarımıyla kuruldu

## Hafta 2 — Bugün ekranı + veri katmanı

- [x] `WeatherRepository` (provider-bağımsız arayüz) → **Open-Meteo ücretsiz uç** ile (O2: geçiş 1 günlük iş)
- [x] Basınç trendi hesabı + skora entegrasyonu *(gerçek Open-Meteo verisi → skor %20 basınç faktörü aktif; testli)*
- [x] Geocoding + GPS konum akışı; konum izni reddedilirse manuel arama (F1)
      *(GPS "mevcut konumum" + canlı Open-Meteo şehir arama; presetler öneri olarak kaldı.
      18 Tem: gerçek cihazda Android izin/servis kapalı akışı doğrulandı; servis kapalıysa
      sistem konum ayarlarına, izin kalıcı reddedilmişse uygulama ayarlarına yönlendirme eklendi.
      GPS sonucu platform ters-geocoding'iyle yer adına çevrilir; çözülemezse koordinat etiketi kullanılır.)*
- [x] Timezone çözümü: konumun IANA tz'siyle hesap; **DST geçiş günü birim testleri** (T2 önlemi)
- [x] Yüksek enlem edge case'leri: nullable moonrise, Tromsø/Anchorage testleri (T3 önlemi)
- [x] Bugün ekranı gerçek tasarımıyla: skor kartı, 24s timeline, güneş/ay kartı, hava şeridi (gerçek veri)
- [x] Hava cache (shared_preferences, 1 saat TTL) + offline fallback (bayat cache → veri)
      *(drift yerine prefs — MVP için yeterli; drift v1.1)*

## Hafta 3 — Takvim, konumlar, bildirimler

- [x] Haftalık şerit + gün detay ekranı (saatlik aktivite eğrisi, fl_chart)
- [x] Aylık görünüm — basit versiyon (skor renkli hücreler + kilit; ısı haritası cilası v1.1)
- [x] Konumlar ekranı: kaydet/sil (swipe), free=1 konum sınırı + upgrade teaser
      *(18 Tem: mevcut konum ücretsiz tek kayıt hakkını günceller; ikinci kayıt Pro'dur.
      Önceki preview'dan kalan ek kayıtlar silinmez, Pro kapalıyken kilitli tutulur.)*
- [x] Lokal bildirimler: günlük özet + yüksek skor uyarısı; her açılışta yeniden planlama
      (self-healing) + exact alarm izni + BOOT_COMPLETED receiver (T4 önlemi)
      *(planlama saf/testli — 8 test; cihazda doğrulanacak)*
- [x] Ayarlar ekranı: birimler (imperial default), 12/24s (çalışır), tema/dil satırları,
      bildirim tercihleri, "How is the score calculated?" şeffaflık sayfası
- [-] Kapalı test grubuna güncelleme — bu sürümün planı dışında

## Hafta 4 — Monetizasyon 🔴

**Bu hafta tamamen gelir kapısına ayrılır (M3 riski):**

- [ ] RevenueCat entegrasyonu; SKU'lar: aylık $3.99, yıllık $23.99 (7 gün deneme) — sadece 2 SKU
- [ ] Paywall ekranı + tetik noktaları (onboarding sonu, kilitli gün, 2. konum)
- [ ] Free/Pro kapıları: 14 gün tahmin, sınırsız konum, periyot hatırlatıcı, reklamsız
- [ ] **Test kartlarıyla uçtan uca test: satın al → restore → iptal → tekrar abone** (M3 önlemi)
- [ ] AdMob banner (yalnız Takvim ekranı) + **UMP consent akışı** (S3 önlemi)
- [ ] Firebase Analytics minimal event seti: paywall_view, trial_start, purchase, score_view

## Hafta 5 — Cila + widget + mağaza hazırlığı

- [ ] Android home-screen widget (küçük boy; orta boy v1.1'e atılabilir)
- [ ] Onboarding akışı (2-3 adım + soft paywall)
- [ ] In-app review prompt'u (yüksek skorlu günde, 3. kullanımdan sonra) — P1 önlemi
- [ ] "How is the score calculated?" şeffaflık sayfası
- [ ] **ASO paketi (P2 önlemi):** isim finali ("Solunar" + "Fishing Times" title'da),
      short/long description anahtar kelime taraması, 8 ekran görüntüsü (metin overlay'li), feature graphic
- [ ] Gizlilik politikası sayfası (statik host — GitHub Pages yeterli)
- [ ] **Data Safety formu:** konum cihazda, paylaşım yok (S3 önlemi)
- [ ] Soğuk açılış < 2 sn ölçümü; APK boyut kontrolü (< 25 MB)

## Hafta 6 — Yayın

- [ ] Play Console üretim erişim koşullarını kontrol et — kapalı test zorunluysa
      yayın öncesi ayrı karar al
- [ ] Crashlytics temiz mi (kapalı test verisi üzerinden)
- [ ] Production release — kademeli açılım (%20 → %50 → %100)
- [ ] Lansman sonrası ilk hafta: Reddit (r/Fishing vb.) + niş forum tanıtımları (P2 önlemi)
- [ ] RevenueCat hunisi + erken uyarı eşikleri izlemede ([risks.md](risks.md) §3)

## Kapsam güvenlik supabı

Takvim sıkışırsa atılma sırası (öncelik: yayın tarihi > özellik):
1. Orta boy widget → v1.1
2. Aylık ısı haritası cilası → v1.1
3. TR çevirisi → v1.1 (l10n altyapısı kalır)
4. Onboarding 3 adım → 2 adım

**Asla atılamaz:** USNO testleri, satın alma E2E testi, UMP consent.

## Yayın sonrası (v1.1+, backlog)

Fiyat A/B + lifetime testi → hunting mode → tide (Open-Meteo ticari plana geçişle) →
catch log → iOS (WeatherKit) → ek diller (ES, PT-BR)

---

# Planlamada kalan açık konular

| # | Konu | Karar sahibi | Ne zaman |
|---|---|---|---|
| 1 | ~~Uygulama ismi~~ ✅ **SoluCast** seçildi (Temmuz 2026) — title: "SoluCast: Best Fishing Times", paket: `app.solucast` | — | Tamamlandı |
| 2 | **Görsel kimlik:** accent renk, ikon, Nisteia'daki gibi design-ref HTML mockup'ları | Birlikte | Hafta 1–2 |
| 3 | **Skor ağırlıklarının son hali** (ay fazı %35 / çakışma %25 / basınç %20 / mevsim %20 taslak) | Birlikte | Hafta 1 |
| 4 | Play hesap türü teyidi: kişisel mi kurumsal mı? (kapalı test şartını netleştirir) | Sen | Hemen |
| 5 | Test grubu: Nisteia'nın 12 kişisi yeniden kullanılabilir mi? | Sen | Hafta 1 |
| 6 | AdMob hesabı hazır mı, UMP mesajı Play'e tanımlı mı? | Sen | Hafta 4'ten önce |
