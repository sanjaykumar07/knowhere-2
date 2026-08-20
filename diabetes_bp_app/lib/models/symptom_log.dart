import 'package:cloud_firestore/cloud_firestore.dart';

/// A daily feeling + symptom check-in, stored at
/// users/{uid}/symptomLogs/{logID}
class SymptomLog {
  final String id;
  final String feeling; // "Good", "Okay", "Not feeling well"
  final List<String> symptoms; // e.g. ["Headache", "Fatigue"]
  final DateTime timestamp;

  SymptomLog({
    required this.id,
    required this.feeling,
    required this.symptoms,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'feeling': feeling,
      'symptoms': symptoms,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory SymptomLog.fromMap(String id, Map<String, dynamic> map) {
    return SymptomLog(
      id: id,
      feeling: map['feeling'] ?? 'Okay',
      symptoms: List<String>.from(map['symptoms'] ?? []),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

/// Fixed, tappable symptom options — no free text required.
const List<String> kSymptomOptions = [
  'Headache',
  'Dizziness',
  'Blurred vision',
  'Excessive thirst',
  'Frequent urination',
  'Fatigue',
  'Nausea',
  'Shortness of breath',
  'None',
];

const List<String> kNotTakenReasons = [
  'Forgot',
  'Ran out of medication',
  'Side effects',
  'Felt better',
  'Other',
];
