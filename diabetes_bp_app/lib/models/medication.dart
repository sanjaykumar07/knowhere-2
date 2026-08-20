import 'package:cloud_firestore/cloud_firestore.dart';

/// A prescribed medication, stored at
/// users/{uid}/medications/{medicationID}
class Medication {
  final String id;
  final String name;
  final String dose;
  final String frequency; // e.g. "Once daily", "Twice daily"
  final String time; // e.g. "08:00 AM"
  final String instructions; // e.g. "Before food", "After food", ""

  Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.frequency,
    required this.time,
    required this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dose': dose,
      'frequency': frequency,
      'time': time,
      'instructions': instructions,
    };
  }

  factory Medication.fromMap(String id, Map<String, dynamic> map) {
    return Medication(
      id: id,
      name: map['name'] ?? '',
      dose: map['dose'] ?? '',
      frequency: map['frequency'] ?? '',
      time: map['time'] ?? '',
      instructions: map['instructions'] ?? '',
    );
  }
}

/// A log entry recording whether a dose was taken.
/// Stored at users/{uid}/medicationLogs/{logID}
class MedicationLog {
  final String id;
  final String medicationId;
  final String status; // "Taken" or "Not Taken"
  final String? reason; // Forgot, Ran out, Side effects, Felt better, Other
  final DateTime timestamp;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.status,
    this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicationID': medicationId,
      'status': status,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory MedicationLog.fromMap(String id, Map<String, dynamic> map) {
    return MedicationLog(
      id: id,
      medicationId: map['medicationID'] ?? '',
      status: map['status'] ?? 'Not Taken',
      reason: map['reason'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
