import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/location/location_service.dart';
import '../../data/location/saved_location.dart';
import '../location/location_providers.dart';
import '../today/today_providers.dart';
import 'entitlement.dart';
import 'upgrade_sheet.dart';

/// Konum başlığına dokununca açılan hızlı konum değiştirici. Kayıtlı konumlar
/// arası seçim + "mevcut konumum" (GPS) + şehir arama. Free tier: 1 konum.
void showLocationSwitcher(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => const _LocationSwitcherSheet(),
  );
}

/// Seçici kapanırken yeni bir sheet açılması gerektiğinde, kapanacak sheet'in
/// bağlamını kullanma. Aksi halde Android'de GPS izni hiç tetiklenmeden akış
/// sessizce bitebilir.
void _openAddLocationAfterClosingSwitcher(
  BuildContext context,
  WidgetRef ref, {
  bool useCurrentImmediately = false,
}) {
  final navigator = Navigator.of(context);
  navigator.pop();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (navigator.mounted) {
      showAddLocationSheet(
        navigator.context,
        ref,
        useCurrentImmediately: useCurrentImmediately,
      );
    }
  });
}

class _LocationSwitcherSheet extends ConsumerWidget {
  const _LocationSwitcherSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationsProvider);
    final scheme = Theme.of(context).colorScheme;
    final isPro = ref.watch(isProPreviewProvider);
    final visibleLocations = isPro
        ? state.locations
        : state.locations.where((loc) => loc.name == state.activeName).toList();
    final lockedLocationCount = state.locations.length - visibleLocations.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Switch location', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final loc in visibleLocations)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                loc.name == state.activeName
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: loc.name == state.activeName
                    ? scheme.tertiary
                    : scheme.onSurfaceVariant,
              ),
              title: Text(loc.name),
              onTap: () {
                ref.read(locationsProvider.notifier).selectActive(loc.name);
                Navigator.of(context).pop();
              },
            ),
          const SizedBox(height: 8),
          if (!state.active.isDeviceLocation) ...[
            OutlinedButton.icon(
              onPressed: () => _openAddLocationAfterClosingSwitcher(
                context,
                ref,
                useCurrentImmediately: true,
              ),
              icon: const Icon(Icons.my_location),
              label: const Text('Use my current location'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () {
              if (isLocationAddLocked(
                  currentCount: state.locations.length, isPro: isPro)) {
                Navigator.of(context).pop();
                showUpgradeTeaser(context, ref, feature: 'Multiple locations');
                return;
              }
              _openAddLocationAfterClosingSwitcher(context, ref);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add location'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
          if (lockedLocationCount > 0) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline, color: scheme.outline),
              title: Text(
                '$lockedLocationCount saved ${lockedLocationCount == 1 ? 'location' : 'locations'}',
              ),
              subtitle: const Text('Available with SoluCast Pro'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showUpgradeTeaser(
                context,
                ref,
                feature: 'Multiple locations',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// GPS ("mevcut konumum") + canlı şehir araması. Gerçek Open-Meteo geocoding;
/// GPS geolocator. İkisi de konumu ekleyip aktif yapar.
void showAddLocationSheet(
  BuildContext context,
  WidgetRef ref, {
  bool useCurrentImmediately = false,
}) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: _AddLocationSheet(useCurrentImmediately: useCurrentImmediately),
    ),
  );
}

class _AddLocationSheet extends ConsumerStatefulWidget {
  const _AddLocationSheet({this.useCurrentImmediately = false});

  final bool useCurrentImmediately;

  @override
  ConsumerState<_AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends ConsumerState<_AddLocationSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _gpsBusy = false;

  @override
  void initState() {
    super.initState();
    if (widget.useCurrentImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _useCurrent();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _pick(SavedLocation location, {bool replaceActive = false}) {
    final controller = ref.read(locationsProvider.notifier);
    if (replaceActive) {
      controller.replaceActive(location);
    } else {
      controller.add(location);
      controller.selectActive(location.name);
    }
    Navigator.of(context).pop();
  }

  Future<void> _useCurrent() async {
    setState(() => _gpsBusy = true);
    try {
      final loc = await ref.read(locationServiceProvider).currentLocation();
      if (mounted) {
        final state = ref.read(locationsProvider);
        final isPro = ref.read(isProPreviewProvider);
        _pick(
          loc,
          replaceActive: isLocationAddLocked(
              currentCount: state.locations.length, isPro: isPro),
        );
      }
    } on LocationFailure catch (e) {
      if (mounted) {
        setState(() => _gpsBusy = false);
        await _showLocationFailure(e);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _gpsBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Couldn\'t get your location. Try searching.')));
      }
    }
  }

  Future<void> _showLocationFailure(LocationFailure failure) async {
    final service = ref.read(locationServiceProvider);
    final opensAppSettings =
        failure.reason == LocationFailureReason.permissionDeniedForever;
    final opensLocationSettings =
        failure.reason == LocationFailureReason.serviceDisabled;

    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(opensAppSettings ? Icons.settings_outlined : Icons.location_off),
        title: Text(
          opensLocationSettings
              ? 'Turn on location services'
              : 'Allow location access',
        ),
        content: Text(
          opensLocationSettings
              ? 'Turn on Location in your device settings to use your current position.'
              : opensAppSettings
                  ? 'Location access was permanently denied. Enable it in app settings to use your current position.'
                  : 'Allow location access when prompted, or search for a city instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          if (opensLocationSettings || opensAppSettings)
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(opensAppSettings ? 'Open app settings' : 'Open settings'),
            ),
        ],
      ),
    );

    if (shouldOpenSettings != true) return;
    if (opensAppSettings) {
      await service.openAppSettings();
    } else if (opensLocationSettings) {
      await service.openLocationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final results = _query.length >= 2
        ? ref.watch(geocodingSearchProvider(_query))
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a location', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _gpsBusy ? null : _useCurrent,
            icon: _gpsBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: const Text('Use my current location'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: false,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Search a city…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: _buildResults(context, results),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
      BuildContext context, AsyncValue<List<SavedLocation>>? results) {
    final scheme = Theme.of(context).colorScheme;
    if (results == null) {
      // Arama boşken hızlı öneriler (preset şehirler).
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('SUGGESTIONS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant, letterSpacing: 0.8)),
          ),
          for (final p in SavedLocation.presets)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(p.name),
              onTap: () => _pick(p),
            ),
        ],
      );
    }
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text('Search failed. Check your connection.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text('No matches.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          );
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: Text(list[i].name),
            subtitle: Text(list[i].timeZoneId,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            onTap: () => _pick(list[i]),
          ),
        );
      },
    );
  }
}
