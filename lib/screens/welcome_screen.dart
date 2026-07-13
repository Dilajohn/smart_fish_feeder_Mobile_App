import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// Welcome screen — transition from onboarding to auth.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        Positioned(top: -60, left: -60,   child: _blob(280, AppColors.accent.withValues(alpha: 0.06))),
        Positioned(bottom: -100, right: -80, child: _blob(340, AppColors.primary.withValues(alpha: 0.18))),
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Column(children: [
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 2),
                        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.22), blurRadius: 32, spreadRadius: 4)],
                      ),
                      child: const Icon(Icons.set_meal_rounded, color: AppColors.accent, size: 48),
                    ),
                    const SizedBox(height: 22),
                    const Text('Smart Fish Feeder',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.6)),
                    const SizedBox(height: 6),
                    const Text('Uganda Tilapia Aquaculture Platform',
                        style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 0.3)),
                  ]),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Wrap(
                    spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                    children: const [
                      _FeaturePill(Icons.schedule_rounded,      'Scheduled feeds'),
                      _FeaturePill(Icons.wifi_off_rounded,      'Offline-safe'),
                      _FeaturePill(Icons.water_drop_rounded,    'Multi-pond'),
                      _FeaturePill(Icons.notifications_rounded, 'Smart alerts'),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primaryDark,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Log in', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Create account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
                    child: const Text('Continue as guest →',
                        style: TextStyle(color: Colors.white30, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text('GROUP21 · MAKERERE UNIVERSITY · v1.0.0',
                      style: TextStyle(color: Color(0x30FFFFFF), fontSize: 9, fontFamily: 'monospace', letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _blob(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppColors.accent, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.02)..strokeWidth = 0.5;
    for (double x = 0; x < size.width;  x += 32) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 32) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
