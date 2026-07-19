import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization.dart';
import '../calendar/calendar_screen.dart';
import '../locations/locations_screen.dart';
import '../notifications/notification_providers.dart';
import '../settings/settings_screen.dart';
import '../shared/location_switcher_sheet.dart';
import '../today/today_screen.dart';
import '../today/today_providers.dart';

/// Single activity + bottom tabs (Today · Forecast · Locations · Settings).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  late final PageController _pageController;

  static const _tabs = [
    _TabDef(Icons.today_outlined, Icons.today),
    _TabDef(Icons.calendar_month_outlined, Icons.calendar_month),
    _TabDef(Icons.map_outlined, Icons.map),
    _TabDef(Icons.settings_outlined, Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
    // Bildirim izni yalnız onboarding veya kullanıcının açıkça etkinleştirdiği
    // bir ayardan istenir. Açılışta sistem ayarına atmak özellikle Xiaomi
    // cihazlarda uygulamanın yönelimini bozuyormuş gibi görünür.
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Plan (tercih/konum/skor) değiştikçe bildirimleri yeniden kurar —
    // her açılışta da çalışır → self-healing (T4).
    ref.watch(notificationSchedulerProvider);

    return Scaffold(
      body: Column(
        children: [
          const _HomeLocationBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                if (_index != index) setState(() => _index = index);
              },
              children: const [
                _KeepAlivePage(child: TodayView()),
                _KeepAlivePage(child: CalendarScreen()),
                _KeepAlivePage(child: LocationsScreen()),
                _KeepAlivePage(child: SettingsScreen()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectDestination,
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: Icon(_tabs[i].icon),
              selectedIcon: Icon(_tabs[i].selected),
              label: switch (i) {
                0 => context.l10n('Today', 'Bugün'),
                1 => context.l10n('Forecast', 'Tahmin'),
                2 => context.l10n('Locations', 'Konumlar'),
                _ => context.l10n('Settings', 'Ayarlar'),
              },
            ),
        ],
      ),
    );
  }
}

/// Sekmeler arası geçişte sayfa durumunu korur; yalnızca görünür sayfa hareket
/// eder, örneğin takvimde seçilen ay veya liste kaydırma konumu kaybolmaz.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});
  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Kök sekmelerin tamamında aynı konumu gösteren ve konum seçiciyi açan
/// kalıcı uygulama çubuğu. Böylece ekran içi tekrarlı/işlevsiz başlıklar yoktur.
class _HomeLocationBar extends ConsumerWidget {
  const _HomeLocationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final location = ref.watch(activeLocationProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: InkWell(
            onTap: () => showLocationSwitcher(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: scheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.icon, this.selected);
  final IconData icon;
  final IconData selected;
}
