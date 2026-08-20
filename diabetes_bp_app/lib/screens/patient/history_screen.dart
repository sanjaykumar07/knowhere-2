import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/glucose_reading.dart';
import '../../models/bp_reading.dart';
import '../../models/medication.dart';
import '../../widgets/health_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  late final TabController _tabController;

  String get _uid => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Trends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Glucose'),
            Tab(text: 'Blood Pressure'),
            Tab(text: 'Adherence'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _glucoseTab(),
          _bpTab(),
          _adherenceTab(),
        ],
      ),
    );
  }

  Widget _glucoseTab() {
    return StreamBuilder<List<GlucoseReading>>(
      stream: _firestore.streamGlucoseHistory(_uid),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final readings = snap.data!; // newest first
        final oldestFirst = readings.reversed.toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: HealthChart(
                  primarySeries: oldestFirst.map((r) => r.value).toList(),
                  primaryColor: Colors.blue,
                  minY: 40,
                  maxY: 300,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...readings.map((r) => ListTile(
                  leading: const Text('🩸'),
                  title: Text('${r.value.toStringAsFixed(0)} mg/dL — ${r.measurementType}'),
                  subtitle: Text(DateFormat('EEE, MMM d · h:mm a').format(r.timestamp)),
                  trailing: Text(r.status,
                      style: TextStyle(
                          color: r.status == 'Normal' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600)),
                )),
            if (readings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('No glucose readings yet', style: TextStyle(color: Colors.grey))),
              ),
          ],
        );
      },
    );
  }

  Widget _bpTab() {
    return StreamBuilder<List<BPReading>>(
      stream: _firestore.streamBPHistory(_uid),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final readings = snap.data!;
        final oldestFirst = readings.reversed.toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    HealthChart(
                      primarySeries: oldestFirst.map((r) => r.systolic.toDouble()).toList(),
                      secondarySeries: oldestFirst.map((r) => r.diastolic.toDouble()).toList(),
                      primaryColor: Colors.red,
                      secondaryColor: Colors.deepOrange,
                      minY: 40,
                      maxY: 200,
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(color: Colors.red, label: 'Systolic'),
                        SizedBox(width: 16),
                        _LegendDot(color: Colors.deepOrange, label: 'Diastolic'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...readings.map((r) => ListTile(
                  leading: const Text('❤️'),
                  title: Text('${r.systolic}/${r.diastolic} mmHg · Pulse ${r.pulse}'),
                  subtitle: Text(DateFormat('EEE, MMM d · h:mm a').format(r.timestamp)),
                  trailing: Text(r.status,
                      style: TextStyle(
                          color: r.status == 'Normal' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600)),
                )),
            if (readings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('No BP readings yet', style: TextStyle(color: Colors.grey))),
              ),
          ],
        );
      },
    );
  }

  Widget _adherenceTab() {
    return StreamBuilder<List<MedicationLog>>(
      stream: _firestore.streamMedicationLogs(_uid, limitDays: 7),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final logs = snap.data!;
        final adherence = _firestore.calculateAdherence(logs);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('${adherence.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 4),
                    const Text('taken this week', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Recent activity', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...logs.map((log) => ListTile(
                  leading: Icon(
                    log.status == 'Taken' ? Icons.check_circle : Icons.cancel,
                    color: log.status == 'Taken' ? Colors.green : Colors.red,
                  ),
                  title: Text(log.status + (log.reason != null ? ' — ${log.reason}' : '')),
                  subtitle: Text(DateFormat('EEE, MMM d · h:mm a').format(log.timestamp)),
                )),
            if (logs.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('No medication logs yet', style: TextStyle(color: Colors.grey))),
              ),
          ],
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
