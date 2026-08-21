import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/symptom_log.dart';

/// One row in the medication list showing Taken / Not Taken state.
/// When "Not Taken" is chosen it asks for a predefined reason via
/// [onNotTaken] — no free-text field.
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final bool takenToday;
  final ValueChanged<bool> onTaken; // true = mark taken
  final ValueChanged<String> onNotTaken; // passes chosen reason

  const MedicationCard({
    super.key,
    required this.medication,
    required this.takenToday,
    required this.onTaken,
    required this.onNotTaken,
  });

  Future<void> _showNotTakenSheet(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Why didn't you take it?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...kNotTakenReasons.map((r) => ListTile(
                    title: Text(r),
                    onTap: () => Navigator.pop(ctx, r),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (reason != null) onNotTaken(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(medication.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${medication.dose} · ${medication.time}'
            '${medication.instructions.isNotEmpty ? " · ${medication.instructions}" : ""}'),
        trailing: takenToday
            ? const Chip(
                label: Text('✓ Taken'),
                backgroundColor: Color(0xFFDFF5E1),
                labelStyle: TextStyle(color: Colors.green),
              )
            : OutlinedButton(
                onPressed: () async {
                  final choice = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(medication.name),
                      content: const Text('Did you take this dose?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Not Taken'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Taken'),
                        ),
                      ],
                    ),
                  );
                  if (choice == true) {
                    onTaken(true);
                  } else if (choice == false && context.mounted) {
                    await _showNotTakenSheet(context);
                  }
                },
                child: const Text('Mark as Taken'),
              ),
      ),
    );
  }
}
