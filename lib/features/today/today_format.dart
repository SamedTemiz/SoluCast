import '../../core/core.dart';

/// UI biçimlendirme yardımcıları. Zaman damgaları UTC; konum ofsetiyle yerel
/// duvar-saatine çevrilir. (Birim/12-24s tercihi Ayarlar'da; şimdilik 24s.)
class TodayFormat {
  const TodayFormat(this.offset, {this.use24h = true, this.turkish = false});

  final Duration offset;
  final bool use24h;
  final bool turkish;

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
  static String countdown(Duration d, {bool turkish = false}) {
    if (d.isNegative) return turkish ? 'şimdi' : 'now';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return turkish ? '${h}sa ${m}dk içinde' : 'in ${h}h ${m}m';
    return turkish ? '${m}dk içinde' : 'in ${m}m';
  }

  /// 1–5 balık derecesinin kısa statü etiketi (Stitch: "Very Good").
  static String ratingLabel(int rating, {bool turkish = false}) {
    switch (rating) {
      case 5:
        return turkish ? 'Mükemmel' : 'Excellent';
      case 4:
        return turkish ? 'Çok İyi' : 'Very Good';
      case 3:
        return turkish ? 'İyi' : 'Good';
      case 2:
        return turkish ? 'Orta' : 'Fair';
      default:
        return turkish ? 'Zayıf' : 'Poor';
    }
  }

  static String periodLabel(SolunarPeriodType type, {bool turkish = false}) =>
      type == SolunarPeriodType.major
      ? (turkish ? 'Ana dönem' : 'Major')
      : (turkish ? 'İkincil dönem' : 'Minor');

  /// Skor faktör anahtarını okunur başlığa çevirir (l10n yerine geçici).
  static String factorLabel(String key, {bool turkish = false}) {
    switch (key) {
      case 'moon_phase':
        return turkish ? 'Ay evresi' : 'Moon phase';
      case 'twilight_overlap':
        return turkish
            ? 'Şafak / alacakaranlık çakışması'
            : 'Dawn / dusk overlap';
      case 'pressure_trend':
        return turkish ? 'Basınç eğilimi' : 'Pressure trend';
      case 'seasonal':
        return turkish ? 'Mevsim' : 'Season';
      default:
        return key;
    }
  }

  static String moonPhaseLabel(MoonPhase phase, {bool turkish = false}) {
    switch (phase) {
      case MoonPhase.newMoon:
        return turkish ? 'Yeni Ay' : 'New Moon';
      case MoonPhase.waxingCrescent:
        return turkish ? 'Büyüyen Hilal' : 'Waxing Crescent';
      case MoonPhase.firstQuarter:
        return turkish ? 'İlk Dördün' : 'First Quarter';
      case MoonPhase.waxingGibbous:
        return turkish ? 'Büyüyen Şişkin Ay' : 'Waxing Gibbous';
      case MoonPhase.fullMoon:
        return turkish ? 'Dolunay' : 'Full Moon';
      case MoonPhase.waningGibbous:
        return turkish ? 'Küçülen Şişkin Ay' : 'Waning Gibbous';
      case MoonPhase.lastQuarter:
        return turkish ? 'Son Dördün' : 'Last Quarter';
      case MoonPhase.waningCrescent:
        return turkish ? 'Küçülen Hilal' : 'Waning Crescent';
    }
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const List<String> _monthsFull = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _weekdaysFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _monthsTr = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  static const List<String> _monthsFullTr = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  static const List<String> _weekdaysTr = [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];
  static const List<String> _weekdaysFullTr = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  static String longDate(DateTime date, {bool turkish = false}) => turkish
      ? '${_weekdaysTr[date.weekday - 1]}, ${date.day} ${_monthsTr[date.month - 1]}'
      : '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';

  /// Gün Detayı başlığı: "Saturday, July 18" (Stitch).
  static String longDateFull(DateTime date, {bool turkish = false}) => turkish
      ? '${_weekdaysFullTr[date.weekday - 1]}, ${date.day} ${_monthsFullTr[date.month - 1]}'
      : '${_weekdaysFull[date.weekday - 1]}, ${_monthsFull[date.month - 1]} ${date.day}';

  static String shortWeekday(DateTime date, {bool turkish = false}) =>
      (turkish ? _weekdaysTr : _weekdays)[date.weekday - 1];
}
