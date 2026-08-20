import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/glucose_reading.dart';

/// Dashboard card showing the latest blood glucose reading.
/// Pure UI — no Firestore calls happen inside this widget.
class GlucoseCard extends StatelessWidget {
  final GlucoseReading? latest;
  final VoidCallback onUpdate;

  const GlucoseCard({super.key, required this.latest, required this.onUpdate});

  Color _statusColor(String status) {
    switch (status) {
      case 'Low':
      case 'High':
        return Colors.red;
      case 'Elevated':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReading = latest != null;
    final statusColor =
        hasReading ? _statusColor(latest!.status) : Colors.grey;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text('🩸', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('BLOOD GLUCOSE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 12),
            if (hasReading) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${latest!.value.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('mg/dL', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(latest!.status,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${latest!.measurementType} · ${DateFormat('MMM d, h:mm a').format(latest!.timestamp)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ] else
              const Text('No readings yet', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onUpdate,
                child: const Text('Update My Glucose'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
