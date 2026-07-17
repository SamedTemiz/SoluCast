# İsterler (Requirements)

## 1. Ürün tanımı

Kullanıcının konumuna göre balık (ve ileride av hayvanı) aktivitesinin en yüksek olacağı
gün ve saatleri gösteren, offline çalışan solunar takvim uygulaması.

**Kuzey yıldızı metrik:** Kullanıcı uygulamayı açtıktan sonra **3 saniye içinde**
"bugünün skoru + bir sonraki iyi zaman dilimi" bilgisini görmüş olmalı.

## 2. Fonksiyonel isterler — MVP (v1.0)

### F1. Konum
- F1.1 GPS ile otomatik konum alma (izin reddedilirse manuel arama)
- F1.2 Şehir/yer adıyla manuel konum arama (geocoding)
- F1.3 Konum kaydetme; **ücretsiz: 1 konum, Pro: sınırsız**
- F1.4 Konum verisi cihazda kalır, sunucuya gönderilmez (ASO + gizlilik satış noktası)

### F2. Solunar çekirdeği (offline, cihazda hesaplanır)
- F2.1 Günlük balıkçılık skoru: 0–100 iç puan → kullanıcıya 1–5 balık ikonu
- F2.2 Major periyotlar (ay transit / anti-transit ±1 saat) — günde 2 adet
- F2.3 Minor periyotlar (ay doğuşu / batışı ±30 dk) — günde 2 adet
- F2.4 Ay fazı, aydınlanma yüzdesi, ay doğuş/batış saatleri
- F2.5 Gün doğumu/batımı, alacakaranlık saatleri (şafak/akşam overlap bonusu skora işlenir)
- F2.6 Skor faktörlerinin şeffaf gösterimi ("Yeni ay +30, major periyot şafakla çakışıyor +20…")
- F2.7 Tüm astronomi hesapları cihazda; **internet olmadan sınırsız ileri tarih** çalışır

### F3. Hava durumu katmanı (online, cache'li)
- F3.1 Anlık + saatlik: sıcaklık, rüzgâr hızı/yönü, bulutluluk, yağış olasılığı
- F3.2 **Barometrik basınç + trend oku** (balıkçı için kritik; skora dahil)
- F3.3 Son başarılı veri cache'lenir; offline'da "son güncelleme X saat önce" ibaresiyle gösterilir
- F3.4 Hava verisi alınamazsa uygulama çalışmaya devam eder (skor yalnız astronomiyle hesaplanır)

### F4. Takvim / tahmin
- F4.1 Bugün ekranı: skor, periyot zaman çizelgesi, güneş/ay saatleri, hava şeridi
- F4.2 Haftalık şerit + aylık takvim görünümü (her gün skor ikonu)
- F4.3 **Ücretsiz: bugün + yarın detay; Pro: 14 güne kadar detay** (astronomi zaten offline
       hesaplanabildiği için kilit yapay ama standart sektör pratiği)
- F4.4 Gün detayı: saatlik aktivite eğrisi (grafik), periyotlar, hava detayı

### F5. Bildirimler (lokal, sunucusuz)
- F5.1 Günlük özet bildirimi (saat seçilebilir): "Bugün 4/5 — major 06:40–08:40"
- F5.2 "Yüksek skorlu gün" uyarısı: skor ≥4 olan günden akşam önce bildirim
- F5.3 Pro: periyot başlamadan X dk önce hatırlatma, konum bazlı çoklu bildirim
- F5.4 Tümü `flutter_local_notifications` ile cihazda planlanır — push sunucusu YOK

### F6. Widget
- F6.1 Android home-screen widget: bugünün skoru + sonraki periyot (küçük + orta boy)
- F6.2 Widget verisi gece yarısı ve uygulama açılışında güncellenir

### F7. Monetizasyon yüzeyleri
- F7.1 Ücretsiz katmanda banner reklam (yalnız takvim ekranında, Bugün ekranı temiz kalır)
- F7.2 Paywall ekranı: onboarding sonu (kapatılabilir) + kilitli özellik dokunuşlarında
- F7.3 Abonelik: aylık / yıllık (7 gün deneme) — detay `monetization.md`
- F7.4 Satın alma durumu RevenueCat ile; hesap gerektirmez

### F8. Ayarlar
- F8.1 Birimler: °C/°F, km/h–mph–kt, hPa/inHg (ABD default: imperial)
- F8.2 12/24 saat formatı (locale default)
- F8.3 Dil: EN (default), TR; altyapı `l10n.yaml` (Nisteia ile aynı)
- F8.4 Tema: sistem / açık / koyu
- F8.5 Bildirim tercihleri, gizlilik politikası, "skor nasıl hesaplanır?" sayfası

## 3. MVP DIŞI — v1.x / v2 backlog

- Gelgit (tide) verisi ve kıyı modu — Open-Meteo Marine / NOAA (ABD)
- **Hunting mode** (aynı motor, av teması + tür bazlı ipuçları)
- Catch log (tuttuğum balıklar günlüğü) → retention artırıcı
- iOS sürümü (Flutter sayesinde düşük maliyet; WeatherKit değerlendirilir)
- Su sıcaklığı, dolunay gece balıkçılığı modu
- Ek diller: ES, PT-BR, DE, NO/SV
- Wear OS / watchOS komplikasyonu

## 4. Fonksiyonel olmayan isterler

| Kategori | İster |
|---|---|
| Performans | Soğuk açılış < 2 sn; ilk ekran render'ı için ağ BEKLENMEZ |
| Offline | Astronomi/solunar %100 offline; hava cache'den |
| Doğruluk | Ay/güneş saatleri USNO referansına ±2 dk; snapshot testlerle korunur |
| Boyut | APK < 25 MB (harita SDK'sı yok, ağır asset yok) |
| Gizlilik | Konum cihaz dışına çıkmaz; analytics anonim (Firebase Analytics minimal) |
| Sunucu | **Backend yok.** Statik gizlilik sayfası hariç sunucu bakımı sıfır |
| Erişilebilirlik | Dinamik font desteği, kontrast AA, TalkBack etiketleri |
| Test | Çekirdek hesap motoru %90+ birim test kapsamı + USNO validasyon snapshot'ları |

## 5. Başarı kriterleri (ilk 6 ay)

- 10K+ indirme, 4.5+ puan
- D30 retention ≥ %15 (bildirim + widget sayesinde)
- Ücretsiz→Pro dönüşüm ≥ %2, aylık churn < %8
- Hedef: 6. ayda $500+ MRR (reklam + abonelik toplamı)
