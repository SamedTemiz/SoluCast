import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solucast/app/app.dart';
import 'package:solucast/data/location/saved_location.dart';
import 'package:solucast/data/notifications/notification_service.dart';
import 'package:solucast/data/prefs/preferences.dart';
import 'package:solucast/data/weather/weather_data.dart';
import 'package:solucast/data/weather/weather_repository.dart';
import 'package:solucast/features/notifications/notification_providers.dart';
import 'package:solucast/features/weather/weather_providers.dart';

class _FakeWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherData?> fetchCurrent(SavedLocation location) async => null;
}

/// Onboarding (screens.md §1): ilk açılışta 3 adım + soft paywall; Skip her
/// zaman görünür; tamamlanınca kalıcı olarak Home'a geçilir.
void main() {
  Future<SharedPreferences> pumpFullApp(WidgetTester tester,
      {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          notificationServiceProvider
              .overrideWithValue(const NoopNotificationScheduler()),
          weatherRepositoryProvider.overrideWithValue(_FakeWeatherRepository()),
        ],
        child: const SoluCastApp(),
      ),
    );
    await tester.pumpAndSettle();
    return sp;
  }

  testWidgets('İlk açılışta onboarding gelir, akış paywall ile biter, '
      'skip sonrası Home + kalıcı bayrak', (tester) async {
    final sp = await pumpFullApp(tester);

    // Adım 1: değer önerisi
    expect(find.text('Know the best time to fish'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Adım 2: konum izni — "Maybe later" ile geçilebilir (izinsiz de çalışır)
    expect(find.text('Forecasts for your spot'), findsOneWidget);
    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();

    // Adım 3: bildirim izni — yine geçilebilir
    expect(find.text('Never miss a 5-star day'), findsOneWidget);
    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();

    // Soft paywall: Skip belirgin, dark pattern yok
    expect(find.text('Fish smarter with Pro'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Home'dayız ve bayrak kalıcı
    expect(find.text('FISHING CONDITION'), findsOneWidget);
    expect(sp.getBool(PrefKeys.onboardingDone), isTrue);
  });

  testWidgets('Onboarding tamamlanmışsa app doğrudan Home ile açılır',
      (tester) async {
    await pumpFullApp(tester, prefs: {PrefKeys.onboardingDone: true});
    expect(find.text('FISHING CONDITION'), findsOneWidget);
    expect(find.text('Know the best time to fish'), findsNothing);
  });

  testWidgets('Onboarding paywall\'unda trial başlatılırsa Pro açık gelir',
      (tester) async {
    final sp = await pumpFullApp(tester);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start 7-day free trial'));
    await tester.pumpAndSettle();

    expect(find.text('FISHING CONDITION'), findsOneWidget);
    expect(sp.getBool(PrefKeys.proPreview), isTrue);
    expect(sp.getBool(PrefKeys.onboardingDone), isTrue);
  });
}
