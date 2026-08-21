import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/symptom_log.dart';
import '../theme/app_style.dart';

/// Whether a medication has been logged for the current session, and how.
/// [none] shows the Taken / Not Taken buttons; [taken] and [notTaken] lock
/// the card to a status chip.
enum MedDoseStatus { none, taken, notTaken }

/// One row in the medication list with direct "Taken" / "Not Taken" actions
/// and an overflow menu to remove the medication. Choosing "Not Taken" asks
/// for a predefined reason via [onNotTaken] — no free-text field. Once either
/// action is logged the buttons are replaced by a status chip.
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final MedDoseStatus statusToday;
  final ValueChanged<bool> onTaken; // true = mark taken
  final ValueChanged<String> onNotTaken; // passes chosen reason
  final VoidCallback onRemove;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.statusToday,
    required this.onTaken,
    required this.onNotTaken,
    required this.onRemove,
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
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medication.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${medication.dose} · ${medication.time}'
                        '${medication.instructions.isNotEmpty ? " · ${medication.instructions}" : ""}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More',
                  onSelected: (value) {
                    if (value == 'remove') onRemove();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _actionArea(context),
          ],
        ),
      ),
    );
  }

  Widget _actionArea(BuildContext context) {
    switch (statusToday) {
      case MedDoseStatus.taken:
        return const Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            label: Text('✓ Taken'),
            backgroundColor: AppStyle.takenChipBackground,
            labelStyle: TextStyle(color: AppStyle.takenChipForeground),
          ),
        );
      case MedDoseStatus.notTaken:
        return const Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            label: Text('✗ Not taken'),
            backgroundColor: AppStyle.notTakenChipBackground,
            labelStyle: TextStyle(color: AppStyle.notTakenChipForeground),
          ),
        );
      case MedDoseStatus.none:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => onTaken(true),
                child: const Text('Taken'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showNotTakenSheet(context),
                child: const Text('Not Taken'),
              ),
            ),
          ],
        );
    }
  }
}
