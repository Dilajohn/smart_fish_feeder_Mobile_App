import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -60, left: -60, child: _glow(280)),
          Positioned(bottom: -80, right: -80, child: _glow(320)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo + brand
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: const Center(
                    child: Icon(Icons.set_meal_rounded, color: AppColors.accent, size: 32),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Smart Fish Feeder',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                ),
                const SizedBox(height: 4),
                const Text(
                  'UGANDAN AQUACULTURE PLATFORM',
                  style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2.0),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Automated feeding for tilapia farms and fish ponds across Uganda. Maintain optimal pond ecosystems easily.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Feature highlights
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: const [
                      _FeatureTile(
                        icon: Icons.calendar_today_outlined,
                        title: 'Remote scheduling',
                        desc: 'Configure trigger durations, portion sizes, and times from anywhere.',
                      ),
                      SizedBox(height: 12),
                      _FeatureTile(
                        icon: Icons.wifi_outlined,
                        title: 'Works without internet',
                        desc: 'Local RTC clock triggers feeding sequences even during cellular blackouts.',
                      ),
                      SizedBox(height: 12),
                      _FeatureTile(
                        icon: Icons.notifications_outlined,
                        title: 'Smart notifications',
                        desc: 'Get notified about critical low food metrics, battery updates, and temperature.',
                      ),
                      SizedBox(height: 12),
                      _FeatureTile(
                        icon: Icons.water_drop_outlined,
                        title: 'Multi-pond management',
                        desc: 'Monitor all your pond feeders from a single dashboard view.',
                      ),
                    ],
                  ),
                ),

                // CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/qr-pair'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.background,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Configure First Feeder Node',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
                        child: const Text(
                          'Skip — Already set up',
                          style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('builtbyokuja · v1.0.0', style: TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withOpacity(0.06)),
      );
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureTile({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
