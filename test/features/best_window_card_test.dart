import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:angler_pulse/app/theme.dart';
import 'package:angler_pulse/data/location/saved_location.dart';
import 'package:angler_pulse/data/notifications/notification_service.dart';
import 'package:angler_pulse/data/prefs/preferences.dart';
import 'package:angler_pulse/data/weather/weather_data.dart';
import 'package:angler_pulse/data/weather/weather_repository.dart';
import 'package:angler_pulse/features/home/home_shell.dart';
import 'package:angler_pulse/features/notifications/notification_providers.dart';
import 'package:angler_pulse/features/weather/weather_providers.dart';

class _FakeWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherData?> fetchCurrent(SavedLocation location) async => null;
}

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          notificationServiceProvider.overrideWithValue(
            const NoopNotificationScheduler(),
          ),
          weatherRepositoryProvider.overrideWithValue(_FakeWeatherRepository()),
        ],
        child: MaterialApp(theme: SoluTheme.dark(), home: const HomeShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Best Window kartı görünür, sheet açılır, Pro hunisine bağlanır', (
    tester,
  ) async {
    await pumpApp(tester);

    // Kart Bugün ekranında (motor 7 günlük tarama içinde neredeyse her zaman
    // yaklaşan bir major pencere bulur).
    final card = find.text('WHEN TO GO');
    expect(card, findsOneWidget);

    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    // Sheet: başlık + free kapsam etiketi + Pro satırı.
    expect(find.text('Best fishing windows'), findsOneWidget);
    expect(find.text('Next 7 days · active spot'), findsOneWidget);
    final proRow = find.text('See 14 days and all spots with Pro');
    expect(proRow, findsOneWidget);

    // Pro satırı → teaser → tam paywall hunisi.
    await tester.tap(proRow);
    await tester.pumpAndSettle();
    expect(find.text('See Pro plans'), findsOneWidget);
  });

  testWidgets('Pro kullanıcıda sheet 14 gün kapsamını gösterir', (
    tester,
  ) async {
    await pumpApp(tester, prefs: {PrefKeys.proPreview: true});

    final card = find.text('WHEN TO GO');
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Next 14 days · all spots'), findsOneWidget);
    expect(find.text('See 14 days and all spots with Pro'), findsNothing);
  });
}
