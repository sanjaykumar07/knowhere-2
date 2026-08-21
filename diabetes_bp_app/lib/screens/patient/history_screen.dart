import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/trend_analysis_service.dart';
import '../../models/glucose_reading.dart';
import '../../models/bp_reading.dart';
import '../../theme/app_style.dart';
import '../../widgets/health_chart.dart';
import '../../widgets/insight_banner.dart';
import '../../widgets/period_selector.dart';
import '../../widgets/stat_summary.dart';

/// History & Trends: separate Glucose and Blood Pressure tabs, each showing a
/// rule-based insight, summary stats, a trend chart and the recent readings.
/// A shared 7/30-day selector filters both tabs.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _trend = TrendAnalysisService();
  late final TabController _tabController;

  int _periodDays = 7;

  String get _uid => _auth.currentUser!.uid;
  DateTime get _since => DateTime.now().subtract(Duration(days: _periodDays));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Text('Period',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                PeriodSelector(
                  selectedDays: _periodDays,
                  onChanged: (days) => setState(() => _periodDays = days),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _glucoseTab(),
                _bpTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Glucose ----------------

  Widget _glucoseTab() {
    return StreamBuilder<List<GlucoseReading>>(
      stream: _firestore.streamGlucoseHistory(_uid, since: _since, limit: 200),
      builder: (context, snap) {
        if (snap.hasError) return _errorState();
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final readings = snap.data!; // newest first
        if (readings.isEmpty) return _emptyState('glucose readings');

        final oldestFirst = readings.reversed.toList();
        final summary = _trend.analyzeGlucose(readings);
        final latest = readings.first;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InsightBanner(summary: summary),
            const SizedBox(height: AppStyle.gap),
            StatSummary(items: [
              StatItem(
                label: 'Latest',
                value: latest.value.toStringAsFixed(0),
                valueColor: AppStyle.statusColor(latest.status),
              ),
              StatItem(
                label: 'Average',
                value: summary.average!.toStringAsFixed(0),
              ),
              StatItem(
                label: 'Range',
                value:
                    '${summary.min!.toStringAsFixed(0)}–${summary.max!.toStringAsFixed(0)}',
              ),
              StatItem(label: 'Trend', value: summary.directionLabel),
            ]),
            const SizedBox(height: AppStyle.gap),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: HealthChart(
                  primarySeries: oldestFirst.map((r) => r.value).toList(),
                  timestamps: oldestFirst.map((r) => r.timestamp).toList(),
                  primaryColor: AppStyle.glucoseLine,
                ),
              ),
            ),
            const SizedBox(height: AppStyle.gap),
            const Text('Recent readings',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...readings.map((r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('🩸', style: TextStyle(fontSize: 20)),
                  title: Text(
                      '${r.value.toStringAsFixed(0)} mg/dL — ${r.measurementType}'),
                  subtitle: Text(
                      DateFormat('EEE, MMM d · h:mm a').format(r.timestamp)),
                  trailing: Text(r.status,
                      style: TextStyle(
                          color: AppStyle.statusColor(r.status),
                          fontWeight: FontWeight.w600)),
                )),
          ],
        );
      },
    );
  }

  // ---------------- Blood pressure ----------------

  Widget _bpTab() {
    return StreamBuilder<List<BPReading>>(
      stream: _firestore.streamBPHistory(_uid, since: _since, limit: 200),
      builder: (context, snap) {
        if (snap.hasError) return _errorState();
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final readings = snap.data!; // newest first
        if (readings.isEmpty) return _emptyState('blood pressure readings');

        final oldestFirst = readings.reversed.toList();
        final sys = _trend.analyzeBpSystolic(readings);
        final dia = _trend.analyzeBpDiastolic(readings);
        final latest = readings.first;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InsightBanner(summary: sys),
            const SizedBox(height: AppStyle.gap),
            StatSummary(items: [
              StatItem(
                label: 'Latest',
                value: '${latest.systolic}/${latest.diastolic}',
                valueColor: AppStyle.statusColor(latest.status),
              ),
              StatItem(
                label: 'Avg Sys',
                value: sys.average!.toStringAsFixed(0),
              ),
              StatItem(
                label: 'Avg Dia',
                value: dia.average!.toStringAsFixed(0),
              ),
              StatItem(label: 'Trend', value: sys.directionLabel),
            ]),
            const SizedBox(height: AppStyle.gap),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    HealthChart(
                      primarySeries:
                          oldestFirst.map((r) => r.systolic.toDouble()).toList(),
                      secondarySeries: oldestFirst
                          .map((r) => r.diastolic.toDouble())
                          .toList(),
                      timestamps:
                          oldestFirst.map((r) => r.timestamp).toList(),
                      primaryColor: AppStyle.systolicLine,
                      secondaryColor: AppStyle.diastolicLine,
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(
                            color: AppStyle.systolicLine, label: 'Systolic'),
                        SizedBox(width: 16),
                        _LegendDot(
                            color: AppStyle.diastolicLine, label: 'Diastolic'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppStyle.gap),
            const Text('Recent readings',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...readings.map((r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('❤️', style: TextStyle(fontSize: 20)),
                  title: Text(
                      '${r.systolic}/${r.diastolic} mmHg · Pulse ${r.pulse}'),
                  subtitle: Text(
                      DateFormat('EEE, MMM d · h:mm a').format(r.timestamp)),
                  trailing: Text(r.status,
                      style: TextStyle(
                          color: AppStyle.statusColor(r.status),
                          fontWeight: FontWeight.w600)),
                )),
          ],
        );
      },
    );
  }

  // ---------------- Shared states ----------------

  Widget _emptyState(String label) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No $label in the last $_periodDays days.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add a reading to start seeing your trend.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "Couldn't load your readings.\nPlease check your connection and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
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
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
