# Para Kazanma Stratejisi

## 1. Model: Freemium — reklam + abonelik (hibrit)

İki gelir bacağı birbirini tamamlar:
- **Reklam:** ücretsiz kullanıcı kitlesinden pasif gelir (balıkçı sezonda her gün açar)
- **Abonelik (Pro):** güç kullanıcıdan asıl gelir; reklamları da kaldırır

Sektör kanıtı: Fishbrain $74.99/yıl, Fishing Points ~$10–30/yıl, niş solunar
uygulamaları reklam+pro modeli — hepsi çalışıyor. Biz fiyat/kalite boşluğuna gireceğiz.

## 2. Katman ayrımı

| Özellik | Free | Pro |
|---|---|---|
| Bugün ekranı (skor, periyotlar, güneş/ay, hava) | ✅ | ✅ |
| Tahmin detayı | Bugün + yarın | **14 gün** |
| Aylık takvim ısı haritası | Yalnız skor ikonları | Tam erişim + gün detayı |
| Kayıtlı konum | 1 | **Sınırsız** |
| Günlük özet bildirimi | ✅ | ✅ |
| Yüksek skorlu gün uyarısı | ✅ (haftada özet) | Anında + özelleştirilebilir |
| Periyot hatırlatıcısı ("major 30 dk sonra") | — | ✅ |
| Widget | Küçük | Küçük + orta, özelleştirme |
| Reklam | Banner (takvim ekranı) | **Yok** |

**İlke:** Free katman tek başına GERÇEKTEN faydalı olmalı (yorum puanı + WOM bunun üstüne
kurulur). Pro, "hafta sonunu planlayan ciddi balıkçı"ya satar.

## 3. Fiyatlandırma

| Plan | ABD fiyatı | Not |
|---|---|---|
| Aylık | **$3.99** | Psikolojik olarak "bir kahve" |
| Yıllık | **$23.99** (~$2/ay) | Öne çıkan plan, "2 ay bedava" rozeti; 7 gün deneme |
| Lifetime (opsiyonel, v1.1'de test) | $59.99 | Abonelik sevmeyen kitle için; oranı izlenir |

- Konum: Fishbrain'in ($74.99/yıl) 1/3'ü altında → "premium ama erişilebilir"
- **Bölgesel fiyatlama:** Play Console ile TR/BR/Meksika vb. için düşük katman
  (ör. TR ₺'de yıllık ~₺349) — bu pazarlarda reklam geliri ağırlıklı zaten
- Deneme: yalnız yıllıkta 7 gün → deneme→ücretli dönüşümü yıllığa yönlendirir

## 4. Reklam politikası

- **Yalnız banner/native**, yalnız **Takvim** ekranının altında. Bugün ekranı ve
  gün detayı DAİMA temiz — rakiplerin en büyük şikâyeti reklam boğulması, farkımız bu.
- Interstitial YOK (v1'de). İleride yalnız "3. konum ekleme" gibi nadir anlarda
  rewarded ("reklam izle, 1 günlük Pro dene") test edilebilir.
- AdMob; ATT/GDPR uyumu için UMP consent SDK'sı.
- Beklenen eCPM (ABD, outdoor niş): banner $0.5–1.5 → reklam tek başına zengin etmez,
  Pro'ya giden yolda "sabır geliri"dir.

## 5. Paywall stratejisi

- **Tetik noktaları:** onboarding sonu (soft, atlanabilir) · kilitli güne dokunma ·
  2. konum ekleme · periyot hatırlatıcısına dokunma
- Kural: paywall her zaman **kapatılabilir**, fiyat her zaman görünür, deneme koşulu açık
  (Play politikası + yorum riski + iade oranı)
- RevenueCat ile: deneme dönüşümü, churn, plan dağılımı metrikleri hazır gelir;
  fiyat A/B testi (Offerings) sunucusuz yapılabilir

## 6. Gelir projeksiyonu (muhafazakâr)

Varsayımlar: 6. ayda 10K indirme, %25 aktif kalan (2.5K MAU), %2 Pro dönüşümü.

| Kalem | Hesap | Aylık |
|---|---|---|
| Pro abonelik | 10K × %2 = 200 abone × ~$2/ay efektif | ~$400 |
| Reklam | 2.3K ücretsiz MAU × 20 oturum × 1 banner × $1 eCPM | ~$45 |
| **Brüt** | | **~$445** |
| Google kesintisi (%15, <1M$) | | -$60 |
| Open-Meteo | | -$29 |
| **Net** | | **~$355/ay** |

- Bu tablo 10K indirmeyle; sezon ASO'su tutarsa (ABD bahar açılışı) 50K indirme
  senaryosunda net ~$1.8–2K/ay bandına çıkar.
- Kırılma noktası: ~$35/ay sabit gider (API + Play hesabı amorti) → **~25 abonede başabaş**.

## 7. Yol haritası bağlantısı

1. **v1.0 (hedef: olabildiğince hızlı — Ağustos–Eylül 2026):** Free+Pro, banner, yıllık+aylık
2. **v1.1:** Lifetime testi, rewarded deneme, fiyat A/B
3. **v1.2:** Hunting mode → aynı aboneliğin değerini artırır (fiyat sabit, değer artar)
4. **v2:** iOS + tide → Pro'ya "kıyı balıkçılığı" pitch'i eklenir
