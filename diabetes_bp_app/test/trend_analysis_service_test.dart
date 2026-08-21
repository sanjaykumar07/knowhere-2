import 'package:flutter_test/flutter_test.dart';
import 'package:diabetes_bp_app/models/glucose_reading.dart';
import 'package:diabetes_bp_app/models/bp_reading.dart';
import 'package:diabetes_bp_app/services/trend_analysis_service.dart';

/// Fixed base time so tests are deterministic. Higher `minute` = more recent.
final _base = DateTime(2026, 1, 1, 8);

GlucoseReading _g(double value, int minute) => GlucoseReading(
      id: 'g$minute',
      value: value,
      measurementType: 'Fasting',
      timestamp: _base.add(Duration(minutes: minute)),
      source: 'test',
    );

BPReading _bp(int systolic, int diastolic, int minute) => BPReading(
      id: 'bp$minute',
      systolic: systolic,
      diastolic: diastolic,
      pulse: 70,
      timestamp: _base.add(Duration(minutes: minute)),
      source: 'test',
    );

void main() {
  final service = TrendAnalysisService();

  group('TrendAnalysisService.analyzeGlucose', () {
    test('empty list → insufficientData with null stats', () {
      final s = service.analyzeGlucose([]);
      expect(s.count, 0);
      expect(s.hasData, isFalse);
      expect(s.direction, TrendDirection.insufficientData);
      expect(s.latest, isNull);
      expect(s.average, isNull);
      expect(s.min, isNull);
      expect(s.max, isNull);
      expect(s.percentChange, isNull);
      expect(s.insight.toLowerCase(), contains('no readings'));
    });

    test('fewer than kMinReadings → insufficientData but stats present', () {
      final s = service.analyzeGlucose([_g(100, 0), _g(120, 1), _g(140, 2)]);
      expect(s.count, 3);
      expect(s.direction, TrendDirection.insufficientData);
      expect(s.latest, 140);
      expect(s.average, closeTo(120, 0.001));
      expect(s.min, 100);
      expect(s.max, 140);
      expect(s.percentChange, isNull);
      expect(s.insight.toLowerCase(), contains('not enough'));
    });

    test('flat readings → stable', () {
      final s =
          service.analyzeGlucose([_g(110, 0), _g(112, 1), _g(109, 2), _g(111, 3)]);
      expect(s.direction, TrendDirection.stable);
      expect(s.percentChange!.abs(), lessThan(TrendAnalysisService.kStableBandPercent));
      expect(s.insight.toLowerCase(), contains('stable'));
      expect(s.directionLabel, 'Stable');
    });

    test('rising readings → increasing', () {
      final s =
          service.analyzeGlucose([_g(100, 0), _g(100, 1), _g(120, 2), _g(120, 3)]);
      expect(s.direction, TrendDirection.increasing);
      expect(s.percentChange, closeTo(20, 0.001));
      expect(s.insight.toLowerCase(), contains('upward'));
      expect(s.directionLabel, 'Increasing');
    });

    test('falling readings → decreasing', () {
      final s =
          service.analyzeGlucose([_g(140, 0), _g(140, 1), _g(120, 2), _g(120, 3)]);
      expect(s.direction, TrendDirection.decreasing);
      expect(s.percentChange, closeTo(-14.2857, 0.01));
      expect(s.insight.toLowerCase(), contains('downward'));
      expect(s.directionLabel, 'Decreasing');
    });

    test('exactly +5% is a trend, not stable (band is exclusive)', () {
      final s =
          service.analyzeGlucose([_g(100, 0), _g(100, 1), _g(105, 2), _g(105, 3)]);
      expect(s.percentChange, closeTo(5, 0.001));
      expect(s.direction, TrendDirection.increasing);
    });

    test('just under +5% stays stable', () {
      final s =
          service.analyzeGlucose([_g(100, 0), _g(100, 1), _g(104, 2), _g(104, 3)]);
      expect(s.percentChange, closeTo(4, 0.001));
      expect(s.direction, TrendDirection.stable);
    });

    test('input order does not matter — series sorted oldest→newest', () {
      // Provided out of chronological order; latest is the max-timestamp value.
      final s = service.analyzeGlucose([_g(120, 10), _g(100, 0), _g(90, 5)]);
      expect(s.latest, 120);
      expect(s.min, 90);
      expect(s.max, 120);
      expect(s.average, closeTo((120 + 100 + 90) / 3, 0.001));
    });

    test('does not mutate the caller list', () {
      final input = [_g(120, 10), _g(100, 0)];
      final copy = List.of(input);
      service.analyzeGlucose(input);
      expect(input.map((r) => r.id), copy.map((r) => r.id));
    });
  });

  group('TrendAnalysisService BP', () {
    test('systolic drives its own trend', () {
      final s = service.analyzeBpSystolic(
          [_bp(120, 80, 0), _bp(122, 80, 1), _bp(140, 90, 2), _bp(142, 90, 3)]);
      expect(s.latest, 142);
      expect(s.direction, TrendDirection.increasing);
    });

    test('diastolic analysed independently of systolic', () {
      final readings = [
        _bp(120, 80, 0),
        _bp(120, 80, 1),
        _bp(120, 90, 2),
        _bp(120, 90, 3),
      ];
      final dia = service.analyzeBpDiastolic(readings);
      expect(dia.latest, 90);
      expect(dia.min, 80);
      expect(dia.max, 90);
      expect(dia.direction, TrendDirection.increasing);

      final sys = service.analyzeBpSystolic(readings);
      expect(sys.direction, TrendDirection.stable); // systolic flat at 120
    });
  });

  test('disclaimer constant is present and non-diagnostic', () {
    expect(TrendAnalysisService.kDisclaimer,
        'Insights are informational and not a medical diagnosis.');
  });
}
