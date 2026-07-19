/// Solunar periyot türü.
///
/// - [major]: ay meridyen geçişi (üst = tepede / alt = ayak altında) ±60 dk.
///   Günde tipik 2 adet; en yüksek aktivite pencereleri.
/// - [minor]: ay doğuşu / batışı ±30 dk. Günde tipik 2 adet; ikincil pencereler.
enum SolunarPeriodType { major, minor }

/// Periyodun hangi astronomik olaydan üretildiği — UI'da doğru etiketleme
/// için (ör. "Dawn Transit", "Moonrise"). Skor hesabını etkilemez.
enum SolunarPeriodKind { upperTransit, lowerTransit, moonrise, moonset }

/// Balık aktivitesinin yükseldiği bir zaman penceresi. Tüm zamanlar **UTC**.
class SolunarPeriod {
  final SolunarPeriodType type;
  final SolunarPeriodKind kind;
  final DateTime start;
  final DateTime peak;
  final DateTime end;

  /// Bu periyodun şafak/akşam alacakaranlığıyla çakışıp çakışmadığı — çakışan
  /// periyotlar "prime" kabul edilir ve skoru yükseltir (F2.5).
  final bool overlapsTwilight;

  const SolunarPeriod({
    required this.type,
    required this.kind,
    required this.start,
    required this.peak,
    required this.end,
    this.overlapsTwilight = false,
  });

  Duration get duration => end.difference(start);

  bool contains(DateTime utc) => !utc.isBefore(start) && !utc.isAfter(end);

  SolunarPeriod copyWith({bool? overlapsTwilight}) => SolunarPeriod(
    type: type,
    kind: kind,
    start: start,
    peak: peak,
    end: end,
    overlapsTwilight: overlapsTwilight ?? this.overlapsTwilight,
  );
}
