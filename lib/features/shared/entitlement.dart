import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/prefs/preferences.dart';

/// Pro durumu — **önizleme/demo amaçlı**. Gerçek satın alma (RevenueCat)
/// Hafta 4 kapsamı (monetization.md); bu, kilit UI'larını test etmek için
/// yerel bir anahtar (kalıcı). Ayarlar'da açıkça "preview" etiketiyle gösterilir.
class ProPreview extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(PrefKeys.proPreview) ??
      false;

  void toggle() => set(!state);

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(PrefKeys.proPreview, value);
  }
}

final isProPreviewProvider = NotifierProvider<ProPreview, bool>(ProPreview.new);

/// F4.3: ücretsizde bugün + yarın detay açık; **ileri** günler Pro gerektirir.
/// Geçmiş günler kilitli değildir (zaten olmuş, astronomi zaten hesaplanabilir).
bool isDateLocked({
  required DateTime candidateLocalDate,
  required DateTime todayLocalDate,
  required bool isPro,
}) {
  if (isPro) return false;
  final diff = candidateLocalDate.difference(todayLocalDate).inDays;
  return diff > 1;
}

/// F1.3: ücretsizde 1 konum, Pro'da sınırsız.
bool isLocationAddLocked({required int currentCount, required bool isPro}) {
  if (isPro) return false;
  return currentCount >= 1;
}
