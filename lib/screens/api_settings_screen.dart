import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
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

  @override
  void initState() {
    super.initState();
    final api = context.read<AppState>().apiService;
    _baseCtrl = TextEditingController(text: api.baseUrl);
    _tokenCtrl = TextEditingController(text: api.token ?? '');
  }

  @override
  void dispose() {
    _baseCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    await state.apiService.saveSettings(base: _baseCtrl.text.trim(), apiToken: _tokenCtrl.text.trim());
    // Refresh data from new endpoint
    await state.initDatabase();
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API settings saved')));
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
            Text('Configure backend URL & token', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: state.dbOnline ? StatusBadge.success('Connected') : StatusBadge.warning('Offline'),
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
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        hintText: 'http://127.0.0.1:8001',
                        prefixIcon: Icon(Icons.link_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter API base URL' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tokenCtrl,
                      decoration: const InputDecoration(
                        labelText: 'API Token',
                        hintText: 'Token for authenticated calls',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator() : const Text('Save & Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
