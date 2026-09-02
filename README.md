# Huddle (EtkinlikApp)

Üniversite öğrencilerinin etkinlik oluşturup keşfedebildiği, topluluklara katılabildiği bir sosyal etkinlik platformu. Backend .NET 9 ile, mobil uygulama Flutter ile geliştirilmiştir.

## Özellikler

- Etkinlik oluşturma, düzenleme, kategoriye göre keşfetme ve haritada görüntüleme
- Etkinliklere katılım isteği gönderme, isteklerin onaylanması/reddedilmesi
- Kullanıcı takip sistemi
- Etkinlik sonrası değerlendirme (puanlama ve yorum) sistemi
- Topluluklar: kullanıcıların kendi topluluklarını oluşturup üye kabul edebildiği, üyelerin "Yönetici" rolüyle işaretlendiği yapı
- Bildirim sistemi (bekleyen katılım istekleri için)
- Profil fotoğrafı ve etkinlik anı fotoğrafları için medya yükleme (Cloudinary)

## Teknolojiler

**Backend:** .NET 9, ASP.NET Core Web API, Entity Framework Core, PostgreSQL, JWT ile kimlik doğrulama, Cloudinary

**Mobil:** Flutter, Dio, flutter_map, flutter_secure_storage

## Proje Yapısı

Backend katmanlı mimariyle yazıldı, bağımlılıklar tek yönde akıyor:

```
EtkinlikApp.Core            -> Entity'ler ve enum'lar (hiçbir şeye bağımlı değil)
EtkinlikApp.Infrastructure  -> AppDbContext, EF Core migration'ları
EtkinlikApp.Api             -> Controller'lar, DTO'lar (dış dünyaya açılan uçlar)
huddle_mobile               -> Flutter mobil uygulaması
```

`huddle_mobile/lib/services/` içindeki dosyalar backend'deki her controller'a karşılık gelir, `huddle_mobile/lib/screens/` içindeki ekranlar ise bu servisleri çağırarak arayüzü oluşturur.

## Kurulum

### Backend

1. PostgreSQL'in bilgisayarında kurulu ve çalışır durumda olduğundan emin ol.
2. `EtkinlikApp.Api/appsettings.Example.json` dosyasını `appsettings.json` olarak kopyala ve içindeki veritabanı bağlantı bilgisini, JWT anahtarını ve Cloudinary bilgilerini kendi değerlerinle doldur. (`appsettings.json` gerçek anahtarlar içerdiği için `.gitignore` ile depoya dahil edilmez.)
3. `EtkinlikApp.Api` klasöründeyken veritabanı tablolarını oluştur:
   ```
   dotnet ef database update --project ../EtkinlikApp.Infrastructure --startup-project .
   ```
4. API'yi çalıştır:
   ```
   dotnet run
   ```

### Mobil uygulama (Flutter)

1. `huddle_mobile` klasörüne gir.
2. Bağımlılıkları yükle:
   ```
   flutter pub get
   ```
3. `lib/services/api_client.dart` içindeki `baseUrl` değerinin backend'in çalıştığı adresle eşleştiğinden emin ol.
4. Uygulamayı çalıştır:
   ```
   flutter run
   ```

## Not

Bu proje bir staj/öğrenme sürecinin parçası olarak geliştirilmektedir. Geliştirme sürecinde Claude (Anthropic) ile birlikte çalışılmıştır; commit geçmişinde bu şeffaf şekilde belirtilir.
