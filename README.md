# SoluCast

**Play Store başlığı:** `SoluCast: Best Fishing Times` (28 karakter)
**Paket adı:** `app.solucast`

> En iyi balık tutma / avlanma zamanlarını gösteren solunar takvim uygulaması.
> "Bugün balığa çıkmaya değer mi, en iyi saat kaç?" sorusuna 2 saniyede cevap.

**Durum:** Aktif geliştirme (Temmuz 2026) — USNO-doğrulanmış çekirdek motor +
4 sekme & Gün Detayı UI (Stitch tasarımı) tamam; sırada veri katmanı (IANA tz,
hava, GPS) ve bildirimler
**Hedef platform:** Android (Play Store) → sonra iOS
**Stack:** Flutter (Nisteia ile aynı altyapı)
**Model:** Freemium — reklamlı ücretsiz katman + Pro abonelik

## Dokümanlar

| Doküman | İçerik |
|---|---|
| [docs/market-analysis.md](docs/market-analysis.md) | Pazar büyüklüğü, rakipler, boşluk analizi, konumlandırma |
| [docs/requirements.md](docs/requirements.md) | Fonksiyonel / fonksiyonel olmayan isterler, MVP kapsamı |
| [docs/screens.md](docs/screens.md) | Ekran listesi ve ekran bazlı detaylar |
| [docs/architecture.md](docs/architecture.md) | Flutter mimarisi, paketler, çekirdek hesap motoru |
| [docs/data-sources.md](docs/data-sources.md) | Veri kaynakları, API'ler, lisans ve maliyet |
| [docs/monetization.md](docs/monetization.md) | Abonelik + reklam stratejisi, fiyatlandırma, paywall |
| [docs/risks.md](docs/risks.md) | Risk kaydı, kısılamazlar listesi, erken uyarı eşikleri |
| [docs/development-plan.md](docs/development-plan.md) | 6 haftalık hızlı geliştirme planı + açık kararlar |

## Tek cümlelik strateji

Solunar nişindeki rakipler eski, çirkin ve reklam dolu; biz Nisteia kalitesinde
modern, hızlı, **tamamen offline çalışan** bir çekirdek + hava durumu katmanı ile
ABD/global pazara İngilizce-first çıkıyoruz. Sunucu yok, bakım maliyeti sıfıra yakın.

## İsim kararı (Temmuz 2026) ✅

**SoluCast** seçildi — Solunar + Forecast + Cast (olta atmak).
Mağaza taramasında çakışma yok; "Solu-" öneki solunar aramalarında kısmi eşleşme sağlıyor,
başlıktaki "Best Fishing Times" nişin en yüksek hacimli arama kalıbı.

Elenenler: BiteTime (iOS'ta mevcut + Fishbrain'in premium özellik adı — marka çatışması),
BiteCast (bitecastpro.com aynı konseptte mevcut), FishCast (Play'de mevcut).

> Play Console'da kayıttan hemen önce mağazada son bir elle arama yapılacak.
