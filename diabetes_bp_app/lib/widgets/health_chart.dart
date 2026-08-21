import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_style.dart';

/// Reusable line chart for glucose/BP history trends.
/// Pass in one or two series (e.g. systolic + diastolic).
///
/// [minY]/[maxY] are optional: when omitted the vertical range is derived from
/// the data with padding. Pass [timestamps] (aligned to [primarySeries],
/// oldest→newest) to label a few points along the X-axis for time context.
class HealthChart extends StatelessWidget {
  final List<double> primarySeries; // oldest -> newest
  final List<double>? secondarySeries;
  final List<DateTime>? timestamps; // aligned to primarySeries
  final Color primaryColor;
  final Color secondaryColor;
  final double? minY;
  final double? maxY;

  const HealthChart({
    super.key,
    required this.primarySeries,
    this.secondarySeries,
    this.timestamps,
    this.primaryColor = AppStyle.brandBlue,
    this.secondaryColor = AppStyle.diastolicLine,
    this.minY,
    this.maxY,
  });

  LineChartBarData _line(List<double> data, Color color) {
    return LineChartBarData(
      spots: [for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i])],
      isCurved: true,
      color: color,
      barWidth: 3,
      // Fewer dots when the series is dense, so points stay readable.
      dotData: FlDotData(show: data.length <= 12),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (primarySeries.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Not enough data yet', style: TextStyle(color: Colors.grey))),
      );
    }

    // Derive a padded vertical range when bounds aren't supplied.
    final allValues = [
      ...primarySeries,
      if (secondarySeries != null) ...secondarySeries!,
    ];
    final dataMin = allValues.reduce(math.min);
    final dataMax = allValues.reduce(math.max);
    final pad = ((dataMax - dataMin) * 0.15).clamp(5.0, 40.0);
    final resolvedMinY = minY ?? math.max(0, dataMin - pad);
    final resolvedMaxY = maxY ?? (dataMax + pad);

    final ts = timestamps;
    final showBottom = ts != null && ts.length == primarySeries.length;
    // Show ~4 labels regardless of series length to avoid clutter.
    final labelStep = primarySeries.length <= 4
        ? 1
        : (primarySeries.length / 4).ceil();
    // Use date labels when the window spans more than ~2 days, else times.
    final spansDays = showBottom &&
        ts.last.difference(ts.first).inHours > 48;
    final formatter = DateFormat(spansDays ? 'M/d' : 'h:mm a');

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: resolvedMinY,
          maxY: resolvedMaxY,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showBottom,
                interval: 1,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.round();
                  if (!showBottom ||
                      idx < 0 ||
                      idx >= ts.length ||
                      idx % labelStep != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      formatter.format(ts[idx]),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            _line(primarySeries, primaryColor),
            if (secondarySeries != null) _line(secondarySeries!, secondaryColor),
          ],
        ),
      ),
    );
  }
}
