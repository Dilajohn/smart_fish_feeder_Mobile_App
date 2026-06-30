import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Calibration wizard — matches fish_feeder_extra_screens.html "Calibration wizard"
/// Step 2 of 3: Calibrate portions — map labels to servo angles.
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  int _step = 2;
  // Servo angles for the three portion sizes
  double _smallAngle = 45;
  double _mediumAngle = 90;
  double _largeAngle = 135;

  // Estimated grams per drop based on angle
  static const double _smallGramsPerDrop = 8.0;
  static const double _mediumGramsPerDrop = 15.0;
  static const double _largeGramsPerDrop = 22.0;

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calibration saved! Servo angles uploaded to device.'),
          backgroundColor: AppColors.online,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _back() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SETUP · STEP $_step OF 3', style: AppTextStyles.screenLabel),
            const Text(
              'Calibrate portions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Map labels to servo angles',
              style: TextStyle(color: AppColors.textMedium, fontSize: 13),
            ),
            const SizedBox(height: 18),

            // Stepper (1 / 2 / 3)
            _Stepper(currentStep: _step),

            const SizedBox(height: 24),

            const SectionHeader(label: 'Portion sizes'),
            const SizedBox(height: 12),

            _PortionCard(
              name: 'Small',
              angle: _smallAngle,
              gramsPerDrop: _smallGramsPerDrop,
              selected: true,
              onAngleChanged: (v) => setState(() => _smallAngle = v),
            ),
            const SizedBox(height: 10),
            _PortionCard(
              name: 'Medium',
              angle: _mediumAngle,
              gramsPerDrop: _mediumGramsPerDrop,
              selected: false,
              onAngleChanged: (v) => setState(() => _mediumAngle = v),
            ),
            const SizedBox(height: 10),
            _PortionCard(
              name: 'Large',
              angle: _largeAngle,
              gramsPerDrop: _largeGramsPerDrop,
              selected: false,
              onAngleChanged: (v) => setState(() => _largeAngle = v),
            ),

            const SizedBox(height: 18),
            AlertBanner.info('Servo range is 0–180°. Recommended: 45°/90°/135° for 8g/15g/22g drops.'),

            const SizedBox(height: 24),

            // Action buttons
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test dispense — servo rotating…'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Test dispense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _back,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppColors.textLight),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _next,
                    child: Text(_step < 3 ? 'Next — test run' : 'Finish calibration'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int currentStep;
  const _Stepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = ['WiFi', 'Portions', 'Test'];
    return Row(
      children: List.generate(3, (i) {
        final stepNum = i + 1;
        final isActive = stepNum <= currentStep;
        final isCurrent = stepNum == currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
                        border: isCurrent
                            ? Border.all(color: AppColors.accent, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: isActive
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '$stepNum',
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        color: isActive ? AppColors.primary : AppColors.textLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < 2)
                Container(
                  width: 24,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: stepNum < currentStep ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _PortionCard extends StatelessWidget {
  final String name;
  final double angle;
  final double gramsPerDrop;
  final bool selected;
  final ValueChanged<double> onAngleChanged;

  const _PortionCard({
    required this.name,
    required this.angle,
    required this.gramsPerDrop,
    required this.selected,
    required this.onAngleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (angle / 180.0).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFDCFCE7) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.primary : AppColors.textDark,
                ),
              ),
              Text(
                '${angle.toStringAsFixed(0)}°',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textMedium,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Estimated ${gramsPerDrop.toStringAsFixed(0)}g per drop',
            style: TextStyle(
              fontSize: 11,
              color: selected ? AppColors.primary : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar (1/3, 2/3, 3/3 reference)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(
                selected ? AppColors.primary : AppColors.secondary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: angle,
              min: 15,
              max: 165,
              onChanged: onAngleChanged,
            ),
          ),
        ],
      ),
    );
  }
}