import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diabetes_bp_app/services/trend_analysis_service.dart';
import 'package:diabetes_bp_app/widgets/health_chart.dart';
import 'package:diabetes_bp_app/widgets/insight_banner.dart';
import 'package:diabetes_bp_app/widgets/period_selector.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PeriodSelector', () {
    testWidgets('renders both options and reports the tapped value',
        (tester) async {
      int? changed;
      await tester.pumpWidget(_host(PeriodSelector(
        selectedDays: 7,
        onChanged: (days) => changed = days,
      )));

      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);

      await tester.tap(find.text('30 days'));
      await tester.pumpAndSettle();
      expect(changed, 30);
    });
  });

  group('InsightBanner', () {
    const increasing = TrendSummary(
      count: 5,
      latest: 120,
      average: 110,
      min: 100,
      max: 120,
      direction: TrendDirection.increasing,
      percentChange: 10,
      insight: 'Test insight sentence.',
    );

    testWidgets('shows the insight, disclaimer and a direction icon',
        (tester) async {
      await tester.pumpWidget(_host(const InsightBanner(summary: increasing)));

      expect(find.text('Test insight sentence.'), findsOneWidget);
      expect(find.text(TrendAnalysisService.kDisclaimer), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('hides the disclaimer when showDisclaimer is false',
        (tester) async {
      await tester.pumpWidget(_host(
          const InsightBanner(summary: increasing, showDisclaimer: false)));

      expect(find.text('Test insight sentence.'), findsOneWidget);
      expect(find.text(TrendAnalysisService.kDisclaimer), findsNothing);
    });

    testWidgets('uses the info icon when data is insufficient', (tester) async {
      const insufficient = TrendSummary(
        count: 2,
        latest: 100,
        average: 100,
        min: 100,
        max: 100,
        direction: TrendDirection.insufficientData,
        percentChange: null,
        insight: 'Not enough readings yet.',
      );
      await tester.pumpWidget(_host(const InsightBanner(summary: insufficient)));

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('HealthChart', () {
    testWidgets('renders a two-series chart with time labels without error',
        (tester) async {
      final now = DateTime(2026, 1, 1, 8);
      await tester.pumpWidget(_host(HealthChart(
        primarySeries: const [120, 122, 118, 130, 128],
        secondarySeries: const [80, 82, 79, 85, 83],
        timestamps: [
          for (int i = 0; i < 5; i++) now.add(Duration(hours: i * 12)),
        ],
      )));
      await tester.pumpAndSettle();

      expect(find.byType(HealthChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows an empty message when there is no data', (tester) async {
      await tester.pumpWidget(_host(const HealthChart(primarySeries: [])));
      expect(find.text('Not enough data yet'), findsOneWidget);
    });
  });
}
