# AnglerPulse ve Solucast Fish & Hunt Rakip Analizi

**Hazırlanma tarihi:** 19 Temmuz 2026
**İncelenen ürünler:**

1. Bu depoda geliştirilen **AnglerPulse** mobil uygulaması
2. b.b.f.c. tarafından yayımlanan **Solucast Fish & Hunt Forecast**

**Rakip mağaza bağlantıları:**

- Google Play: <https://play.google.com/store/apps/details?id=com.bbfc.solufishandhunt>
- App Store: <https://apps.apple.com/us/app/solucast-fish-hunt-forecast/id6752908949>

---

## 1. Yönetici özeti

İki uygulama arasında hem isim hem de temel ürün vaadi bakımından yüksek düzeyde benzerlik vardır. Her iki ürün de solunar dönemleri, güneş ve ay verileri, hava koşulları, günlük balıkçılık puanı, saatlik aktivite görünümü, takvim ve bildirimler üzerinden kullanıcının en uygun zamanı seçmesine yardımcı olmayı amaçlamaktadır.

Bu nedenle mevcut ürünün önceki adıyla pazara çıkarılması önerilmemektedir. Aynı kategoride, benzer işlevlerle ve benzer pazarlama diliyle sunulan iki ürünün kullanıcı tarafından birbirine ait ya da birbirinin kopyası sanılması kuvvetle muhtemeldir. Bu durum mağaza onayı, marka itirazı, arama sonuçlarında karışıklık, kullanıcı güveni ve uzun vadeli marka yatırımı açısından gereksiz risk yaratır.

Bizim uygulamamızda rakibin mağaza materyallerinde açıkça görülmeyen bazı değerli özellikler vardır:

- Astronomi hesaplarının cihaz üzerinde ve çevrimdışı yapılması
- Hava verisinin önbellekten çevrimdışı kullanılabilmesi
- Sekiz dil için yerelleştirme altyapısı
- Birden fazla kayıtlı konum ve konumlar arasında hızlı geçiş
- Günlük özet, yüksek skorlu gün ve seçilen solunar dönemi için ayrı bildirim türleri
- Dört ağırlıklı faktöre dayanan, daha açık bir 0–100 puan açıklaması

Ancak bunların hiçbiri mevcut haliyle tek başına güçlü ve kalıcı bir rekabet hendeği oluşturmaz. Rakip ise gelgit, avcılık, tür ve koşula özel ekipman/yem önerileri ile tahmin paylaşımı gibi alanlarda daha ileridedir.

Uzman görüşü olarak önerilen ürün yönü şudur:

> **Çevrimdışı çalışan, kayıtlı balıkçılık noktalarını karşılaştıran, skorunu açıkça gerekçelendiren ve zamanla kullanıcının av kayıtlarından öğrenen kişisel balıkçılık planlayıcısı.**

Önerilen yeni marka adı **AnglerPulse**'tır. Önerilen mağaza adı: **AnglerPulse: Fishing Forecast**.

---

## 2. İnceleme kapsamı ve sınırlamalar

Rakip uygulama analizi; Google Play ve App Store açıklamaları, sürüm bilgileri ve mağaza ekran görüntülerine dayanmaktadır. Rakip uygulamanın ücretli özellikleri satın alınarak uçtan uca test edilmemiştir. Bu nedenle “rakipte yok” ifadesi yerine, gerektiğinde “rakibin mağaza materyallerinde gösterilmiyor veya açıkça belirtilmiyor” yaklaşımı kullanılmıştır.

Bizim uygulama için depodaki kaynak kod, testler ve mevcut ürün akışları incelenmiştir. Kodda bulunan ancak gerçek abonelik, mağaza yayını veya üretim doğrulaması tamamlanmamış özellikler ayrıca işaretlenmiştir.

Rakip hakkında doğrulanan başlıca bilgiler:

- Google Play'de 100+ indirme görünmektedir.
- Son Google Play güncellemesi 20 Ekim 2025 tarihlidir.
- Android ve iOS sürümleri bulunmaktadır.
- App Store kaydında uygulama dili yalnızca İngilizce olarak belirtilmiştir.
- Uygulama içi satın alma ve Pro özellikleri bulunmaktadır.
- Mağaza ekranlarında gelgit, hava durumuyla ayarlanmış aktivite saatleri, takvim, türe özel öneriler ve uygun gün bildirimleri gösterilmektedir.

---

## 3. Temel ürün konumlandırması

### Rakip Solucast

Rakip, balıkçılık ve avcılığı birlikte hedefleyen genel amaçlı bir doğa aktivitesi tahmin uygulamasıdır. Ana vaadi, solunar tablolar ile hava verilerini bir araya getirip balık ve av hayvanlarının hareketli olacağı zamanları göstermektir.

Rakibin ürün mesajı dört eksende kurulmuştur:

1. Günlük balıkçılık ve avcılık puanı
2. Solunar, ay, güneş ve hava koşullarının birlikte analizi
3. İleri tarih planlama ve saatlik aktivite eğrileri
4. Tür ve koşula göre ekipman/yem önerileri

### Bizim AnglerPulse

Bizim ürün balıkçılığa daha dar odaklanmaktadır. Günlük skor, solunar dönemler, saatlik aktivite, hava durumu, takvim, konum yönetimi ve bildirimler sunmaktadır. Teknik mimaride cihaz üzerinde astronomi hesabı ve çevrimdışı tolerans öne çıkmaktadır.

Mevcut ürünün güçlü tarafı veri göstermekten çok, veriyi daha açık bir puanlama ve bildirim sistemine dönüştürebilmesidir. Bununla birlikte kullanıcıya verilen sonuç hâlen rakiple aynı temel cümlede özetlenmektedir: “Balığa çıkmak için en iyi zamanı göster.” Bu nedenle farklılaşmanın özellik listesinden daha güçlü bir kullanıcı problemine taşınması gerekir.

---

## 4. Özellik karşılaştırması

| Özellik | Rakip Solucast | Bizim uygulama | Değerlendirme |
|---|---|---|---|
| Ana ve ikincil solunar dönemleri | Var | Var | Doğrudan örtüşme |
| Ay evresi, ay doğuşu/batışı | Var | Var | Doğrudan örtüşme |
| Gün doğumu ve gün batımı | Var | Var | Doğrudan örtüşme |
| Günlük aktivite/balıkçılık puanı | 4 yıldızlı sistem | 0–100 skor ve 5 yıldız | Aynı ihtiyacın farklı sunumu |
| Skor nedeninin açıklanması | Katkıların açıklanacağı belirtiliyor | Dört faktör ve ağırlıkları açıklanıyor | Bizim uygulama daha şeffaf olabilir |
| Hava durumuyla skor ayarlama | Rüzgâr, sıcaklık, basınç ve yağış | Özellikle basınç trendi skor motoruna giriyor | Rakip daha geniş hava sinyali iddia ediyor |
| Saatlik aktivite eğrisi | Var, hava ile ayarlanıyor | Var | Büyük ölçüde örtüşme |
| Takvim görünümü | Var | Var | Doğrudan örtüşme |
| İleri tarih tahmini | Genişletilmiş takvim/forecast horizon | 14 günlük Pro tahmini | Benzer |
| Konum bazlı tahmin | GPS ve manuel/ZIP konumu | GPS, şehir arama ve kayıtlı konumlar | Bizim uygulama daha güçlü geliştirilebilir |
| Çoklu kayıtlı konum | Mağaza materyallerinde açık değil | Var | Muhtemel fark |
| Günlük özet bildirimi | Açıkça gösterilmiyor | Her gün 07.00 özeti | Bizim uygulamada farklı bir bildirim akışı |
| Yüksek skorlu gün uyarısı | Var; uygun günler için önceden bildirim | 4–5 yıldızlı günden önceki akşam | Örtüşüyor |
| Seçilen dönem hatırlatıcısı | Önemli pencere uyarıları var | Kullanıcı belirli dönemi seçebiliyor | Bizim akış daha kontrollü olabilir |
| Çevrimdışı astronomi | Açıkça belirtilmiyor | Cihazda hesaplanıyor | Önemli fark |
| Çevrimdışı hava toleransı | Belirtilmiyor | Eski hava önbelleği kullanılıyor | Faydalı fark |
| Dil desteği | App Store'da İngilizce | 8 dil altyapısı | Güçlü pazarlama farkı |
| Gelgit | Var | Yok | Önemli ürün açığı |
| Avcılık tahmini | Var | Yok | Rakibin hedef kitlesi daha geniş |
| Tür bazlı yem/takım tavsiyesi | Var | Yok | Rakip üstün |
| Tahmin paylaşımı | Var | Yok | Rakip üstün |
| Koyu tema | Var | Var | Fark değil |
| Birim ve 12/24 saat ayarı | Var | Var | Fark değil |

---

## 5. Bizim uygulamadaki mevcut farklılaştırıcılar

### 5.1. Çevrimdışı çalışan astronomi çekirdeği

Astronomi ve solunar dönemlerin cihaz üzerinde hesaplanması, bağlantının zayıf olduğu göl, kıyı ve kırsal alanlarda gerçek kullanıcı değeri yaratır. Hava verisi alınamadığında uygulamanın tamamen işlevsiz kalmaması da önemlidir.

Bu özellik teknik bir ayrıntı olarak bırakılmamalı; ürün vaadine dönüştürülmelidir:

> “Sinyal olmasa da günün balıkçılık pencereleri yanında.”

Sınırlama: Güncel hava verisi çevrimdışı üretilemez. Kullanıcıya astronomi verisinin güncel, hava verisinin ise önbellekten geldiği açıkça gösterilmelidir.

### 5.2. Çoklu konum altyapısı

Kayıtlı konumlar rakibin açıkça pazarlamadığı bir alandır. Mevcut uygulama konumları saklayıp değiştirebilmektedir; fakat bunun gerçek rekabet avantajına dönüşmesi için yalnızca listeleme yetmez.

Bir sonraki adım, kayıtlı konumları aynı tarih için karşılaştırmak olmalıdır:

- Bugün hangi konum daha iyi?
- Cumartesi sabahı hangi noktada rüzgâr daha uygun?
- Hangi konumda ana solunar dönem gün doğumuyla çakışıyor?
- Kullanıcının seçtiği saat aralığında hangi nokta öne çıkıyor?

Bu özellik uygulamayı “veri gösteren takvim” olmaktan çıkarıp karar veren bir planlayıcıya dönüştürür.

### 5.3. Açıklanabilir skor

Bizim skor sistemi ay evresi, alacakaranlık çakışması, basınç trendi ve mevsimsel etkiyi ayrı ağırlıklarla kullanmaktadır. Bunun kullanıcıya açıkça gösterilmesi güven oluşturur.

Rakip de skorun nedenini açıkladığını belirtmektedir. Bu nedenle yalnızca “Neden?” ekranı yeterli bir fark değildir. Açıklama eyleme dönük olmalıdır:

- “Skor neden 74?”
- “Skoru düşüren etken ne?”
- “İki saat sonra koşul neden iyileşecek?”
- “Bu konum diğerinden neden daha iyi?”

### 5.4. Dil desteği

Sekiz dil, İngilizce ağırlıklı rakibe karşı belirgin bir dağıtım avantajıdır. Özellikle Türkçe, Brezilya Portekizcesi, Latin Amerika İspanyolcası ve İskandinav dilleri hedefli mağaza sayfalarıyla desteklenirse organik büyüme sağlayabilir.

Ancak yerelleştirme yalnızca menü çevirisi olarak ele alınmamalıdır. Tarih/saat biçimleri, ölçü birimleri, bildirim metinleri, mağaza ekran görüntüleri ve destek içerikleri de her pazar için doğrulanmalıdır.

### 5.5. Bildirim çeşitliliği

Bizim uygulamada üç ayrı bildirim amacı bulunmaktadır:

1. Günlük özet
2. Yüksek skorlu gün uyarısı
3. Kullanıcının seçtiği solunar dönem hatırlatıcısı

Bu yapı iyi bir temeldir; ancak rakibin de uygun gün ve önemli pencere uyarıları vardır. Fark yaratmak için bildirimlerin kişiselleşmesi gerekir. Örneğin kullanıcı “rüzgâr 20 km/s altındaysa, yağış olasılığı %30'dan düşükse ve skor 70 üzerindeyse haber ver” diyebilmelidir.

---

## 6. Rakibin üstün olduğu alanlar

### 6.1. Gelgit

Gelgit, kıyı balıkçılığı için solunar veriden daha doğrudan karar etkileyebilen bir sinyaldir. Rakibin ekran görüntülerinde gelgit grafiği ve NOAA istasyonu bilgisi görülmektedir. Bizim uygulamada gelgit bulunmaması, deniz ve kıyı balıkçıları açısından önemli bir eksikliktir.

Öneri: Gelgit verisi eklenecekse yalnızca grafik olarak eklenmemeli; skor ve en iyi zaman açıklamasına dahil edilmelidir. Küresel veri kaynağı ve lisans maliyeti ayrıca değerlendirilmelidir.

### 6.2. Tür ve koşula özel öneriler

Rakip; tür, gelgit, bulutluluk, rüzgâr ve solunar döneme göre yem/takım tavsiyesi göstermektedir. Bu özellik kullanıcının “Veriyi gördüm, şimdi ne yapmalıyım?” sorusunu cevaplar.

Bizim ürün bu alanı doğrudan kopyalamamalıdır. Daha güçlü yaklaşım, öneriyi kullanıcının kendi geçmiş av sonuçlarıyla birleştirmektir.

### 6.3. Tahmin paylaşımı

Rakibin güncel sürümünde tahmin paylaşma özelliği bulunmaktadır. Bu hem grup planlaması hem de organik edinim için değerlidir. Bizim uygulamada paylaşım bulunmamaktadır.

Öneri: Basit ekran görüntüsü paylaşmak yerine; konum gizliliğini koruyan, tarih, skor ve en iyi pencereyi içeren bir “gezi kartı” paylaşılmalıdır. Özel balık noktası koordinatları varsayılan olarak paylaşılmamalıdır.

### 6.4. Daha geniş hedef kitle

Rakip hem balıkçılık hem avcılık sunarak daha geniş bir kullanıcı tabanına hitap etmektedir. Bizim ürünün avcılığı eklemesi şart değildir. Aksine yalnızca balıkçılığa odaklanmak; türler, su tipi, yem, av günlüğü ve nokta karşılaştırması konularında daha derin bir deneyim oluşturmak için stratejik avantaj olabilir.

---

## 7. Ürün ve marka riskleri

### 7.1. İsim ve karıştırılma riski

Önceki marka adı ile “Solucast Fish & Hunt Forecast” yazım ve telaffuz olarak aynıydı. İki ürün de aynı mağaza kategorisinde benzer anahtar kelimeleri kullanmaktadır. Rakip daha önce yayımlanmıştır.

Olası sonuçlar:

- Kullanıcıların iki ürünü aynı şirketin uygulaması sanması
- Olumsuz yorumların yanlış ürüne yönelmesi
- Mağaza aramasında marka görünürlüğünün bölünmesi
- Geliştirici veya marka sahibi tarafından itiraz edilmesi
- Alan adı, sosyal hesap ve reklam kampanyalarında karışıklık
- Sonradan yapılacak isim değişikliğinin kullanıcı ve edinim kaybı yaratması

Bu değerlendirme hukuki görüş değildir. Yeni isim kesinleşmeden önce Türkiye, ABD, Avrupa Birliği ve hedeflenen diğer pazarlarda marka araştırması yapılmalıdır.

### 7.2. Ürünün tamamlanmış görünmesine rağmen üretim seviyesinde olmaması

Mevcut kodda Pro durumu bir önizleme/demo anahtarıdır. Gerçek abonelik ve satın alma geri yükleme akışı tamamlanmamıştır. Reklam alanı da yer tutucu durumundadır. Bu yüzden mevcut Pro vaatleri mağaza metnine aynen taşınmamalıdır.

19 Temmuz 2026 tarihinde çalıştırılan testlerde 87 test geçmiştir; ancak yerelleştirme test dosyası eksik `Locale` importu nedeniyle derlenememiştir. Bu hata ürün motorunun başarısız olduğunu göstermez, fakat yayın öncesi kalite kapısının henüz tamamen temiz olmadığını gösterir.

### 7.3. Skor doğruluğu ve güven riski

Solunar teori ve hava sinyallerinden üretilen sonuçlar kesin av garantisi değildir. Skor pazarlaması “balığın kesin ısıracağı saat” şeklinde yapılırsa kullanıcı güveni hızla zarar görebilir.

Ürün dili şu yönde olmalıdır:

- “Tahmini aktivite”
- “Koşulların uyumu”
- “Planlama desteği”
- “Sonuçlar tür, su ve yerel koşullara göre değişebilir”

Kişisel av kayıtları eklendiğinde genel model ile kullanıcının gerçek sonuçları ayrı gösterilmelidir.

---

## 8. Önerilen farklılaşma stratejisi

### Stratejik konumlandırma

Önerilen kategori tanımı:

> **Kişisel balıkçılık planlayıcısı ve nokta karşılaştırma uygulaması**

Önerilen temel vaat:

> “Hangi noktaya, hangi gün ve hangi saatte gitmen gerektiğini açıklar; bağlantı olmasa da çalışır ve her avdan sonra sana daha uygun hale gelir.”

Bu yaklaşım rakiple aynı özellik listesinde yarışmak yerine üç farklı değeri birleştirir:

1. **Karar:** En iyi konumu ve zamanı seçer.
2. **Güven:** Sonucun nedenini açıklar.
3. **Öğrenme:** Kullanıcının av geçmişinden kişiselleşir.

### Önerilen temel özellik: Spot Compare

Kullanıcı bir tarih ve saat aralığı seçer; uygulama kayıtlı noktaları karşılaştırır.

Her nokta için:

- Toplam skor
- En iyi zaman penceresi
- Solunar çakışma gücü
- Rüzgâr ve yağış uygunluğu
- Basınç trendi
- Yolculuk için önerilen başlangıç saati
- Verinin güncellik/çevrimdışı durumu

Sonuç örneği:

> “Cumartesi 06.00–10.00 için Sapanca, İznik'ten 14 puan daha iyi. Ana dönem gün doğumuyla çakışıyor ve rüzgâr daha düşük.”

### Önerilen rekabet hendeği: Av günlüğü ve kişisel model

Her av kaydı şu bilgileri içerebilir:

- Konum
- Tarih ve saat
- Balık türü
- Adet, ağırlık ve isteğe bağlı fotoğraf
- Kullanılan yem veya sahte yem
- Yakalama başarısı
- Otomatik eklenen hava, ay, solunar ve ileride gelgit verileri

Uygulama zamanla şu tür sonuçlar üretmelidir:

- “Bu noktada düşen basınçta daha başarılısın.”
- “Turna kayıtlarının çoğu gün doğumundan sonraki 90 dakikada.”
- “Bu yem, 12–18 km/s kuzey rüzgârında daha iyi sonuç vermiş.”

Bu veri kullanıcıya özeldir, zamanla değer kazanır ve başka bir genel solunar uygulamasının kolayca kopyalayamayacağı bir avantaj oluşturur.

### Önerilen bildirim sistemi

Bildirimler yalnızca uygulamanın belirlediği sabit kurallara değil, kullanıcı tercihlerine dayanmalıdır:

- Minimum skor
- Maksimum rüzgâr
- Maksimum yağış olasılığı
- Favori konumlar
- Favori tür
- Bildirimin kaç saat önce gönderileceği

Örnek:

> “Yarın 06.40–08.30 arasında Karasu için koşullar uygun: skor 82, rüzgâr 9 km/s, basınç düşüyor.”

---

## 9. Önerilen ürün yol haritası

### Aşama 1 — Yayına hazırlık

- SoluCast adını değiştirme
- Gerçek abonelik ve satın alma geri yükleme entegrasyonu
- Tüm testleri temiz duruma getirme
- Sekiz dil için yerelleştirme kalite kontrolü
- Çevrimdışı/güncel veri durumunu arayüzde açık gösterme
- Gizlilik politikası ve mağaza veri beyanlarını doğrulama
- Skor iddialarını tahmin/planlama diliyle yeniden yazma

### Aşama 2 — Mevcut farkı ürünleştirme

- Kayıtlı konum karşılaştırma ekranı
- Tarih ve saat aralığına göre “en iyi nokta” önerisi
- Gelişmiş ve kişiselleştirilebilir bildirim kuralları
- Gizlilik korumalı gezi/tahmin paylaşım kartı
- Çevrimdışı modun mağaza ve onboarding içinde açıkça anlatılması

### Aşama 3 — Kalıcı rekabet avantajı

- Av günlüğü
- Tür, yem ve sonuç kaydı
- Kişisel başarı analizleri
- Kullanıcının geçmişine göre kişisel skor katmanı
- İsteğe bağlı bulut yedekleme; çevrimdışı ve hesapsız kullanım korunmalı

### Aşama 4 — Veri derinliği

- Gelgit ve deniz verileri
- Su sıcaklığı, dalga ve akıntı gibi kıyı sinyalleri
- Bölgeye göre tür ve sezon bilgileri
- Yerel mevzuat, kapalı sezon ve yasal boy uyarıları için güvenilir veri ortaklıkları

---

## 10. Yeni isim değerlendirmesi

Yeni isim seçim kriterleri:

- “Solucast” ile görsel veya fonetik benzerlik taşımamalı
- Yalnızca solunar teorisine sıkışmamalı
- İleride av günlüğü, kişiselleştirme ve konum karşılaştırmasını kapsayabilmeli
- İngilizce ve hedef dillerde söylenebilir olmalı
- Mağaza aramasında ayırt edici olmalı
- Alan adı, sosyal hesap ve marka tescili araştırmasına uygun olmalı

### Birinci öneri: AnglerPulse

**Önerilen mağaza adı:** `AnglerPulse: Fishing Forecast`

**Türkçe slogan:**

> Nerede ve ne zaman balık tutulur — çevrimdışı, açıklanabilir tahmin.

**İngilizce slogan:**

> Compare your spots. Understand the conditions. Fish the right window.

Neden öneriliyor:

- “Angler” hedef kullanıcıyı doğrudan tanımlar.
- “Pulse” aktivite, değişen koşullar, bildirim ve güncel durum fikrini taşır.
- Solunar özelliğine sıkışmadan ürünün gelecekteki kişisel analiz yönünü kapsar.
- İlk genel web ve mağaza aramasında aynı adla belirgin bir balıkçılık uygulaması görülmemiştir.

Bu ilk araştırma hukuki uygunluk veya kullanılabilirlik garantisi değildir. İsim kesinleşmeden önce resmi marka veri tabanları, uygulama mağazaları, alan adları ve sosyal platformlar kontrol edilmelidir.

### Alternatif isimler

| İsim | Güçlü tarafı | Zayıf tarafı |
|---|---|---|
| **SpotPulse** | Çoklu konum ve nokta karşılaştırmasını iyi anlatır | Balıkçılık ilk bakışta anlaşılmayabilir |
| **BiteArc** | Aktivite eğrisi ve ısırma zamanını çağrıştırır | `bitearc.com` kayıtlı görünmektedir |
| **CatchWindow** | En iyi zaman penceresini açık anlatır | Jenerik ve tescili daha zor olabilir |
| **FishSignal** | Basit, uluslararası ve anlaşılır | Ayırt ediciliği daha düşüktür |
| **AnglerWindow** | Kullanıcı ve zaman penceresini birlikte anlatır | AnglerPulse kadar akıcı değildir |

Nihai uzman tercihi: **AnglerPulse**.

---

## 11. Önerilen mağaza konumlandırması

### Kısa açıklama

> Compare fishing spots, understand every score and find your best time — even offline.

### Türkçe kısa açıklama

> Noktalarını karşılaştır, skoru anla ve en iyi balıkçılık zamanını bul — çevrimdışı bile.

### İlk mağaza ekran görüntüsü mesajları

1. **Compare Your Fishing Spots**
   Aynı gün için kayıtlı noktaları karşılaştır.

2. **Know Why the Score Changes**
   Ay, solunar dönem, basınç ve gün ışığının etkisini gör.

3. **Works When the Signal Doesn't**
   Astronomi ve solunar dönemler cihazında hesaplanır.

4. **Get Alerts for Your Conditions**
   Skor, rüzgâr ve yağış tercihlerine göre uyarı al.

5. **Learn From Every Catch**
   Av kayıtlarından kendi başarılı koşullarını keşfet.

Son ekran mesajı, av günlüğü tamamlanmadan kullanılmamalıdır.

---

## 12. Nihai uzman görüşü

AnglerPulse teknik olarak yalnızca basit bir solunar takvim değildir; çevrimdışı astronomi, konum yönetimi, açıklanabilir skor ve bildirim altyapısı sayesinde iyi bir ürün temeline sahiptir. Buna rağmen önceki isim ve ana özellik paketi rakip Solucast ile gereğinden fazla örtüşüyordu.

Rakibi özellik özellik takip etmek yanlış strateji olur. Gelgit ve paylaşım gibi eksikler kapatılabilir, fakat ürünün asıl iddiası şu olmalıdır:

> **Genel bir “bugün balık olur mu?” uygulaması değil; kullanıcının kendi noktaları ve geçmiş sonuçları üzerinden “nereye ve ne zaman gitmeliyim?” sorusunu cevaplayan kişisel karar aracı.**

Bu strateji doğrultusunda öncelik sırası:

1. İsmi **AnglerPulse** veya marka araştırmasından geçecek benzer derecede ayırt edici bir adla değiştirmek
2. Mevcut çoklu konum altyapısını gerçek bir konum karşılaştırma ürününe dönüştürmek
3. Üretim aboneliği, testler ve yerelleştirme kalitesini tamamlamak
4. Av günlüğü ve kişisel tahmin katmanıyla kalıcı rekabet avantajı oluşturmak
5. Daha sonra gelgit, paylaşım ve tür verileriyle veri derinliğini artırmak

Bu yol izlendiğinde ürün, rakip Solucast'ın başka isimli bir alternatifi olmaktan çıkar ve kendine ait, savunulabilir bir kategori konumuna sahip olur.
