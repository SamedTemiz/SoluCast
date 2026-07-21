import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:angler_pulse/app/localization.dart';

void main() {
  test(
    'every released language has a locale, a native picker label and core copy',
    () {
      for (final language in AppLanguage.values) {
        expect(language.locale.languageCode, isNotEmpty);
        expect(language.nativeName, isNotEmpty);
        if (language != AppLanguage.english &&
            language != AppLanguage.turkish) {
          expect(SoluCopy.lookup(language, 'FISHING CONDITION'), isNotNull);
          expect(SoluCopy.lookup(language, 'Solunar Periods'), isNotNull);
          expect(
            SoluCopy.lookup(language, 'Use my current location'),
            isNotNull,
          );
        }
      }
    },
  );

  test(
    'locale detection keeps Latin American Spanish and Brazilian Portuguese distinct',
    () {
      expect(
        AppLanguageDetails.fromLocale(const Locale('es', '419')),
        AppLanguage.spanishLatinAmerica,
      );
      expect(
        AppLanguageDetails.fromLocale(const Locale('pt', 'BR')),
        AppLanguage.portugueseBrazil,
      );
    },
  );

  test('new Pro and trip-brief copy is present in every released catalog', () {
    const keys = [
      'Smart trip alert',
      'ALERT RULE',
      'PLANNED FISHING TIME',
      'Copy trip brief',
      'Trip brief copied.',
      'smart_alert_summary',
      'weather_minutes_ago',
      'spot_compare_best_window',
    ];
    for (final language in AppLanguage.values.where(
      (language) =>
          language != AppLanguage.english && language != AppLanguage.turkish,
    )) {
      for (final key in keys) {
        expect(
          SoluCopy.lookup(language, key),
          isNotNull,
          reason: '$language: $key',
        );
      }
    }
  });
}
