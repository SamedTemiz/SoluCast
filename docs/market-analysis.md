# Pazar Analizi — Solunar Balıkçılık Uygulaması

*Son güncelleme: 15 Temmuz 2026*

## 1. Pazar büyüklüğü

- Balıkçılık uygulamaları pazarı **2026'da ~217M$**, 2035'e kadar ~587M$ öngörüsü (**CAGR %11.7**).
  Kaynak: [Business Research Insights](https://www.businessresearchinsights.com/market-reports/fishing-app-market-121030),
  [Industry Research](https://www.industryresearch.biz/market-reports/fishing-app-market-103636)
- Kullanımın **%38'i Kuzey Amerika**; sadece ABD'de **~50.1 milyon amatör balıkçı** var ve
  %45'i planlama/tahmin için uygulama kullanıyor.
- Global olarak balıkçılık uygulamalarında **50M+ aktif kullanıcı**, ~1.000 uygulama.
- Avcılık tarafı (solunar teorisi aynı) ABD'de ek ~15M kullanıcı potansiyeli — aynı motorla
  ikinci kitle.

## 2. Rakip haritası

### Katman 1 — Devler (doğrudan rakip DEĞİL)
| Uygulama | Kullanıcı | Fiyat | Konum |
|---|---|---|---|
| **Fishbrain** | 11–15M | $9.99/ay veya $74.99/yıl | Sosyal ağ + harita + catch log canavarı. Ağır, hesap zorunlu. |
| **Fishing Points** | 5M+ | ~$10–30/yıl (bölgesel) | Harita/navigasyon + tide odaklı. |
| **Navionics / onWater** | — | $$$ | Denizcilik haritacılığı. |

Bunlarla rekabet etmiyoruz; bunların **karmaşıklığından kaçan** kullanıcıyı alıyoruz.

### Katman 2 — Doğrudan rakipler (solunar nişi)
| Uygulama | İndirme | Zayıf noktaları |
|---|---|---|
| **Fishing & Hunting Solunar Time** | 1M+ | 2015 görünümlü UI, yanlış ay doğuş/batış saatleri şikâyetleri, ödeme hataları, reklam yoğun. Puanı 4.7 ama yorumlarda doğruluk şikâyeti belirgin. |
| **Solunar Fishing Calendar** (SarkaSofta) | 50K (~910/ay) | Eski tasarım, sınırlı özellik. |
| **iSolunar** | — | Tek seferlik ücretli, iOS ağırlıklı, modernize edilmemiş. |
| **Fishing Times** | 500K+ | Reklam dolu, offline zayıf. |

Kaynaklar: [Play Store — Solunar Time](https://play.google.com/store/apps/details?id=com.antonnikitin.solunarforecast),
[AppBrain istatistikleri](https://www.appbrain.com/app/solunar-fishing-calendar/com.professional.kalakalenteri),
[justuseapp yorum analizi](https://justuseapp.com/en/app/1056000899/fishing-hunting-solunar-time/reviews)

## 3. Kullanıcı şikâyetlerinden çıkan boşluklar (feature-gap)

Rakip yorumlarından derlenen fırsatlar:

1. **Doğruluk:** "Ay doğuş/batış saatleri yanlış" şikâyeti yaygın → bizim çekirdeğimiz
   Meeus algoritmalarıyla hesaplanacak ve USNO/timeanddate verisiyle snapshot-test edilecek
   (Nisteia'daki orthocal validasyon yaklaşımının aynısı).
2. **Modern UI yok:** Niş rakiplerin tamamı eski görünümlü. Nisteia kalite çıtası tek başına fark.
3. **Offline eksik:** Kamp/tekne ortamında çekim yok; solunar çekirdeğimiz %100 offline.
4. **Hesap zorunluluğu:** Fishbrain kayıt istiyor → biz hesapsız, açar açmaz değer.
5. **Widget eksikliği:** "Uygulamayı açmadan bugünün skorunu göreyim" talebi karşılanmıyor.
6. **Şeffaf olmayan skor:** Skorun neden 3 yıldız olduğu açıklanmıyor → biz katkı
   faktörlerini gösteririz (ay fazı, major periyot yakınlığı, basınç trendi).

## 4. Konumlandırma

> **"The fastest answer to: should I go fishing today?"**

- **Tek işe odak:** Skor + saatler. Sosyal ağ yok, harita canavarı yok.
- **Hesapsız, hızlı, offline-first.**
- **Dürüst veri:** Solunar teori + hava/basınç birleşik skoru, faktörleri açıklanmış.
- **Fiyat konumu:** Fishbrain'in ($74.99/yıl) çok altında, niş rakiplerin kalitesinin çok üstünde.

## 5. Hedef kitle ve pazarlar

1. **Birincil:** ABD kıyı + tatlı su amatör balıkçıları (İngilizce, ödeme gücü yüksek)
2. **İkincil:** Avustralya, Kanada, UK, İskandinavya, Brezilya (güney yarımküre sezon dengeler)
3. **Bonus:** Türkiye (TR lokalizasyon bedava, reklam ağırlıklı gelir)
4. **V2 genişleme:** Avcılar (hunting mode) — aynı solunar motor, ayrı tema

## 6. Mevsimsellik

- Kuzey yarımküre pik: Mart–Ekim; kış düşüşünü güney yarımküre + buz balıkçılığı kısmen dengeler.
- ASO piki: sezon açılışları (ABD'de eyalet bazlı Nisan–Mayıs).
- **Plan: olabildiğince hızlı lansman (hedef Ağustos–Eylül 2026).** ABD güz sezonu +
  güney yarımküre baharı yakalanır; asıl kazanç, 2027 bahar pikine kadar yorum ve
  sıralama birikmiş olması. Bkz. [risks.md](risks.md) P1.

## 7. Riskler

| Risk | Etki | Önlem |
|---|---|---|
| Solunar teorinin bilimselliği tartışmalı | Düşük — kitle zaten talep ediyor | "Tahmin aracı" dili; hava/basınç gibi somut verilerle harmanla |
| Mevsimsellik | Orta | Güney yarımküre + hunting mode + yıllık abonelik |
| Niş rakiplerin fiyat avantajı (ücretsiz) | Orta | Ücretsiz katman cömert kalsın; Pro sadece güç kullanıcıya |
| Google Play politika değişiklikleri | Düşük | Sunucusuz mimari, hassas veri yok (konum cihazda kalıyor) |
