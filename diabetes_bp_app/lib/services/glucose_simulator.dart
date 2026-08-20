import 'dart:math';
import '../models/glucose_reading.dart';

/// Simulated IoT glucometer.
///
/// This is the software stand-in for a real Bluetooth-enabled glucose
/// meter. It generates a clinically plausible reading within a chosen
/// scenario band rather than a fully random number, and tags every
/// reading with source = "simulated_glucometer" so the app never
/// implies a real device is connected.
///
/// To later support real hardware, replace only this class's
/// `generateReading` implementation with a BLE read — the rest of the
/// app (Firestore schema, dashboard, history) does not need to change.
enum GlucoseScenario { normal, elevated, high }

class GlucoseSimulator {
  static const String deviceId = 'SIM-GLUCO-001';
  static const String source = 'simulated_glucometer';

  final Random _random = Random();

  /// Plausible ranges (mg/dL) per scenario. Fasting/before-meal ranges
  /// are used as the base; after-meal/random readings run a bit higher.
  final Map<GlucoseScenario, List<int>> _ranges = {
    GlucoseScenario.normal: [80, 125],
    GlucoseScenario.elevated: [140, 180],
    GlucoseScenario.high: [200, 260],
  };

  /// Generates one plausible reading. [measurementType] should be one
  /// of: "Fasting", "Before Meal", "After Meal", "Random".
  GlucoseReading generateReading({
    required String measurementType,
    GlucoseScenario scenario = GlucoseScenario.normal,
  }) {
    final range = _ranges[scenario]!;
    final value = (range[0] + _random.nextInt(range[1] - range[0] + 1)).toDouble();

    return GlucoseReading(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      value: value,
      measurementType: measurementType,
      timestamp: DateTime.now(),
      source: source,
    );
  }
}
