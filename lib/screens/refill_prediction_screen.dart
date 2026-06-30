import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class RefillPredictionScreen extends StatefulWidget {
  const RefillPredictionScreen({super.key});

  @override
  State<RefillPredictionScreen> createState() => _RefillPredictionScreenState();
}

class _RefillPredictionScreenState extends State<RefillPredictionScreen> {
  bool _reminderSet = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final level = state.hopperLevel;
    final isLow = level < 25;
    final daysLeft = (level / 5.5).floor(); // ~5.5% per day based on 3 feeds

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FOOD MANAGEMENT', style: AppTextStyles.screenLabel),
            const Text('Refill Prediction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusBadge(label: 'Active', color: AppColors.online, bgColor: const Color(0xFFDCFCE7)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ring gauge card
            AppCard(
              child: Column(
                children: [
                  Text('INTERACTIVE FOOD QUANTITY', style: AppTextStyles.screenLabel),
                  const SizedBox(height: 16),
                  _RingGauge(percent: level / 100),
                  const SizedBox(height: 16),
                  Slider(
                    value: level,
                    min: 1,
                    max: 100,
                    activeColor: isLow ? AppColors.offline : AppColors.primary,
                    inactiveColor: const Color(0xFFE2E8F0),
                    onChanged: (v) => state.setHopperLevel(v),
                  ),
                  Text(
                    'Drag slider to simulate hopper level',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Alert if low
            if (isLow)
              AlertBanner.warning('⚠ Food level critically low. Refill immediately to prevent missed feedings.'),

            const SizedBox(height: 14),

            // Prediction stats
            AppCard(
              child: Column(
                children: [
                  const SectionHeader(label: 'Analytics', title: 'Prediction Summary'),
                  const SizedBox(height: 14),
                  InfoRow(label: 'Current hopper level', value: '${level.toStringAsFixed(0)}%'),
                  const Divider(height: 1),
                  InfoRow(label: 'Daily consumption rate', value: '~5.5% / day'),
                  const Divider(height: 1),
                  InfoRow(label: 'Estimated days remaining', value: '$daysLeft days'),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Refill recommended by',
                    value: '',
                    trailing: Text(
                      _refillDate(daysLeft),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: daysLeft <= 3 ? AppColors.offline : AppColors.textDark,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  InfoRow(label: 'Avg portion per feed', value: '120g'),
                  const Divider(height: 1),
                  InfoRow(label: 'Feeds per day', value: '3 (6AM · 12PM · 5PM)'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Consumption chart (bar chart)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(label: 'Past 7 days', title: 'Daily Consumption'),
                  const SizedBox(height: 16),
                  _WeeklyChart(currentLevel: level),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Reminder toggle
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Set Low-Stock Reminder', style: AppTextStyles.cardTitle),
                        const SizedBox(height: 2),
                        Text('Notify me when food drops below 20%', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _reminderSet,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _reminderSet = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refill reminder scheduled!'), backgroundColor: AppColors.primary),
                );
              },
              icon: const Icon(Icons.notification_add_outlined, size: 18),
              label: const Text('Schedule Refill Reminder'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _refillDate(int daysLeft) {
    final date = DateTime.now().add(Duration(days: daysLeft));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ── Ring Gauge ──────────────────────────────────────────────
class _RingGauge extends StatelessWidget {
  final double percent;
  const _RingGauge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent < 0.25 ? AppColors.offline : AppColors.primary;
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(130, 130),
            painter: _RingPainter(percent: percent, color: color),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color),
              ),
              const Text('hopper', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;
  const _RingPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Background ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, 2 * pi, false,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, 2 * pi * percent, false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.percent != percent;
}

// ── Weekly Bar Chart ────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final double currentLevel;
  const _WeeklyChart({required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [5.8, 5.2, 6.1, 5.5, 5.9, 4.8, currentLevel / 100 * 6.0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final isToday = i == 6;
        final h = (values[i] / 7.0 * 90).clamp(10.0, 90.0);
        return Expanded(
          child: Column(
            children: [
              Container(
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(days[i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isToday ? AppColors.primary : AppColors.textLight,
                  )),
            ],
          ),
        );
      }),
    );
  }
}
