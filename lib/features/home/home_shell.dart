import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../calendar/calendar_screen.dart';
import '../locations/locations_screen.dart';
import '../notifications/notification_providers.dart';
import '../settings/settings_screen.dart';
import '../today/today_screen.dart';

/// Tek aktivite + alt tab bar (Bugün · Takvim · Konumlar · Ayarlar) — screens.md.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _tabs = [
    _TabDef('Bugün', Icons.today_outlined, Icons.today),
    _TabDef('Takvim', Icons.calendar_month_outlined, Icons.calendar_month),
    _TabDef('Konumlar', Icons.map_outlined, Icons.map),
    _TabDef('Ayarlar', Icons.settings_outlined, Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    // İzin isteği ilk kareden sonra (UI hazırken). Reddedilirse uygulama
    // bildirimsiz çalışmaya devam eder. Kalıcı onboarding akışı ayrı iş (#25).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = ref.read(notificationServiceProvider);
      await service.initialize();
      await service.requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Plan (tercih/konum/skor) değiştikçe bildirimleri yeniden kurar —
    // her açılışta da çalışır → self-healing (T4).
    ref.watch(notificationSchedulerProvider);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayView(),
          CalendarScreen(),
          LocationsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selected),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.label, this.icon, this.selected);
  final String label;
  final IconData icon;
  final IconData selected;
}
