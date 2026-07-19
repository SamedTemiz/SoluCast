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
}
