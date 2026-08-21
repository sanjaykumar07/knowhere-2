import 'package:flutter/material.dart';
import '../services/trend_analysis_service.dart';
import '../theme/app_style.dart';

/// Displays a rule-based [TrendSummary] as a soft banner: a direction icon,
/// the informational insight sentence, and a subtle non-diagnostic disclaimer.
///
/// The tint is intentionally neutral (brand blue / grey) — the arrow shape
/// conveys direction without colour-coding a value as "good" or "bad", which
/// would imply a medical judgement the app must not make.
class InsightBanner extends StatelessWidget {
  final TrendSummary summary;

  /// Hide the disclaimer line where the screen already shows it once.
  final bool showDisclaimer;

  const InsightBanner({
    super.key,
    required this.summary,
    this.showDisclaimer = true,
  });

  IconData get _icon {
    switch (summary.direction) {
      case TrendDirection.increasing:
        return Icons.trending_up;
      case TrendDirection.decreasing:
        return Icons.trending_down;
      case TrendDirection.stable:
        return Icons.trending_flat;
      case TrendDirection.insufficientData:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tint = summary.direction == TrendDirection.insufficientData
        ? Colors.grey
        : AppStyle.brandBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppStyle.cardRadius),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: tint, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.insight,
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
                if (showDisclaimer) ...[
                  const SizedBox(height: 6),
                  const Text(
                    TrendAnalysisService.kDisclaimer,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
