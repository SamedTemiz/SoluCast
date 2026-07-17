# Risk Analizi

*Bağlam: hızlandırılmış plan — hedef, MVP'yi haftalar içinde Play Store'a göndermek.
Riskler bu hız hedefine göre puanlandı. Skor = Olasılık × Etki (1–5 × 1–5).*

## 1. Risk kaydı (skora göre sıralı)

### 🔴 Kritik (öncelikli aksiyon gerekli)

| # | Risk | O×E | Açıklama ve önlem |
|---|---|---|---|
| S1 | **Play kapalı test zorunluluğu hız planını bloke eder** | 4×5 | Kasım 2023 sonrası açılan **kişisel** geliştirici hesaplarında her yeni uygulama için üretime geçmeden önce **12 test kullanıcısıyla 14 gün kesintisiz kapalı test** şartı var. Nisteia'da bu süreci yaşadıysan aynısı burada da geçerli. **Önlem:** Geliştirmenin 1. haftasında iskelet APK ile kapalı testi BAŞLAT — 14 günlük sayaç geliştirmeyle paralel işlesin. Nisteia test grubunu yeniden kullan. Bunu ihmal edersek "bitti ama 2+ hafta yayınlanamıyor" durumuna düşeriz. |
| T1 | **Astronomi doğruluğu — hız uğruna validasyonu kısmak** | 3×5 | Rakiplerin 1 numaralı şikâyeti "ay saatleri yanlış". Bizim ana satış vaadimiz doğruluk; hızlı geliştirmede test atlanırsa farkımız yok olur ve yorumlar bunu affetmez (yorum ortalaması ASO'nun kendisidir). **Önlem:** USNO snapshot testleri MVP kapsamından ASLA çıkarılamaz — pazarlıksız kural. Hazır paket (`astronomy`/`sweph`) + 10 konumluk validasyon ilk haftanın işi. |
| M3 | **Faturalandırma/abonelik kurulum hataları** | 3×4 | Rakipte "payment unsuccessful" şikâyetleri mevcut; aynı hatayı yaparsak paywall'a gelen kullanıcıyı (en değerlisi) kaybederiz. **Önlem:** RevenueCat kullan (elle Play Billing yazma), kapalı test döneminde test kartlarıyla satın alma + restore + iptal akışlarının tamamını dene. Lansmanda lifetime YOK — SKU sayısını 2'de tut (aylık, yıllık). |

### 🟠 Yüksek

| # | Risk | O×E | Açıklama ve önlem |
|---|---|---|---|
| T4 | **OEM pil optimizasyonu bildirimleri öldürür** | 4×3 | Xiaomi/Huawei/Samsung agresif battery killer'lar planlı lokal bildirimleri engeller → "bildirim gelmiyor" 1-yıldız yorumları. **Önlem:** `exact alarm` izni + ayarlara "bildirim sorunları" yardım sayfası (dontkillmyapp yönlendirmesi); bildirim planlamayı uygulama her açılışta yeniden kur (self-healing). |
| P2 | **Keşfedilebilirlik — indirme gelmemesi** | 3×4 | Niş uygulamada ASO tek trafiğimiz; hızlı lansman ASO hazırlığını kısma eğilimi yaratır. **Önlem:** İsimde "Solunar" + "Fishing Times" anahtar kelimeleri geçsin (title 30 karakter dolsun); ekran görüntüleri metin overlay'li ve İngilizce; long description anahtar kelime taraması yapılmış olsun. Lansman sonrası ilk ay Reddit (r/Fishing, r/FishingForBeginners) + niş forumlarda organik tanıtım. |
| T2 | **Timezone/DST hataları** | 3×4 | Yanlış saat = güven kaybı; ABD'de DST geçişleri Kasım/Mart. **Önlem:** tüm hesaplar konumun IANA tz'sinde; DST geçiş günleri için birim test; UTC offset'i elle hesaplamak YASAK. |
| O3 | **Scope creep — hız hedefini içeriden öldürür** | 4×3 | Tide, hunting mode, catch log, iOS "hazır yapmışken" cazibesi. **Önlem:** MVP kapsamı `requirements.md`'de kilitli; yeni fikir → backlog'a, koda değil. Kural: v1.0'a özellik EKLENMEZ, sadece çıkarılır. |
| M1 | **Pro dönüşümü %2 varsayımının tutmaması** | 3×3 | Free katman fazla cömertse kimse ödemez; fazla kısıksa yorumlar düşer. **Önlem:** RevenueCat metrikleriyle ilk 30 günde paywall görüntülenme→deneme→ücretli hunisini izle; ilk kaldıraç fiyat değil katman sınırıdır (ör. tahmin 2 gün→bugün'e düşürmek yerine konum sınırını oyna). |

### 🟡 Orta

| # | Risk | O×E | Açıklama ve önlem |
|---|---|---|---|
| P1 | **Sezon ortası lansman** | 3×3 | Hemen çıkarsak (Ağu–Eyl 2026) ABD pik sezonunun sonuna denk geliriz. Ama bu net negatif değil: güz balıkçılığı + güney yarımküre baharı (Eyl–Ara) yakalanır ve **2027 bahar pikine yorum birikmiş, sıralaması oturmuş bir uygulamayla gireriz.** Hızlı lansmanın asıl getirisi bu. **Önlem:** lansmanı "yorum biriktirme sezonu" olarak çerçevele; in-app review prompt'u (yüksek skorlu günde, başarılı kullanım sonrası) v1.0'da olsun. |
| S3 | **GDPR/UMP consent eksikliği reklam gelirini keser** | 2×4 | AdMob, AB trafiğinde consent yoksa reklam sunmaz/hesap uyarısı gelir. **Önlem:** UMP SDK'sı ilk günden entegre; Data Safety formu doğru doldurulur (konum: cihazda, paylaşılmıyor). |
| O2 | **Gelirden önce sabit gider** | 3×2 | Open-Meteo ticari $29/ay, gelir 0 iken başlar. **Önlem:** Lansmanı OpenWeatherMap ücretsiz katmanıyla (1K çağrı/gün ≈ ilk ~200-300 kullanıcı) yap; `WeatherRepository` provider-bağımsız olduğundan hacim gelince Open-Meteo'ya geçiş ~1 gün. Gider ancak kullanıcı varken doğar. |
| T3 | **Yüksek enlem edge case'leri** | 2×3 | Ay bazı günler doğmaz/batmaz; kutup yazı güneşi hiç batmaz → null-crash veya saçma skor. **Önlem:** motor nullable döner, UI "no moonrise today" gösterir; Tromsø/Anchorage snapshot'ları test setinde. |
| P3 | **Yerleşik ücretsiz rakiplerin yorum tabanı** | 3×2 | 1M+ indirmeli rakiple aynı anahtar kelimede yarışıyoruz. **Önlem:** İlk hedef "solunar" long-tail'i; ana kelime ("fishing times") sıralaması 2027 baharına hedef. Farklılaşma görselde: mağaza ekran görüntüleri modern UI'ı bağırsın. |

### 🟢 Düşük (izle, aksiyon gerekmez)

| # | Risk | O×E | Not |
|---|---|---|---|
| L1 | Solunar teorinin bilimsel eleştirisi | 2×2 | "Prediction/forecast" dili kullan, "guarantee" asla; şeffaflık sayfası zaten var. |
| L2 | Hukuki/lisans | 1×3 | Sağlık verisi yok, konum cihazda, Meeus kamu malı, Open-Meteo attribution yeterli. `data-sources.md` kontrol listesi tamam. |
| P4 | Mevsimsel gelir dalgalanması | 3×1 | Yıllık abonelik ağırlıklı model + güney yarımküre doğal çit; kabul edilen risk. |
| O1 | Nisteia ile dikkat bölünmesi | 2×2 | Nisteia incelemeden döner/yorum gelirse bağlam değişimi maliyeti; haftalık tek "Nisteia günü" ayır. |

## 2. Hızlandırılmış plana özel "kısılamazlar" listesi

Hız için her şey kısılabilir, ŞUNLAR HARİÇ:

1. **USNO snapshot testleri** (T1) — ürün vaadinin kendisi
2. **Kapalı testin 1. haftada başlatılması** (S1) — takvimi bloke eden tek dış etken
3. **Satın alma akışının uçtan uca testi** (M3) — gelir kapısı
4. **UMP consent + Data Safety formu** (S3) — politika/ban riski

Kısılabilirler (v1.1'e ertelenebilir): aylık ısı haritası → basit liste, orta boy widget,
TR lokalizasyonu (altyapı kalsın, çeviri sonra), onboarding 3 adım → 2 adım, fiyat A/B.

## 3. Erken uyarı göstergeleri ve eşikler

| Gösterge | Eşik | Aksiyon |
|---|---|---|
| Yorum ortalaması (ilk 50 yorum) | < 4.2 | Özellik geliştirmeyi durdur, şikâyet temalarını düzelt |
| "saat/doğruluk" temalı şikâyet | ≥ 2 adet | Hotfix önceliği — marka vaadi tehlikede |
| D7 retention | < %8 | Bildirim/widget değer döngüsünü yeniden tasarla |
| Paywall→deneme dönüşümü | < %5 | Paywall metni/tetik noktaları revizyonu |
| 3. ayda toplam indirme | < 1.000 | ASO revizyonu + isim/ekran görüntüsü testi; 6. ayda < 3K ise projeyi "bakım moduna" al, yeni fikre geç (sunk cost tuzağına düşme) |

Son satır önemli: sunucusuz mimari sayesinde uygulamayı **$0 maliyetle sonsuza dek rafta
tutabiliriz** — başarısızlık senaryosunda bile zarar sadece geliştirme süresidir.
