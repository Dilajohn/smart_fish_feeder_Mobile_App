import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl   = TextEditingController();
  final _pwd2Ctrl  = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _pwdCtrl, _pwd2Ctrl]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pwdCtrl.text != _pwd2Ctrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final resp = await ApiService.instance.postPublic('/auth/register/', {
        'name':     _nameCtrl.text.trim(),
        'email':    _emailCtrl.text.trim(),
        'phone':    _phoneCtrl.text.trim(),
        'password': _pwdCtrl.text,
      });
      if (!mounted) return;
      if (resp != null) {
        Navigator.pushReplacementNamed(context, '/verify-email',
            arguments: _emailCtrl.text.trim());
      } else {
        setState(() { _error = 'Registration failed. Try again or use a different email.'; _busy = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Server unreachable. Check your connection.'; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        Positioned(top: -60,   right: -60, child: _blob(240, AppColors.accent.withValues(alpha: 0.06))),
        Positioned(bottom: -80, left: -80, child: _blob(300, AppColors.primary.withValues(alpha: 0.15))),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Create account',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Join Smart Fish Feeder',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      const Text('Start managing your tilapia ponds today',
                          style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      const SizedBox(height: 20),

                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.offline.withValues(alpha: 0.3)),
                          ),
                          child: Text(_error!, style: const TextStyle(color: AppColors.offline, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 14),
                      ],

                      _FieldLabel('Full name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                        decoration: const InputDecoration(hintText: 'Okuja Moses', prefixIcon: Icon(Icons.person_outline_rounded)),
                      ),
                      const SizedBox(height: 14),

                      _FieldLabel('Email address'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        decoration: const InputDecoration(hintText: 'farmer@pondA.ug', prefixIcon: Icon(Icons.alternate_email_rounded)),
                      ),
                      const SizedBox(height: 14),

                      _FieldLabel('Phone number (optional)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: '+256 700 000 000', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                      const SizedBox(height: 14),

                      _FieldLabel('Password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pwdCtrl,
                        obscureText: _obscure1,
                        validator: (v) => (v == null || v.length < 8) ? 'Password must be 8+ characters' : null,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            color: AppColors.textLight,
                            onPressed: () => setState(() => _obscure1 = !_obscure1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _FieldLabel('Confirm password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pwd2Ctrl,
                        obscureText: _obscure2,
                        validator: (v) => (v == null || v.isEmpty) ? 'Confirm your password' : null,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            color: AppColors.textLight,
                            onPressed: () => setState(() => _obscure2 = !_obscure2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('Create account'),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text('Already have an account? Log in',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _blob(double s, Color c) =>
      Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: c));
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMedium));
}
