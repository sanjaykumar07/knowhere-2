import 'package:flutter/material.dart';

/// Central design tokens for CareSync.
///
/// Keeps the visual identity (brand blue, card shape, status colours) in one
/// place so the UI stays consistent and duplicated styling can be removed.
///
/// Note: reading-status *thresholds* still live in the model getters
/// ([GlucoseReading.status] / [BPReading.status]); this file only maps the
/// resulting status *string* to a colour used across cards, history lists and
/// the status pill.
class AppStyle {
  AppStyle._();

  /// Brand blue — also the app's [ColorScheme] seed in main.dart.
  static const Color brandBlue = Color(0xFF2563EB);

  /// Clean, light app background.
  static const Color scaffoldBackground = Color(0xFFF6F7F9);

  // Corner radii.
  static const double cardRadius = 16;
  static const double pillRadius = 8;

  // Spacing scale.
  static const double gap = 16;
  static const double gapSmall = 8;

  /// Maps a reading status string to its colour. "Low" and "High" are both
  /// out-of-range → red; "Elevated" → orange; "Normal" → green; anything
  /// else (including null / "no reading") → grey.
  static Color statusColor(String? status) {
    switch (status) {
      case 'Low':
      case 'High':
        return Colors.red;
      case 'Elevated':
        return Colors.orange;
      case 'Normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Chart palette — tied to the identity rather than raw Material colours.
  static const Color glucoseLine = brandBlue;
  static const Color systolicLine = Colors.red;
  static const Color diastolicLine = Colors.deepOrange;

  // Medication "Taken" chip.
  static const Color takenChipBackground = Color(0xFFDFF5E1);
  static const Color takenChipForeground = Colors.green;

  // Medication "Not taken" chip.
  static const Color notTakenChipBackground = Color(0xFFFDE7E7);
  static const Color notTakenChipForeground = Color(0xFFD32F2F);

  /// Shared card shape (radius [cardRadius]).
  static RoundedRectangleBorder get cardShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius));
}
