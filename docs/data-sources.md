# Veri Kaynakları

## 1. Özet tablo

| Veri | Kaynak | Maliyet | Offline? |
|---|---|---|---|
| Güneş/ay saatleri, faz, transit | **Cihazda hesap** (Meeus algoritmaları) | 0 | ✅ %100 |
| Solunar periyot + skor | **Cihazda hesap** | 0 | ✅ %100 |
| Hava durumu (sıcaklık, rüzgâr, basınç, bulut, yağış) | **Open-Meteo Forecast API** | Geliştirmede ücretsiz; yayında $29/ay | Cache'li |
| Geocoding (konum arama) | **Open-Meteo Geocoding API** | Ücretsiz | — |
| Timezone çözümü | Geocoding yanıtındaki `timezone` alanı | 0 | Kayıt sonrası ✅ |
| Gelgit (V2) | Open-Meteo Marine / NOAA (ABD) | Marine pakete dahil | Cache'li |
| Referans/validasyon | USNO, timeanddate (test verisi) | 0 | test-time |

**Kritik nokta:** Uygulamanın ana değeri (solunar) hiçbir API'ye bağımlı değil.
API tamamen çökse bile uygulama işlevini sürdürür — rakiplerin çoğu bunu yapamıyor.

## 2. Open-Meteo detayı

- **Geliştirme/test:** ücretsiz uç (`api.open-meteo.com`), 10K çağrı/gün, anahtar yok.
  Lisans gereği ücretsiz uç **ticari kullanımda yasak** → yayına çıkarken geçiş şart.
- **Yayın:** [Standard plan **$29/ay**](https://open-meteo.com/en/pricing) —
  1M çağrı/ay, `customer-api.open-meteo.com`, ticari lisans + SLA.
  Forecast + **Marine** + Air Quality + Geocoding dahil (V2 gelgit için ek maliyet yok).
- **Çağrı bütçesi:** 1 kullanıcı ≈ 3–5 çağrı/gün (1 saat cache ile) →
  1M çağrı/ay ≈ **~8–10K DAU** kapasitesi. Bu eşiğe gelirsek zaten gelir sorunu yok.
- Tek istekte saatlik+günlük 14 günlük tahmin alınabiliyor → çağrı sayısı düşük kalır.

### Yedek plan
- **OpenWeatherMap One Call 3.0:** 1.000 çağrı/gün ücretsiz, ticari kullanım serbest.
  Çok erken dönemde (ilk yüzler) maliyetsiz başlamak istersek launch'ı bununla yapıp
  hacim gelince Open-Meteo'ya geçebiliriz. Repo arayüzü (`WeatherRepository`)
  provider-bağımsız tasarlanacak → geçiş 1 günlük iş.
- **Apple WeatherKit (iOS V2):** Apple Developer üyeliğiyle 500K çağrı/ay bedava —
  iOS sürümünde maliyeti daha da düşürür.

## 3. Astronomi hesabı — neden API değil?

1. **Maliyet ve offline:** Efemeris matematiği deterministik; API'ye ödeme saçmalık olur.
2. **Doğruluk kontrolü bizde:** Rakipler "saatler yanlış" şikâyeti alıyor; biz snapshot
   testlerle garantiye alıyoruz.
3. **Sınırsız ileri tarih:** Pro'daki 14 günlük tahmin ve takvim ısı haritası bedava üretilir.

Kaynak algoritma: Jean Meeus, *Astronomical Algorithms* (2. baskı) —
güneş için NOAA basitleştirilmiş modeli (±1 dk), ay için ELP tabanlı kısaltılmış seri (±2 dk).
Önce pub.dev paketleri (`astronomy`, `sweph` FFI) değerlendirilir; kalite yetmezse port yazılır.

## 4. Validasyon referansları (test verisi)

- **USNO (aa.usno.navy.mil):** güneş/ay doğuş-batış-transit tabloları — ground truth
- **timeanddate.com:** ikinci kaynak çapraz kontrol
- 10+ konum × 4 mevsim snapshot JSON'ları `test/validation/snapshots/` altına
  (Nisteia'daki orthocal snapshot düzeninin aynısı)

## 5. Lisans kontrol listesi

- [x] Open-Meteo ticari plan → CC BY 4.0 attribution: Ayarlar ekranına
      "Weather data by Open-Meteo.com" satırı eklenecek
- [x] Meeus algoritmaları: matematik, telif kapsamı dışında; kod kendi yazımımız/MIT port
- [x] Solunar teorisi: kamu malı (John Alden Knight, 1926)
- [ ] Kullanılacak pub.dev paketlerinin lisansları yayın öncesi taranacak (MIT/BSD/Apache OK)
- [x] Discogs benzeri "ücret alamazsın" tuzağı YOK — Open-Meteo ücretli planında
      monetizasyon serbest
