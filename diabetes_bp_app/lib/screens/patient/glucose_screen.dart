import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/glucose_simulator.dart';
import '../../models/glucose_reading.dart';

/// Screen that mimics connecting to a simulated IoT glucometer,
/// generating a reading, and saving it to Firestore.
class GlucoseScreen extends StatefulWidget {
  const GlucoseScreen({super.key});

  @override
  State<GlucoseScreen> createState() => _GlucoseScreenState();
}

class _GlucoseScreenState extends State<GlucoseScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _simulator = GlucoseSimulator();

  String _measurementType = 'Fasting';
  GlucoseScenario _scenario = GlucoseScenario.normal;
  GlucoseReading? _generatedReading;
  bool _saving = false;

  void _generate() {
    setState(() {
      _generatedReading = _simulator.generateReading(
        measurementType: _measurementType,
        scenario: _scenario,
      );
    });
  }

  Future<void> _save() async {
    if (_generatedReading == null) return;
    setState(() => _saving = true);
    await _firestore.saveGlucoseReading(_auth.currentUser!.uid, _generatedReading!);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulated Glucometer')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.red.withOpacity(0.06),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SIMULATED GLUCOMETER',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text('Device\n${GlucoseSimulator.deviceId}'),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Text('Status  '),
                        Text('🟢 Connected', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This is prototype/simulated data — no real medical device is connected.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _measurementType,
              decoration: const InputDecoration(labelText: 'Measurement type', border: OutlineInputBorder()),
              items: ['Fasting', 'Before Meal', 'After Meal', 'Random']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _measurementType = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GlucoseScenario>(
              value: _scenario,
              decoration: const InputDecoration(labelText: 'Simulation scenario', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: GlucoseScenario.normal, child: Text('Normal')),
                DropdownMenuItem(value: GlucoseScenario.elevated, child: Text('Elevated')),
                DropdownMenuItem(value: GlucoseScenario.high, child: Text('High')),
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
                      Text('${_generatedReading!.value.toStringAsFixed(0)} mg/dL',
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(DateFormat('h:mm a').format(_generatedReading!.timestamp)),
                      const SizedBox(height: 4),
                      Text(_generatedReading!.measurementType, style: const TextStyle(color: Colors.grey)),
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
