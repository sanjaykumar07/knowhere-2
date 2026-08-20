import 'dart:math';
import '../models/bp_reading.dart';

/// Simulated IoT blood-pressure monitor. Same design as
/// [GlucoseSimulator]: generates plausible values inside a scenario
/// band, timestamps them, and tags them as "simulated_bp_monitor".
///
/// Replace `generateReading` with a real BLE read to support actual
/// hardware later without touching the rest of the app.
enum BPScenario { normal, elevated, high }

class BPSimulator {
  static const String deviceId = 'SIM-BP-001';
  static const String source = 'simulated_bp_monitor';

  final Random _random = Random();

  // [min, max] for systolic, diastolic, pulse per scenario.
  final Map<BPScenario, Map<String, List<int>>> _ranges = {
    BPScenario.normal: {
      'systolic': [105, 120],
      'diastolic': [70, 80],
      'pulse': [60, 85],
    },
    BPScenario.elevated: {
      'systolic': [125, 139],
      'diastolic': [81, 89],
      'pulse': [70, 95],
    },
    BPScenario.high: {
      'systolic': [140, 170],
      'diastolic': [90, 110],
      'pulse': [80, 105],
    },
  };

  BPReading generateReading({BPScenario scenario = BPScenario.normal}) {
    final r = _ranges[scenario]!;
    int pick(List<int> range) =>
        range[0] + _random.nextInt(range[1] - range[0] + 1);

    return BPReading(
      id: 'bp_${DateTime.now().millisecondsSinceEpoch}',
      systolic: pick(r['systolic']!),
      diastolic: pick(r['diastolic']!),
      pulse: pick(r['pulse']!),
      timestamp: DateTime.now(),
      source: source,
    );
  }
}
