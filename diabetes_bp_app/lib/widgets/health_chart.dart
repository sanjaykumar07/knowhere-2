import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Reusable line chart for glucose/BP history trends.
/// Pass in one or two series (e.g. systolic + diastolic).
class HealthChart extends StatelessWidget {
  final List<double> primarySeries; // oldest -> newest
  final List<double>? secondarySeries;
  final Color primaryColor;
  final Color secondaryColor;
  final double minY;
  final double maxY;

  const HealthChart({
    super.key,
    required this.primarySeries,
    this.secondarySeries,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.deepOrange,
    required this.minY,
    required this.maxY,
  });

  LineChartBarData _line(List<double> data, Color color) {
    return LineChartBarData(
      spots: [for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i])],
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
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

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
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
