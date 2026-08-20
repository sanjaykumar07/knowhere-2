import 'package:cloud_firestore/cloud_firestore.dart';

/// A single blood pressure reading, stored at
/// users/{uid}/bpReadings/{readingID}
class BPReading {
  final String id;
  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime timestamp;
  final String source; // e.g. "simulated_bp_monitor"

  BPReading({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'timestamp': Timestamp.fromDate(timestamp),
      'source': source,
    };
  }

  factory BPReading.fromMap(String id, Map<String, dynamic> map) {
    return BPReading(
      id: id,
      systolic: (map['systolic'] ?? 0).toInt(),
      diastolic: (map['diastolic'] ?? 0).toInt(),
      pulse: (map['pulse'] ?? 0).toInt(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      source: map['source'] ?? 'simulated_bp_monitor',
    );
  }

  /// General prototype target-range check (not a diagnosis).
  String get status {
    if (systolic < 90 || diastolic < 60) return 'Low';
    if (systolic <= 120 && diastolic <= 80) return 'Normal';
    if (systolic <= 139 || diastolic <= 89) return 'Elevated';
    return 'High';
  }
}
