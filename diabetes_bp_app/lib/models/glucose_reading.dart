import 'package:cloud_firestore/cloud_firestore.dart';

/// A single blood glucose reading, stored at
/// users/{uid}/glucoseReadings/{readingID}
class GlucoseReading {
  final String id;
  final double value; // mg/dL
  final String measurementType; // Fasting, Before Meal, After Meal, Random
  final DateTime timestamp;
  final String source; // e.g. "simulated_glucometer"

  GlucoseReading({
    required this.id,
    required this.value,
    required this.measurementType,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'measurementType': measurementType,
      'timestamp': Timestamp.fromDate(timestamp),
      'source': source,
    };
  }

  factory GlucoseReading.fromMap(String id, Map<String, dynamic> map) {
    return GlucoseReading(
      id: id,
      value: (map['value'] ?? 0).toDouble(),
      measurementType: map['measurementType'] ?? 'Random',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      source: map['source'] ?? 'simulated_glucometer',
    );
  }

  /// Simple clinical categorisation for UI colour-coding / alerts.
  /// This is NOT a diagnosis — just a threshold check against general
  /// prototype target ranges.
  String get status {
    if (measurementType == 'Fasting' || measurementType == 'Before Meal') {
      if (value < 70) return 'Low';
      if (value <= 130) return 'Normal';
      if (value <= 180) return 'Elevated';
      return 'High';
    } else {
      // After meal / random
      if (value < 70) return 'Low';
      if (value <= 180) return 'Normal';
      if (value <= 250) return 'Elevated';
      return 'High';
    }
  }
}
