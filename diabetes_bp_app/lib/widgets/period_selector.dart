import 'package:flutter/material.dart';

/// A compact 7-day / 30-day toggle for the History screen.
///
/// Emits the selected number of days via [onChanged]; the parent owns the
/// state and re-queries Firestore with `since: now - selectedDays`.
class PeriodSelector extends StatelessWidget {
  final int selectedDays;
  final ValueChanged<int> onChanged;

  const PeriodSelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: 7, label: Text('7 days')),
        ButtonSegment(value: 30, label: Text('30 days')),
      ],
      selected: {selectedDays},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
