import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/trend_analysis_service.dart';
import '../../models/user_model.dart';
import '../../models/glucose_reading.dart';
import '../../models/bp_reading.dart';
import '../../models/medication.dart';
import '../../models/symptom_log.dart';
import '../../widgets/glucose_card.dart';
import '../../widgets/bp_card.dart';
import '../../widgets/insight_banner.dart';
import '../../widgets/symptom_selector.dart';
import '../auth/login_screen.dart';
import 'glucose_screen.dart';
import 'bp_screen.dart';
import 'medication_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  /// Switches the parent [MainShell] to another tab (History = 1, Meds = 2).
  /// Null when the dashboard is shown outside the shell, in which case the
  /// medication and history shortcuts fall back to pushing the screens.
  final void Function(int index)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _notifications = NotificationService();
  final _trend = TrendAnalysisService();

  String? _selectedFeeling;
  final Set<String> _selectedSymptoms = {};
  final TextEditingController _otherController = TextEditingController();

  // Id of the most recent reading we've already evaluated for an alert.
  // build() re-runs every time the user switches tabs (this screen lives in
  // MainShell's IndexedStack), so we guard by id to avoid re-popping the same
  // alert dialog on every rebuild. A new reading (new id) alerts once.
  String? _lastAlertedGlucoseId;
  String? _lastAlertedBPId;

  String get _uid => _auth.currentUser!.uid;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  /// Toggle a symptom chip, enforcing that "None" is mutually exclusive with
  /// every real symptom: picking "None" clears the rest, and picking any real
  /// symptom clears "None".
  void _toggleSymptom(String s) {
    setState(() {
      if (s == kNoneSymptom) {
        if (_selectedSymptoms.contains(kNoneSymptom)) {
          _selectedSymptoms.remove(kNoneSymptom);
        } else {
          _selectedSymptoms
            ..clear()
            ..add(kNoneSymptom);
          _otherController.clear();
        }
        return;
      }
      // A real symptom was tapped — "None" can no longer apply.
      _selectedSymptoms.remove(kNoneSymptom);
      if (_selectedSymptoms.contains(s)) {
        _selectedSymptoms.remove(s);
        if (s == kOtherSymptom) _otherController.clear();
      } else {
        _selectedSymptoms.add(s);
      }
    });
  }

  Future<void> _saveCheckIn() async {
    // Fold the free-text entry into the symptom list, replacing the raw
    // "Other" token with what the patient actually typed.
    final symptoms = _selectedSymptoms.toList();
    if (symptoms.remove(kOtherSymptom)) {
      final custom = _otherController.text.trim();
      if (custom.isNotEmpty) symptoms.add(custom);
    }
    const uuid = Uuid();
    final log = SymptomLog(
      id: uuid.v4(),
      feeling: _selectedFeeling!,
      symptoms: symptoms,
      timestamp: DateTime.now(),
    );
    await _firestore.saveSymptomLog(_uid, log);
    if (!mounted) return;
    setState(() {
      _selectedFeeling = null;
      _selectedSymptoms.clear();
      _otherController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in saved')),
    );
  }

  void _maybeShowAlert(HealthAlert? alert) {
    if (alert == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(alert.title),
          content: Text(alert.message),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    });
  }

  /// Jump to the Meds tab in the shell, or push the screen if standalone.
  void _openMeds() {
    if (widget.onNavigate != null) {
      widget.onNavigate!(2);
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const MedicationScreen()));
    }
  }

  /// Jump to the Trends tab in the shell, or push the screen if standalone.
  void _openHistory() {
    if (widget.onNavigate != null) {
      widget.onNavigate!(1);
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _auth.signOut();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _firestore.streamUserProfile(_uid),
        builder: (context, userSnap) {
          final userName = userSnap.data?.name.split(' ').first ?? '';
          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Good ${_greeting()}, $userName',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Glucose card
                StreamBuilder<List<GlucoseReading>>(
                  stream: _firestore.streamGlucoseHistory(_uid, limit: 1),
                  builder: (context, snap) {
                    final latest = (snap.data != null && snap.data!.isNotEmpty) ? snap.data!.first : null;
                    if (latest != null && latest.id != _lastAlertedGlucoseId) {
                      _lastAlertedGlucoseId = latest.id;
                      _maybeShowAlert(_notifications.checkGlucose(latest));
                    }
                    return GlucoseCard(
                      latest: latest,
                      onUpdate: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const GlucoseScreen())),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // BP card
                StreamBuilder<List<BPReading>>(
                  stream: _firestore.streamBPHistory(_uid, limit: 1),
                  builder: (context, snap) {
                    final latest = (snap.data != null && snap.data!.isNotEmpty) ? snap.data!.first : null;
                    if (latest != null && latest.id != _lastAlertedBPId) {
                      _lastAlertedBPId = latest.id;
                      _maybeShowAlert(_notifications.checkBP(latest));
                    }
                    return BPCard(
                      latest: latest,
                      onUpdate: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const BPScreen())),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Rule-based health-trend insight (glucose-led, BP fallback).
                _healthTrendSection(),

                // Medication summary card
                StreamBuilder<List<Medication>>(
                  stream: _firestore.streamMedications(_uid),
                  builder: (context, medSnap) {
                    final meds = medSnap.data ?? [];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const Text('💊', style: TextStyle(fontSize: 22)),
                        title: const Text('MEDICATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(meds.isEmpty
                            ? 'No medications added yet'
                            : '${meds.length} medication${meds.length == 1 ? '' : 's'} scheduled'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openMeds,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Feeling / symptoms
                SymptomSelector(
                  selectedFeeling: _selectedFeeling,
                  selectedSymptoms: _selectedSymptoms,
                  otherController: _otherController,
                  onFeelingSelected: (f) => setState(() => _selectedFeeling = f),
                  onSymptomToggled: _toggleSymptom,
                  onSave: _saveCheckIn,
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _openHistory,
                  icon: const Icon(Icons.show_chart),
                  label: const Text('View History & Trends'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  /// A single "Your health trend" banner. Uses recent glucose when there are
  /// enough readings; otherwise falls back to blood pressure. Never blocks the
  /// dashboard — on loading/error it renders nothing.
  Widget _healthTrendSection() {
    return StreamBuilder<List<GlucoseReading>>(
      stream: _firestore.streamGlucoseHistory(_uid, limit: 30),
      builder: (context, gSnap) {
        if (gSnap.hasError || !gSnap.hasData) return const SizedBox.shrink();
        final glucose = gSnap.data!;
        if (glucose.length >= TrendAnalysisService.kMinReadings) {
          return _wrapInsight(_trend.analyzeGlucose(glucose));
        }
        return StreamBuilder<List<BPReading>>(
          stream: _firestore.streamBPHistory(_uid, limit: 30),
          builder: (context, bSnap) {
            if (bSnap.hasError || !bSnap.hasData) return const SizedBox.shrink();
            final bp = bSnap.data!;
            if (bp.length >= TrendAnalysisService.kMinReadings) {
              return _wrapInsight(_trend.analyzeBpSystolic(bp));
            }
            // Neither metric has enough data yet — gentle glucose prompt.
            return _wrapInsight(_trend.analyzeGlucose(glucose));
          },
        );
      },
    );
  }

  Widget _wrapInsight(TrendSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your health trend',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        InsightBanner(summary: summary),
        const SizedBox(height: 16),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}
