import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _baseCtrl;
  late TextEditingController _tokenCtrl;
  bool _saving = false;
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final api = ApiService.instance;
    _baseCtrl  = TextEditingController(text: api.baseUrl);
    _tokenCtrl = TextEditingController(text: api.token ?? '');
  }

  @override
  void dispose() {
    _baseCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _testing = true; _testResult = null; });

    // Temporarily apply the URL to test it without saving
    final originalUrl = ApiService.instance.baseUrl;
    await ApiService.instance.setBaseUrl(_baseCtrl.text.trim());
    final alive = await ApiService.instance.ping();
    if (!alive) await ApiService.instance.setBaseUrl(originalUrl); // restore if failed

    if (!mounted) return;
    setState(() {
      _testing     = false;
      _testSuccess = alive;
      _testResult  = alive
          ? 'Connection successful! Backend is reachable.'
          : 'Could not reach backend. Check the URL and ensure the server is running.';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Persist URL and token via ApiService
    await ApiService.instance.saveSettings(
      base:     _baseCtrl.text.trim(),
      apiToken: _tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim(),
    );

    // Re-run startup load from the new endpoint
    final state = context.read<AppState>();
    await state.refreshFromApi();

    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.dbOnline
              ? 'API settings saved — connected to backend.'
              : 'API settings saved — server offline or token invalid.'),
          backgroundColor: state.dbOnline ? AppColors.online : AppColors.warning,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REMOTE API SETTINGS', style: AppTextStyles.screenLabel),
            Text('Backend URL & auth token',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: state.dbOnline
                ? StatusBadge.online()
                : StatusBadge.warning('Offline'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API ENDPOINT', style: AppTextStyles.screenLabel),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _baseCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        hintText: 'http://192.168.1.100:8000/api/v1',
                        prefixIcon: Icon(Icons.link_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter the backend base URL' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tokenCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Auth Token (optional)',
                        hintText: 'Paste token from /auth/login/ response',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                    ),
                  ],
                ),
              ),

              // Test result banner
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                _testSuccess
                    ? AlertBanner.success(_testResult!)
                    : AlertBanner.error(_testResult!),
              ],

              const SizedBox(height: 14),

              // Test connection button
              OutlinedButton.icon(
                onPressed: _testing ? null : _testConnection,
                icon: _testing
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.wifi_find_outlined, size: 18),
                label: Text(_testing ? 'Testing...' : 'Test Connection'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Save & Apply'),
              ),

              const SizedBox(height: 24),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The base URL should point to your Django server\'s /api/v1 path.\n'
                        'For Android emulator use http://10.0.2.2:8000/api/v1\n'
                        'For a physical device use your LAN IP (e.g. http://192.168.1.100:8000/api/v1)',
                        style: TextStyle(color: AppColors.info, fontSize: 11, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
