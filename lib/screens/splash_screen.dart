import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _loadProgress = 0.0;
  late AnimationController _logoAnim;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _logoAnim, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _logoAnim, curve: Curves.easeOut),
    );
    _logoAnim.forward();
    _startBootSequence();
  }

  void _startBootSequence() {
    const tick = Duration(milliseconds: 40);
    const step = 0.02;
    _progressTimer = Timer.periodic(tick, (timer) {
      if (!mounted) return;
      setState(() {
        _loadProgress = (_loadProgress + step).clamp(0.0, 1.0);
      });
      if (_loadProgress >= 1.0) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 400), _navigateNext);
      }
    });
  }

  void _navigateNext() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _logoAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient glow circles
          Positioned(
            top: -60,
            left: -60,
            child: _glowCircle(280),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: _glowCircle(320),
          ),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _logoAnim,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeIn,
                  child: Transform.translate(
                    offset: Offset(0, _slideUp.value),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
<<<<<<< HEAD
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
=======
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
>>>>>>> main
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.set_meal_rounded,
                        color: AppColors.accent,
                        size: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Brand title
                  const Text(
                    'Smart Fish Feeder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'WITH APP SCHEDULING',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    child: Text(
                      'Automated feeding for tilapia farms\nand fish ponds across Uganda',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF86EFAC),
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tech chips
                  const Wrap(
                    spacing: 8,
                    children: [
                      _TechChip('Precision Feed'),
                      _TechChip('RTC Scheduler'),
                      _TechChip('Calibrated'),
                      _TechChip('Eco-Balanced'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom progress area
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  width: 140,
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _loadProgress,
<<<<<<< HEAD
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
=======
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
>>>>>>> main
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'v1.0.0 · UGANDA COLLABORATIVE AGRI-FEED',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
<<<<<<< HEAD
        color: AppColors.accent.withValues(alpha: 0.07),
=======
        color: AppColors.accent.withValues(alpha: 0.07),
>>>>>>> main
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  final String label;
  const _TechChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
<<<<<<< HEAD
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
=======
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
>>>>>>> main
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
