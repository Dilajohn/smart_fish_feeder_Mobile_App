import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Analytics — matches fish_feeder_extra_screens.html "Analytics" checkpoint.
/// This week summary: total feeds, feed used, on-time rate, manual feeds + daily feed chart.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _range = 'Week'; // Week / Month / All time

  // Daily feed grams (matches checkpoint values)
  static const _dailyGrams = {
    'Mon': 45.0,
    'Tue': 30.0,
    'Wed': 45.0,
    'Thu': 30.0,
    'Fri': 45.0,
    'Sat': 54.0,
    'Sun': 54.0,
  };

  static const _stats = {
    'Total feeds': '21',
    'Feed used': '318g',
    'On-time rate': '95%',
    'Manual feeds': '3',
  };

  @override
  Widget build(BuildContext context) {
    final maxG = _dailyGrams.values.reduce((a, b) => a > b ? a : b);
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FEEDING ANALYTICS',
                style: TextStyle(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            Text('This week',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text('Jun 10 – Jun 16',
                  style: TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Range segment
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: ['Week', 'Month', 'All time'].map((r) {
                  final selected = _range == r;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _range = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          r,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.textMedium,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: _stats.entries.map((e) => _StatTile(label: e.key, value: e.value)).toList(),
            ),

            const SizedBox(height: 18),

            // Daily feed bar chart
            const SectionHeader(label: 'Daily feed (grams)'),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: _dailyGrams.entries.map((e) {
                  final pct = (e.value / maxG).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(e.key,
                              style: const TextStyle(color: AppColors.textMedium, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 38,
                          child: Text('${e.value.toStringAsFixed(0)}g',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // Insights
            const SectionHeader(label: 'Insights'),
            const SizedBox(height: 8),
            const AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _InsightRow(label: 'Refill estimate', value: '~6 days', color: AppColors.warning),
                  Divider(height: 1),
                  _InsightRow(label: 'Offline events', value: '2 this week', color: AppColors.textMedium),
                  Divider(height: 1),
                  _InsightRow(label: 'Avg per feed', value: '15g', color: AppColors.textMedium),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMedium, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InsightRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          Text(value,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}