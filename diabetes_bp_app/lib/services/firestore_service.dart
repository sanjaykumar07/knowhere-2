import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/glucose_reading.dart';
import '../models/bp_reading.dart';
import '../models/medication.dart';
import '../models/symptom_log.dart';

/// Single place where all Cloud Firestore reads/writes happen.
/// UI widgets never talk to Firestore directly — they go through this
/// service, keeping database logic out of the widget tree.
///
/// Structure:
/// users/{uid}                                -> profile fields
/// users/{uid}/medications/{medicationID}
/// users/{uid}/glucoseReadings/{readingID}
/// users/{uid}/bpReadings/{readingID}
/// users/{uid}/medicationLogs/{logID}
/// users/{uid}/symptomLogs/{logID}
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  // ---------------- Profile ----------------

  Future<void> createUserProfile(UserModel user) {
    return _userDoc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromMap(snap.data()!);
  }

  Stream<UserModel?> streamUserProfile(String uid) {
    return _userDoc(uid).snapshots().map(
        (snap) => snap.exists ? UserModel.fromMap(snap.data()!) : null);
  }

  // ---------------- Medications ----------------

  Future<void> addMedication(String uid, Medication med) {
    return _userDoc(uid).collection('medications').doc(med.id).set(med.toMap());
  }

  Stream<List<Medication>> streamMedications(String uid) {
    return _userDoc(uid).collection('medications').snapshots().map((snap) =>
        snap.docs.map((d) => Medication.fromMap(d.id, d.data())).toList());
  }

  Future<void> logMedicationStatus(String uid, MedicationLog log) {
    return _userDoc(uid)
        .collection('medicationLogs')
        .doc(log.id)
        .set(log.toMap());
  }

  Stream<List<MedicationLog>> streamMedicationLogs(String uid, {int limitDays = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: limitDays));
    return _userDoc(uid)
        .collection('medicationLogs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MedicationLog.fromMap(d.id, d.data())).toList());
  }

  // ---------------- Glucose readings ----------------

  Future<void> saveGlucoseReading(String uid, GlucoseReading reading) {
    return _userDoc(uid)
        .collection('glucoseReadings')
        .doc(reading.id)
        .set(reading.toMap());
  }

  Stream<List<GlucoseReading>> streamGlucoseHistory(String uid, {int limit = 30}) {
    return _userDoc(uid)
        .collection('glucoseReadings')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GlucoseReading.fromMap(d.id, d.data())).toList());
  }

  // ---------------- BP readings ----------------

  Future<void> saveBPReading(String uid, BPReading reading) {
    return _userDoc(uid)
        .collection('bpReadings')
        .doc(reading.id)
        .set(reading.toMap());
  }

  Stream<List<BPReading>> streamBPHistory(String uid, {int limit = 30}) {
    return _userDoc(uid)
        .collection('bpReadings')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BPReading.fromMap(d.id, d.data())).toList());
  }

  // ---------------- Symptom logs ----------------

  Future<void> saveSymptomLog(String uid, SymptomLog log) {
    return _userDoc(uid).collection('symptomLogs').doc(log.id).set(log.toMap());
  }

  Stream<List<SymptomLog>> streamSymptomLogs(String uid, {int limit = 30}) {
    return _userDoc(uid)
        .collection('symptomLogs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SymptomLog.fromMap(d.id, d.data())).toList());
  }

  // ---------------- Adherence calculation ----------------

  /// % of medication logs in the last 7 days marked "Taken".
  double calculateAdherence(List<MedicationLog> logs) {
    if (logs.isEmpty) return 0;
    final taken = logs.where((l) => l.status == 'Taken').length;
    return (taken / logs.length) * 100;
  }
}
