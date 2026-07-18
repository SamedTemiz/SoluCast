import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solucast/app/theme.dart';
import 'package:solucast/data/location/saved_location.dart';
import 'package:solucast/data/notifications/notification_service.dart';
import 'package:solucast/data/prefs/preferences.dart';
import 'package:solucast/data/weather/weather_data.dart';
import 'package:solucast/data/weather/weather_repository.dart';
import 'package:solucast/features/home/home_shell.dart';
import 'package:solucast/features/notifications/notification_providers.dart';
import 'package:solucast/features/weather/weather_providers.dart';

/// Hava katmanını hermetik yapar — widget testleri gerçek ağa çıkmaz.
class _FakeWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherData?> fetchCurrent(SavedLocation location) async => null;
}

void main() {
  Future<void> pumpApp(WidgetTester tester,
      {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          // Platform kanalı olmayan test ortamı için sessiz zamanlayıcı.
          notificationServiceProvider
              .overrideWithValue(const NoopNotificationScheduler()),
          weatherRepositoryProvider.overrideWithValue(_FakeWeatherRepository()),
        ],
        child: MaterialApp(theme: SoluTheme.dark(), home: const HomeShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Bugün ekranı hero kartı ve bölümleri render eder', (tester) async {
    await pumpApp(tester);

    expect(find.text('FISHING CONDITION'), findsOneWidget);
    expect(find.text('ACTIVITY TIMELINE'), findsOneWidget);
    expect(find.textContaining('/ 5'), findsOneWidget);

    const statuses = ['Excellent', 'Very Good', 'Good', 'Fair', 'Poor'];
    expect(
      statuses.any((s) => find.text(s).evaluate().isNotEmpty),
      isTrue,
      reason: 'hero kart bir statü etiketi göstermeli',
    );

    await tester.scrollUntilVisible(find.text('SOLUNAR DATA'), 200);
    expect(find.text('SOLUNAR DATA'), findsOneWidget);
  });

  testWidgets('WHY? butonu faktör dökümü sheet\'ini açar', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('WHY?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Why'), findsOneWidget);
    expect(find.text('Moon phase'), findsOneWidget);
  });

  testWidgets('Alt navigasyon 4 sekme arasında geçiş yapar', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Takvim'));
    await tester.pumpAndSettle();
    expect(find.text('Forecast'), findsOneWidget);

    await tester.tap(find.text('Konumlar'));
    await tester.pumpAndSettle();
    expect(find.text('My Locations'), findsOneWidget);

    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Pro Preview'), findsOneWidget);

    await tester.tap(find.text('Bugün'));
    await tester.pumpAndSettle();
    expect(find.text('FISHING CONDITION'), findsOneWidget);
  });

  testWidgets('Takvimde bugüne dokununca Gün Detayı açılır, geri döner', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Takvim'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Today').first);
    await tester.pumpAndSettle();

    expect(find.text('Hourly Activity'), findsOneWidget);
    expect(find.text('Solunar Periods'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Forecast'), findsOneWidget);
  });

  testWidgets('Ayarlarda Pro Preview açınca kilitler kalkar', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Takvim'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('Free kullanıcıda ikinci kayıtlı konum kilitli görünür',
      (tester) async {
    // Pro-preview döneminden kalan 2 kayıt + Pro kapalı senaryosu.
    await pumpApp(tester, prefs: {
      PrefKeys.locations:
          '[{"name":"İstanbul","lat":41.0082,"lon":28.9784,"tz":"Europe/Istanbul","isDeviceLocation":false},'
          '{"name":"Sydney","lat":-33.8688,"lon":151.2093,"tz":"Australia/Sydney","isDeviceLocation":false}]',
      PrefKeys.activeLocation: 'İstanbul',
      PrefKeys.proPreview: false,
    });

    await tester.tap(find.text('Konumlar'));
    await tester.pumpAndSettle();

    // İkinci kayıt silinmemiş ama kilitli: kart listede + kilit ikonu var.
    expect(find.text('Sydney'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
    expect(find.text('ACTIVE'), findsOneWidget); // yalnız İstanbul aktif

    // Kilitli karta dokunma → upgrade teaser (aktif konum DEĞİŞMEZ).
    await tester.tap(find.text('Sydney'));
    await tester.pumpAndSettle();
    expect(find.text('Enable Pro Preview'), findsOneWidget);
  });
}
