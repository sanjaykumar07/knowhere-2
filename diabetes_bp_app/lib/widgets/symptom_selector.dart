import 'package:flutter/material.dart';
import '../models/symptom_log.dart';

/// "How are you feeling?" buttons + multi-select symptom chips.
/// No text input anywhere — everything is a tap.
class SymptomSelector extends StatelessWidget {
  final String? selectedFeeling;
  final Set<String> selectedSymptoms;
  final ValueChanged<String> onFeelingSelected;
  final ValueChanged<String> onSymptomToggled;
  final VoidCallback onSave;

  const SymptomSelector({
    super.key,
    required this.selectedFeeling,
    required this.selectedSymptoms,
    required this.onFeelingSelected,
    required this.onSymptomToggled,
    required this.onSave,
  });

  Widget _feelingButton(String label, String emoji) {
    final selected = selectedFeeling == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => onFeelingSelected(label),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.blue.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? Colors.blue : Colors.transparent, width: 1.5),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How are you feeling?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                _feelingButton('Good', '😊'),
                _feelingButton('Okay', '😐'),
                _feelingButton('Not feeling well', '😟'),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Any symptoms?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kSymptomOptions.map((s) {
                final selected = selectedSymptoms.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) => onSymptomToggled(s),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedFeeling == null ? null : onSave,
                child: const Text('Save Check-In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
