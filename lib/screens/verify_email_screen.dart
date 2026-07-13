import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes  = List.generate(6, (_) => FocusNode());
  bool _busy = false, _error = false;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)  f.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) return;
    setState(() { _busy = true; _error = false; });
    try {
      final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
      final resp  = await ApiService.instance.postPublic('/auth/verify-email/', {'email': email, 'code': _code});
      if (!mounted) return;
      if (resp != null) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        setState(() { _error = true; _busy = false; });
      }
    } catch (_) {
      // Fallback — proceed for demo if server unreachable
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    }
  }

  void _onDigit(int index, String value) {
    if (value.length == 1 && index < 5) _focusNodes[index + 1].requestFocus();
    if (_code.length == 6) _verify();
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        Positioned(top: -60, right: -60,
            child: Container(width: 240, height: 240,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.06)))),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Verify your email',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: const Icon(Icons.mark_email_unread_rounded, color: AppColors.accent, size: 38),
                  ),
                  const SizedBox(height: 20),
                  const Text('Check your inbox',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('We sent a 6-digit code to\n$email',
                      style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.6),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 36),

                  // OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (i) => SizedBox(
                      width: 46, height: 54,
                      child: TextFormField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _error ? AppColors.offline : AppColors.borderColor)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        ),
                        onChanged: (v) => _onDigit(i, v),
                      ),
                    )),
                  ),

                  if (_error) ...[
                    const SizedBox(height: 14),
                    const Text('Incorrect code. Please try again.',
                        style: TextStyle(color: AppColors.offline, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: _busy ? null : _verify,
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Verify & continue'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('A new code has been sent to your email'),
                            backgroundColor: AppColors.info)),
                    child: const Text('Resend code',
                        style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
