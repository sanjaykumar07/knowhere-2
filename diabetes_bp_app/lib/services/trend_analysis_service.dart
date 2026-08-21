import '../models/glucose_reading.dart';
import '../models/bp_reading.dart';

/// Direction of a metric's recent movement, decided by simple, transparent
/// rules (see [TrendAnalysisService]). This is NOT a medical assessment.
enum TrendDirection { stable, increasing, decreasing, insufficientData }

/// Immutable result of analysing a series of readings.
///
/// Carries the basic statistics the UI needs (latest / average / min / max /
/// count) plus a rule-based [direction] and a plain-language [insight].
class TrendSummary {
  final int count;
  final double? latest;
  final double? average;
  final double? min;
  final double? max;
  final TrendDirection direction;

  /// Percent change of the recent half vs the earlier half of the series.
  /// Null when there aren't enough readings to compute a trend.
  final double? percentChange;

  /// Informational, non-diagnostic sentence for display.
  final String insight;

  const TrendSummary({
    required this.count,
    required this.latest,
    required this.average,
    required this.min,
    required this.max,
    required this.direction,
    required this.percentChange,
    required this.insight,
  });

  bool get hasData => count > 0;

  /// Short label for a summary tile.
  String get directionLabel {
    switch (direction) {
      case TrendDirection.stable:
        return 'Stable';
      case TrendDirection.increasing:
        return 'Increasing';
      case TrendDirection.decreasing:
        return 'Decreasing';
      case TrendDirection.insufficientData:
        return '—';
    }
  }
}

/// Rule-based trend analysis for the prototype.
///
/// Intentionally simple and transparent — this is NOT machine learning and NOT
/// a medical diagnosis. It computes basic statistics and classifies recent
/// movement by comparing the average of the more recent half of the readings
/// against the earlier half, using documented thresholds so a tiny fluctuation
/// is never reported as a trend.
///
/// Keep this class free of Flutter/Firestore imports so it stays unit-testable.
class TrendAnalysisService {
  /// Fewer than this many readings → we don't claim a trend.
  static const int kMinReadings = 4;

  /// Movement within ±this percent is treated as "stable".
  static const double kStableBandPercent = 5.0;

  /// Shown alongside insights in the UI.
  static const String kDisclaimer =
      'Insights are informational and not a medical diagnosis.';

  /// Analyse the glucose value series.
  TrendSummary analyzeGlucose(List<GlucoseReading> readings) {
    final values = _sortedValues(readings, (r) => r.value, (r) => r.timestamp);
    return _analyze(values, metricLabel: 'glucose');
  }

  /// Analyse the systolic series (the primary driver of the BP trend).
  TrendSummary analyzeBpSystolic(List<BPReading> readings) {
    final values =
        _sortedValues(readings, (r) => r.systolic.toDouble(), (r) => r.timestamp);
    return _analyze(values, metricLabel: 'blood pressure');
  }

  /// Analyse the diastolic series (used for its average / range in the UI).
  TrendSummary analyzeBpDiastolic(List<BPReading> readings) {
    final values =
        _sortedValues(readings, (r) => r.diastolic.toDouble(), (r) => r.timestamp);
    return _analyze(values, metricLabel: 'blood pressure');
  }

  /// Extracts a value series ordered oldest → newest without mutating [items].
  List<double> _sortedValues<T>(
    List<T> items,
    double Function(T) value,
    DateTime Function(T) time,
  ) {
    final sorted = [...items]..sort((a, b) => time(a).compareTo(time(b)));
    return sorted.map(value).toList();
  }

  /// Core routine. [values] must be ordered oldest → newest.
  TrendSummary _analyze(List<double> values, {required String metricLabel}) {
    if (values.isEmpty) {
      return TrendSummary(
        count: 0,
        latest: null,
        average: null,
        min: null,
        max: null,
        direction: TrendDirection.insufficientData,
        percentChange: null,
        insight:
            'No readings yet. Add a reading to start seeing your $metricLabel trend.',
      );
    }

    final count = values.length;
    final latest = values.last;
    final total = values.reduce((a, b) => a + b);
    final average = total / count;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);

    if (count < kMinReadings) {
      return TrendSummary(
        count: count,
        latest: latest,
        average: average,
        min: minV,
        max: maxV,
        direction: TrendDirection.insufficientData,
        percentChange: null,
        insight:
            'Not enough readings yet to identify a meaningful $metricLabel trend.',
      );
    }

    // Compare the earlier half vs the more recent half (equal-sized,
    // non-overlapping; the middle reading of an odd-length series is skipped).
    final half = count ~/ 2;
    final earlier = values.sublist(0, half);
    final recent = values.sublist(count - half);
    final earlierAvg = earlier.reduce((a, b) => a + b) / earlier.length;
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;

    final percentChange =
        earlierAvg == 0 ? null : (recentAvg - earlierAvg) / earlierAvg * 100;
    final pct = percentChange ?? 0;

    TrendDirection direction;
    String insight;
    if (pct.abs() < kStableBandPercent) {
      direction = TrendDirection.stable;
      insight =
          'Your recent $metricLabel readings have remained relatively stable.';
    } else if (pct > 0) {
      direction = TrendDirection.increasing;
      insight = 'Your recent $metricLabel readings show an upward trend.';
    } else {
      direction = TrendDirection.decreasing;
      insight = 'Your recent $metricLabel readings show a downward trend.';
    }

    return TrendSummary(
      count: count,
      latest: latest,
      average: average,
      min: minV,
      max: maxV,
      direction: direction,
      percentChange: percentChange,
      insight: insight,
    );
  }
}
