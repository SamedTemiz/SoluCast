import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:angler_pulse/app/theme.dart';
import 'package:angler_pulse/app/app.dart';
import 'package:angler_pulse/data/location/saved_location.dart';
import 'package:angler_pulse/data/notifications/notification_service.dart';
import 'package:angler_pulse/data/prefs/preferences.dart';
import 'package:angler_pulse/data/weather/weather_data.dart';
import 'package:angler_pulse/data/weather/weather_repository.dart';
import 'package:angler_pulse/features/home/home_shell.dart';
import 'package:angler_pulse/features/notifications/notification_providers.dart';
import 'package:angler_pulse/features/onboarding/onboarding_screen.dart';
import 'package:angler_pulse/features/paywall/paywall_screen.dart';
import 'package:angler_pulse/features/weather/weather_providers.dart';

/// Hava katmanını hermetik yapar — widget testleri gerçek ağa çıkmaz.
class _FakeWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherData?> fetchCurrent(SavedLocation location) async => null;
}

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
    TextScaler? textScaler,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          // Platform kanalı olmayan test ortamı için sessiz zamanlayıcı.
          notificationServiceProvider.overrideWithValue(
            const NoopNotificationScheduler(),
          ),
          weatherRepositoryProvider.overrideWithValue(_FakeWeatherRepository()),
        ],
        child: MaterialApp(
          theme: SoluTheme.dark(),
          builder: (context, child) => textScaler == null
              ? child!
              : MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: child!,
                ),
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Bugün ekranı hero kartı ve bölümleri render eder', (
    tester,
  ) async {
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

    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('SOLUNAR DATA'), findsOneWidget);
    // Sahte hava reposu null döner → çevrimdışı → güven bandı görünür.
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });

  testWidgets('WHY? butonu faktör dökümü sheet\'ini açar', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('WHY?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Why'), findsOneWidget);
    expect(find.text('Moon phase'), findsOneWidget);
    // Eyleme dönük çıkarım bandı (bu sayfanın yeni değer katmanı).
    expect(find.byIcon(Icons.tips_and_updates_outlined), findsOneWidget);
  });

  testWidgets('Alt navigasyon 4 sekme arasında geçiş yapar', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Forecast'), findsWidgets);

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();
    expect(find.text('My Locations'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Pro Preview'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.today_outlined));
    await tester.pumpAndSettle();
    expect(find.text('FISHING CONDITION'), findsOneWidget);
  });

  testWidgets('Language and theme choices apply immediately and persist', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({PrefKeys.onboardingDone: true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(
            const NoopNotificationScheduler(),
          ),
          weatherRepositoryProvider.overrideWithValue(_FakeWeatherRepository()),
        ],
        child: const AnglerPulseApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language').at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Türkçe').last);
    await tester.pumpAndSettle();

    expect(find.text('Ayarlar'), findsWidgets);
    expect(find.text('Bugün'), findsOneWidget);
    expect(prefs.getString(PrefKeys.language), 'turkish');

    await tester.tap(find.text('Tema').at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Açık'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Ayarlar').first)).brightness,
      Brightness.light,
    );
    expect(prefs.getString(PrefKeys.themeMode), 'light');
  });

  testWidgets('Takvimde bugüne dokununca Gün Detayı açılır, geri döner', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Today').first);
    await tester.pumpAndSettle();

    expect(find.text('Hourly Activity'), findsOneWidget);
    expect(find.text('Solunar Periods'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Forecast'), findsWidgets);
  });

  testWidgets('Ayarlarda Pro Preview açınca kilitler kalkar', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('Free kullanıcıda ikinci kayıtlı konum kilitli görünür', (
    tester,
  ) async {
    // Pro-preview döneminden kalan 2 kayıt + Pro kapalı senaryosu.
    await pumpApp(
      tester,
      prefs: {
        PrefKeys.locations:
            '[{"name":"İstanbul","lat":41.0082,"lon":28.9784,"tz":"Europe/Istanbul","isDeviceLocation":false},'
            '{"name":"Sydney","lat":-33.8688,"lon":151.2093,"tz":"Australia/Sydney","isDeviceLocation":false}]',
        PrefKeys.activeLocation: 'İstanbul',
        PrefKeys.proPreview: false,
      },
    );

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    // İkinci kayıt silinmemiş ama kilitli: kart listede + kilit ikonu var.
    expect(find.text('Sydney'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
    expect(find.text('ACTIVE'), findsOneWidget); // yalnız İstanbul aktif

    // Kilitli karta dokunma → teaser → tam paywall hunisi.
    await tester.tap(find.text('Sydney'));
    await tester.pumpAndSettle();
    expect(find.text('See Pro plans'), findsOneWidget);

    await tester.tap(find.text('See Pro plans'));
    await tester.pumpAndSettle();
    expect(find.text('Fish smarter with Pro'), findsOneWidget);
    expect(find.text('2 MONTHS FREE'), findsOneWidget); // yıllık öne çıkan

    // Trial başlat (şimdilik Pro preview) → kilitler kalkmalı.
    await tester.tap(find.text('Start 7-day free trial'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.text('ACTIVE'), findsOneWidget);
  });

  testWidgets('Narrow screen and larger text do not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester, textScaler: const TextScaler.linear(1.3));

    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Onboarding and paywall fit a compact screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Widget scaled(Widget child) => MaterialApp(
      theme: SoluTheme.dark(),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.3)),
        child: page!,
      ),
      home: child,
    );

    await tester.pumpWidget(
      ProviderScope(child: scaled(const OnboardingScreen())),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ProviderScope(child: scaled(const PaywallScreen())),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
