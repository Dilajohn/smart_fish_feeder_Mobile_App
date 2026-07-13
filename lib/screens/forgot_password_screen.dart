import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _busy = false, _sent = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ApiService.instance.postPublic('/auth/password-reset/', {'email': _emailCtrl.text.trim()});
    } catch (_) {}
    if (mounted) setState(() { _busy = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
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
                const Text('Forgot password',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: AppColors.accent, size: 36),
                  ),
                  const SizedBox(height: 20),
                  const Text('Reset your password',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                  const SizedBox(height: 8),
                  const Text("Enter your email and we'll send you a reset link",
                      style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 30),

                  if (_sent)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.online.withValues(alpha: 0.3)),
                      ),
                      child: Column(children: [
                        const Icon(Icons.mark_email_read_rounded, color: AppColors.online, size: 40),
                        const SizedBox(height: 12),
                        const Text('Email sent!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.online)),
                        const SizedBox(height: 6),
                        Text('A password reset link has been sent to ${_emailCtrl.text}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMedium, fontSize: 13, height: 1.5)),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary)),
                          child: const Text('Back to login'),
                        ),
                      ]),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Email address',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMedium)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                            decoration: const InputDecoration(
                                hintText: 'farmer@pondA.ug',
                                prefixIcon: Icon(Icons.alternate_email_rounded)),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _busy ? null : _send,
                            child: _busy
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : const Text('Send reset link'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back to login',
                                style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                      ),
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
