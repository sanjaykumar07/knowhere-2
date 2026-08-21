import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/bp_simulator.dart';
import '../../models/bp_reading.dart';

/// Screen that mimics connecting to a simulated IoT blood-pressure
/// monitor, generating a reading, and saving it to Firestore.
class BPScreen extends StatefulWidget {
  const BPScreen({super.key});

  @override
  State<BPScreen> createState() => _BPScreenState();
}

class _BPScreenState extends State<BPScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _simulator = BPSimulator();

  BPScenario _scenario = BPScenario.normal;
  BPReading? _generatedReading;
  bool _saving = false;

  void _generate() {
    setState(() {
      _generatedReading = _simulator.generateReading(scenario: _scenario);
    });
  }

  Future<void> _save() async {
    if (_generatedReading == null) return;
    setState(() => _saving = true);
    try {
      await _firestore.saveBPReading(_auth.currentUser!.uid, _generatedReading!);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save reading. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulated BP Monitor')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.red.withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SIMULATED BP MONITOR',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    SizedBox(height: 8),
                    Text('Device\n${BPSimulator.deviceId}'),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Status  '),
                        Text('🟢 Connected', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'This is prototype/simulated data — no real medical device is connected.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<BPScenario>(
              initialValue: _scenario,
              decoration: const InputDecoration(labelText: 'Simulation scenario', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: BPScenario.normal, child: Text('Normal')),
                DropdownMenuItem(value: BPScenario.elevated, child: Text('Elevated')),
                DropdownMenuItem(value: BPScenario.high, child: Text('High')),
              ],
              onChanged: (v) => setState(() => _scenario = v!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generate,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Generate Reading'),
            ),
            const SizedBox(height: 24),
            if (_generatedReading != null) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('${_generatedReading!.systolic} / ${_generatedReading!.diastolic} mmHg',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Pulse ${_generatedReading!.pulse} bpm', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(DateFormat('h:mm a').format(_generatedReading!.timestamp)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Reading'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
