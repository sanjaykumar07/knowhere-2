import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/medication.dart';
import '../../theme/app_style.dart';
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

  // Tracks how each medication was logged this session (Taken / Not Taken),
  // so the card locks to a status chip after either action. The log itself
  // (status/reason/timestamp) is written to Firestore on every action.
  final Map<String, MedDoseStatus> _statusToday = {};

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
    setState(() => _statusToday[med.id] = MedDoseStatus.taken);
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
    setState(() => _statusToday[med.id] = MedDoseStatus.notTaken);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged as not taken (${reason.toLowerCase()})')),
    );
  }

  /// Confirms then deletes a medication. Past logs are kept, so adherence
  /// history stays intact.
  Future<void> _confirmRemove(Medication med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${med.name}?'),
        content: const Text(
            "This removes it from your list. Past logs aren't affected."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _firestore.deleteMedication(_uid, med.id);
      if (!mounted) return;
      setState(() => _statusToday.remove(med.id));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove medication. Please try again.')),
      );
    }
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
          if (snap.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  "Couldn't load your medications.\nPlease check your connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final meds = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _adherenceSummary(),
              const SizedBox(height: AppStyle.gap),
              const Text('Your medications',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (meds.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No medications yet. Tap + to add one.',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ...meds.map((med) => MedicationCard(
                      medication: med,
                      statusToday: _statusToday[med.id] ?? MedDoseStatus.none,
                      onTaken: (_) => _markTaken(med),
                      onNotTaken: (reason) => _markNotTaken(med, reason),
                      onRemove: () => _confirmRemove(med),
                    )),
              const SizedBox(height: AppStyle.gap),
              _recentActivity(),
            ],
          );
        },
      ),
    );
  }

  /// Weekly adherence headline, computed from the medication logs of the last
  /// 7 days via the existing [FirestoreService.calculateAdherence].
  Widget _adherenceSummary() {
    return StreamBuilder<List<MedicationLog>>(
      stream: _firestore.streamMedicationLogs(_uid, limitDays: 7),
      builder: (context, snap) {
        final logs = snap.data ?? [];
        final hasLogs = logs.isNotEmpty;
        final adherence = _firestore.calculateAdherence(logs);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ADHERENCE · LAST 7 DAYS',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  hasLogs ? '${adherence.toStringAsFixed(0)}%' : '—',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                Text(
                  hasLogs ? 'of logged doses marked taken' : 'No doses logged yet',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Recent Taken / Not Taken activity (relocated from the old History tab).
  Widget _recentActivity() {
    return StreamBuilder<List<MedicationLog>>(
      stream: _firestore.streamMedicationLogs(_uid, limitDays: 7),
      builder: (context, snap) {
        final logs = snap.data ?? [];
        if (logs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent activity',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...logs.map((log) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    log.status == 'Taken' ? Icons.check_circle : Icons.cancel,
                    color: log.status == 'Taken' ? Colors.green : Colors.red,
                  ),
                  title: Text(log.status +
                      (log.reason != null ? ' — ${log.reason}' : '')),
                  subtitle: Text(
                      DateFormat('EEE, MMM d · h:mm a').format(log.timestamp)),
                )),
          ],
        );
      },
    );
  }
}
