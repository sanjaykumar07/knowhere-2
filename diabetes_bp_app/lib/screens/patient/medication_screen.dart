import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/medication.dart';
import '../../widgets/medication_card.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();

  String get _uid => _auth.currentUser!.uid;

  // Tracks medication IDs marked "Taken" today (local session state —
  // the log itself, with status/reason/timestamp, is written to
  // Firestore on every action).
  final Set<String> _takenToday = {};

  Future<void> _markTaken(Medication med) async {
    const uuid = Uuid();
    await _firestore.logMedicationStatus(
      _uid,
      MedicationLog(
        id: uuid.v4(),
        medicationId: med.id,
        status: 'Taken',
        timestamp: DateTime.now(),
      ),
    );
    setState(() => _takenToday.add(med.id));
  }

  Future<void> _markNotTaken(Medication med, String reason) async {
    const uuid = Uuid();
    await _firestore.logMedicationStatus(
      _uid,
      MedicationLog(
        id: uuid.v4(),
        medicationId: med.id,
        status: 'Not Taken',
        reason: reason,
        timestamp: DateTime.now(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged as not taken (${reason.toLowerCase()})')),
    );
  }

  Future<void> _addMedicationDialog() async {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    String frequency = 'Once daily';
    String instructions = 'None';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: doseCtrl, decoration: const InputDecoration(labelText: 'Dose')),
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: ['Once daily', 'Twice daily', 'Three times daily', 'As needed']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => frequency = v!),
                ),
                TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Time (e.g. 8:00 AM)')),
                DropdownButtonFormField<String>(
                  initialValue: instructions,
                  decoration: const InputDecoration(labelText: 'Instructions'),
                  items: ['None', 'Before food', 'After food']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => instructions = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                const uuid = Uuid();
                await _firestore.addMedication(
                  _uid,
                  Medication(
                    id: uuid.v4(),
                    name: nameCtrl.text.trim(),
                    dose: doseCtrl.text.trim(),
                    frequency: frequency,
                    time: timeCtrl.text.trim(),
                    instructions: instructions,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Medications')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedicationDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Medication>>(
        stream: _firestore.streamMedications(_uid),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final meds = snap.data!;
          if (meds.isEmpty) {
            return const Center(child: Text('No medications yet. Tap + to add one.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meds.length,
            itemBuilder: (context, i) {
              final med = meds[i];
              return MedicationCard(
                medication: med,
                takenToday: _takenToday.contains(med.id),
                onTaken: (_) => _markTaken(med),
                onNotTaken: (reason) => _markNotTaken(med, reason),
              );
            },
          );
        },
      ),
    );
  }
}
