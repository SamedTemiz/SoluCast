import '../../core/core.dart';

/// UI biçimlendirme yardımcıları. Zaman damgaları UTC; konum ofsetiyle yerel
/// duvar-saatine çevrilir. (Birim/12-24s tercihi Ayarlar'da; şimdilik 24s.)
class TodayFormat {
  const TodayFormat(this.offset, {this.use24h = true});

  final Duration offset;
  final bool use24h;

  String time(DateTime? utc) {
    if (utc == null) return '—';
    final l = utc.add(offset);
    if (use24h) return '${_pad(l.hour)}:${_pad(l.minute)}';
    final h12 = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final suffix = l.hour < 12 ? 'AM' : 'PM';
    return '$h12:${_pad(l.minute)} $suffix';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Bir sonraki periyoda kalan süre: "in 2h 15m" / "in 45m".
  static String countdown(Duration d) {
    if (d.isNegative) return 'now';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return 'in ${h}h ${m}m';
    return 'in ${m}m';
  }

  /// 1–5 balık derecesinin kısa statü etiketi (Stitch: "Very Good").
  static String ratingLabel(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Very Good';
      case 3:
        return 'Good';
      case 2:
        return 'Fair';
      default:
        return 'Poor';
    }
  }

  static String periodLabel(SolunarPeriodType type) =>
      type == SolunarPeriodType.major ? 'Major' : 'Minor';

  /// Skor faktör anahtarını okunur başlığa çevirir (l10n yerine geçici).
  static String factorLabel(String key) {
    switch (key) {
      case 'moon_phase':
        return 'Moon phase';
      case 'twilight_overlap':
        return 'Dawn / dusk overlap';
      case 'pressure_trend':
        return 'Pressure trend';
      case 'seasonal':
        return 'Season';
      default:
        return key;
    }
  }

  static String moonPhaseLabel(MoonPhase phase) {
    switch (phase) {
      case MoonPhase.newMoon:
        return 'New Moon';
      case MoonPhase.waxingCrescent:
        return 'Waxing Crescent';
      case MoonPhase.firstQuarter:
        return 'First Quarter';
      case MoonPhase.waxingGibbous:
        return 'Waxing Gibbous';
      case MoonPhase.fullMoon:
        return 'Full Moon';
      case MoonPhase.waningGibbous:
        return 'Waning Gibbous';
      case MoonPhase.lastQuarter:
        return 'Last Quarter';
      case MoonPhase.waningCrescent:
        return 'Waning Crescent';
    }
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static const List<String> _weekdaysFull = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static String longDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';

  /// Gün Detayı başlığı: "Saturday, July 18" (Stitch).
  static String longDateFull(DateTime date) =>
      '${_weekdaysFull[date.weekday - 1]}, ${_monthsFull[date.month - 1]} ${date.day}';

  static String shortWeekday(DateTime date) => _weekdays[date.weekday - 1];
}
