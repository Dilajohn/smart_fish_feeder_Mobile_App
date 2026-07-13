import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl    = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter both email and password to continue.');
      return;
    }
    setState(() { _busy = true; _error = null; });

    final ok = await ApiService.instance.login(email: email, password: password);
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      setState(() {
        _busy  = false;
        _error = 'Invalid email or password. Check your credentials and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.set_meal_rounded, color: AppColors.accent, size: 36),
                    ),
                    const SizedBox(height: 12),
                    const Text('Smart Fish Feeder',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                    const SizedBox(height: 4),
                    const Text('Arduino · Django · Flutter',
                        style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 0.5)),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Error banner
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.offline.withValues(alpha: 0.4)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.offline, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 14),
              ],

              const _FieldLabel('Email'),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'farmer@pondA.ug',
                  prefixIcon: Icon(Icons.alternate_email, color: AppColors.textLight),
                ),
              ),

              const SizedBox(height: 16),

              const _FieldLabel('Password'),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                onSubmitted: (_) => _signIn(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textLight),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textLight),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _busy ? null : _signIn,
                child: _busy
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('Signing in…'),
                      ])
                    : const Text('Sign in'),
              ),

              const SizedBox(height: 6),

              // Forgot password — routes to real screen
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                child: const Text('Forgot password?',
                    style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w600)),
              ),

              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('— or —', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                ),
                Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
              ]),

              const SizedBox(height: 16),

              // Create account — routes to signup screen
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Create account',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),

              const SizedBox(height: 16),

              // Guest access
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
                  child: const Text('Continue as guest →',
                      style: TextStyle(color: Colors.white30, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 16),
              const Center(
                child: Text('GROUP21 · v1.0.0',
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1.2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2));
}
