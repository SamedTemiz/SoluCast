# Ekranlar

Navigasyon: alt tab bar — **Bugün · Takvim · Konumlar · Ayarlar** (4 tab).
Nisteia'daki gibi tek aktivite, Material 3, koyu/açık tema.

---

## 1. Onboarding (ilk açılış, 3 adım + soft paywall)

1. **Değer önerisi:** "Know the best time to fish — anywhere, even offline." Tek görsel + tek cümle.
2. **Konum izni:** Neden istediğimizi açıklayan ekran → sistem izni. Reddedilirse manuel arama.
3. **Bildirim izni:** "5-yıldızlı günleri kaçırma" → sistem izni (Android 13+).
4. **Soft paywall:** 7 gün ücretsiz Pro denemesi teklifi, sağ üstte belirgin "Skip" — dark pattern yok.

## 2. Bugün (ana ekran — uygulamanın kalbi)

Yukarıdan aşağı:
- **Konum + tarih başlığı** (konuma dokununca konum değiştirici bottom sheet)
- **Skor kartı:** Büyük 1–5 balık ikonu + "Good day to fish" etiketi + skora dokununca
  faktör dökümü bottom sheet ("Neden 4/5?")
- **Zaman çizelgesi (timeline):** 24 saatlik yatay şerit; major periyotlar koyu dalga,
  minor periyotlar açık dalga, gün doğumu/batımı ikonları, şimdiki zaman imleci.
  Bir sonraki periyoda geri sayım: "Major in 2h 15m"
- **Güneş & Ay kartı:** doğuş/batış saatleri, ay fazı görseli, aydınlanma %
- **Hava şeridi:** sıcaklık, rüzgâr (yön oku), bulut, yağış %, **basınç + trend oku**
- Ücretsizde reklam YOK bu ekranda — ilk izlenim temiz kalmalı

## 3. Takvim / Tahmin

- Üstte **7 günlük şerit** (her gün: mini skor ikonu + hava ikonu) — yatay kaydırma
- Altta **aylık grid** görünümü (her hücrede skor rengi — ısı haritası hissi)
- Ücretsiz: bugün+yarın dokunulabilir, sonrası kilitli (kilit ikonlu, dokununca paywall)
- Pro: 14 gün detay
- En altta banner reklam (yalnız ücretsiz katman)

## 4. Gün Detayı (takvimden veya Bugün'den geçiş)

- Tarih + skor + faktör özeti
- **Saatlik aktivite eğrisi:** 0–24 çizgi grafik; major/minor tepeleri, şafak/akşam gölgeleme
- Periyot listesi: "Major 06:40–08:40 ★★ (şafakla çakışıyor)"
- O günün hava tahmini (saatlik kaydırılabilir şerit)
- "Bu gün için hatırlatma kur" butonu (Pro)

## 5. Konumlar

- Kayıtlı konum listesi: ad + mini skor (bugün) + hava ikonu
- "+" → arama (geocoding) veya "mevcut konumum"
- Ücretsiz 1 kayıtlı konum; ikincisini eklemeye çalışınca paywall
- Kaydırarak sil / yeniden adlandır

## 6. Ayarlar

- Pro durumu / "Upgrade" satırı (en üstte)
- Birimler (°F/°C, mph/kmh/kt, inHg/hPa), saat formatı
- Bildirimler: günlük özet saati, yüksek skor uyarısı aç/kapa, periyot hatırlatıcıları (Pro)
- Dil, tema
- "How is the score calculated?" (şeffaflık sayfası — güven inşası, ASO yorumlarında artı)
- Gizlilik politikası, restore purchases, uygulama hakkında

## 7. Paywall

- Başlık: "Fish smarter with Pro"
- Karşılaştırma tablosu: Free vs Pro (14 gün tahmin, sınırsız konum, periyot hatırlatıcı,
  reklamsız, widget özelleştirme)
- Fiyat kartları: **Yıllık (öne çıkan, "2 ay bedava" rozeti) / Aylık**
- 7 gün deneme vurgusu + "cancel anytime"
- Kapatma X'i görünür — agresif değil (Play Store politika + yorum riski)

## 8. Widget'lar (Android)

- **Küçük (2x2):** bugünün skoru (balık ikonları) + ay fazı
- **Orta (4x2):** skor + sonraki periyot geri sayımı + gün doğ/bat
- Widget'a dokunma → Bugün ekranı

---

## Ekran-dışı UX kuralları

- Hesap/kayıt YOK. Açar açmaz değer.
- İlk açılışta konum izni gelmeden bile İstanbul/örnek konumla demo veri gösterilebilir
  (boş ekran yerine canlı önizleme).
- Tüm skor ikonografisi renk körlüğü dostu (yalnız renge değil, dolu/boş ikona dayan).
- Maskot/illüstrasyon minimal; Nisteia'daki gibi tipografi + tek accent renk ile premium his.
