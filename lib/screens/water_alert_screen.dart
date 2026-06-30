import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Water alert — matches fish_feeder_extra_screens.html "Water alert" checkpoint.
/// Live alert view: pH out of range, current readings, auto-actions, recommendation.
class WaterAlertScreen extends StatelessWidget {
  const WaterAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C2D12),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('LIVE ALERT — POND A',
                style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            Text('pH out of range',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Critical alert
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_rounded, color: AppColors.offline, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'pH dropped to 5.8',
                          style: TextStyle(
                            color: AppColors.offline,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Safe range is 6.5–8.5. Feeding paused automatically until resolved.',
                          style: TextStyle(color: AppColors.offline, fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Current readings
            const SectionHeader(label: 'Current readings'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: const [
                _ReadingCard(label: 'pH level', value: '5.8', status: 'Critical', color: AppColors.offline),
                _ReadingCard(label: 'Temperature', value: '24°C', status: 'Normal', color: AppColors.online),
                _ReadingCard(label: 'Dissolved O₂', value: '5.1 mg/L', status: 'Low', color: AppColors.warning),
                _ReadingCard(label: 'Turbidity', value: '28 NTU', status: 'Elevated', color: AppColors.warning),
              ],
            ),

            const SizedBox(height: 18),

            // Auto-actions
            const SectionHeader(label: 'Auto-actions taken'),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: const [
                  _ActionRow(label: 'Feeding paused', value: 'Yes', color: AppColors.offline),
                  Divider(height: 1),
                  _ActionRow(label: 'Alert sent', value: 'Push + SMS', color: AppColors.online),
                  Divider(height: 1),
                  _ActionRow(label: 'Triggered at', value: '9:38 AM', color: AppColors.textMedium),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Recommended action
            const SectionHeader(label: 'Recommended action'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'Add buffer solution to raise pH. Do a 20–30% water change and retest in 1 hour. Resume feeding only when pH is above 6.5.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alert resolved · feeding resumed after pH retest'),
                    backgroundColor: AppColors.online,
                  ),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Resolve & resume feeding'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.offline,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final Color color;
  const _ReadingCard({
    required this.label,
    required this.value,
    required this.status,
    required this.color,
  });

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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color == AppColors.online ? AppColors.textDark : color,
              )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ActionRow({required this.label, required this.value, required this.color});

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