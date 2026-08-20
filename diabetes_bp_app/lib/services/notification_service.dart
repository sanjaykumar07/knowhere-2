import '../models/glucose_reading.dart';
import '../models/bp_reading.dart';

/// Evaluates readings against general prototype target ranges and
/// produces an in-app alert message when attention is needed.
///
/// Important: this only flags that a reading is outside a configured
/// range — it never diagnoses the patient or claims to be medical
/// advice. Wording always points the patient back to their
/// healthcare provider.
class HealthAlert {
  final String title;
  final String message;
  final AlertSeverity severity;

  HealthAlert({
    required this.title,
    required this.message,
    required this.severity,
  });
}

enum AlertSeverity { info, warning, critical }

class NotificationService {
  HealthAlert? checkGlucose(GlucoseReading reading) {
    switch (reading.status) {
      case 'Low':
        return HealthAlert(
          title: '⚠️ Reading requires attention',
          message:
              'Your latest blood glucose reading is below your configured '
              'target range. Please follow your healthcare provider\'s '
              'instructions.',
          severity: AlertSeverity.critical,
        );
      case 'High':
        return HealthAlert(
          title: '⚠️ Reading requires attention',
          message:
              'Your latest blood glucose reading is above your configured '
              'target range. Please follow your healthcare provider\'s '
              'instructions.',
          severity: AlertSeverity.critical,
        );
      case 'Elevated':
        return HealthAlert(
          title: 'Reading slightly outside target',
          message:
              'Your latest blood glucose reading is a little higher than '
              'your usual target. Keep an eye on it and log how you feel.',
          severity: AlertSeverity.warning,
        );
      default:
        return null;
    }
  }

  HealthAlert? checkBP(BPReading reading) {
    switch (reading.status) {
      case 'Low':
        return HealthAlert(
          title: '⚠️ Reading requires attention',
          message:
              'Your latest blood pressure reading is below your configured '
              'target range. Please follow your healthcare provider\'s '
              'instructions.',
          severity: AlertSeverity.critical,
        );
      case 'High':
        return HealthAlert(
          title: '⚠️ Reading requires attention',
          message:
              'Your latest blood pressure reading is outside your '
              'configured target range. Please follow your healthcare '
              'provider\'s instructions.',
          severity: AlertSeverity.critical,
        );
      case 'Elevated':
        return HealthAlert(
          title: 'Reading slightly outside target',
          message:
              'Your latest blood pressure reading is a little higher than '
              'your usual target. Keep an eye on it and log how you feel.',
          severity: AlertSeverity.warning,
        );
      default:
        return null;
    }
  }
}
