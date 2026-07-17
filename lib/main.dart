import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/prefs/preferences.dart';
import 'data/timezone/app_timezone.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTimeZone.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SoluCastApp(),
    ),
  );
}
