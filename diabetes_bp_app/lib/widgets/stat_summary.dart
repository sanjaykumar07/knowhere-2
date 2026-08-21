import 'package:flutter/material.dart';
import '../theme/app_style.dart';

/// One labelled statistic, e.g. label "Average", value "128 mg/dL".
class StatItem {
  final String label;
  final String value;

  /// Optional accent for the value text (e.g. status colour for "Latest").
  final Color? valueColor;

  const StatItem({required this.label, required this.value, this.valueColor});
}

/// A compact, overflow-safe grid of [StatItem] tiles.
///
/// Uses [Wrap] so the tiles reflow instead of overflowing on narrow phones or
/// at large text scales.
class StatSummary extends StatelessWidget {
  final List<StatItem> items;

  const StatSummary({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppStyle.gapSmall,
      runSpacing: AppStyle.gapSmall,
      children: items.map((item) => _StatTile(item: item)).toList(),
    );
  }
}

class _StatTile extends StatelessWidget {
  final StatItem item;

  const _StatTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyle.cardRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: item.valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
