import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:postgres/postgres.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class DbSettingsScreen extends StatefulWidget {
  const DbSettingsScreen({super.key});

  @override
  State<DbSettingsScreen> createState() => _DbSettingsScreenState();
}

class _DbSettingsScreenState extends State<DbSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _dbNameCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passwordCtrl;
  bool _usePostgres = false;

  bool _obscurePassword = true;
  bool _testingConnection = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final dbService = context.read<AppState>().dbService;
    _hostCtrl = TextEditingController(text: dbService.host);
    _portCtrl = TextEditingController(text: dbService.port.toString());
    _dbNameCtrl = TextEditingController(text: dbService.dbName);
    _userCtrl = TextEditingController(text: dbService.username);
    _passwordCtrl = TextEditingController(text: dbService.password);
    _usePostgres = dbService.usePostgres;
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _dbNameCtrl.dispose();
    _userCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Tests connection using current form values without saving yet
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _testingConnection = true;
      _testResult = null;
      _testSuccess = false;
    });

    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 5432;
    final dbName = _dbNameCtrl.text.trim();
    final user = _userCtrl.text.trim();
    final password = _passwordCtrl.text;

    Connection? testConn;
    try {
      testConn = await Connection.open(
        Endpoint(
          host: host,
          database: dbName,
          username: user,
          password: password.isEmpty ? null : password,
          port: port,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
          connectTimeout: Duration(seconds: 4),
          queryTimeout: Duration(seconds: 4),
        ),
      );

      // Execute simple query to test privileges
      await testConn.execute('SELECT 1');

      setState(() {
        _testSuccess = true;
        _testResult = 'Connection successful! Database is accessible.';
      });
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Connection failed: ${e.toString().split('\n').first}';
      });
    } finally {
      try {
        await testConn?.close();
      } catch (_) {}
      setState(() {
        _testingConnection = false;
      });
    }
  }

  // Saves current form values and updates application state
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<AppState>();
    
    await state.dbService.saveSettings(
      newHost: _hostCtrl.text.trim(),
      newPort: int.tryParse(_portCtrl.text.trim()) ?? 5432,
      newDbName: _dbNameCtrl.text.trim(),
      newUsername: _userCtrl.text.trim(),
      newPassword: _passwordCtrl.text,
      newUsePostgres: _usePostgres,
    );

    // Trigger state database reconnect sequence
    final connected = await state.reconnectDatabase();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(connected 
            ? 'Settings saved. PostgreSQL Database connected successfully!' 
            : 'Settings saved. Database offline: falling back to mock data.'),
          backgroundColor: connected ? AppColors.primary : AppColors.warning,
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
            Text('LOCAL & REMOTE ENDPOINTS', style: AppTextStyles.screenLabel),
            Text('Database Connection',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: state.dbOnline
                ? StatusBadge.success('Connected')
                : StatusBadge.warning('Offline Mode'),
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
              // Endpoint security alert banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.offline, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ENDPOINT SECURITY ALERT',
                            style: TextStyle(
                              color: AppColors.offline,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Direct mobile-to-database connections expose credentials. In production, configure low-privilege SQL users and use TLS encryption. Avoid connecting with the superuser account.',
                            style: TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enable PostgreSQL',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Switch.adaptive(
                          value: _usePostgres,
                          activeTrackColor: AppColors.primary,
                          activeThumbColor: Colors.white,
                          onChanged: (val) {
                            setState(() {
                              _usePostgres = val;
                            });
                          },
                        ),
                      ],
                    ),
                    Text(
                      'If disabled, the application runs entirely on offline local cached mock data.',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (_usePostgres) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ENDPOINT SETTINGS', style: AppTextStyles.screenLabel),
                      const SizedBox(height: 14),

                      // Host Input
                      TextFormField(
                        controller: _hostCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Database Host / IP Address',
                          hintText: 'e.g. 10.0.2.2 or db.example.com',
                          prefixIcon: Icon(Icons.dns_outlined),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty 
                            ? 'Please enter database host IP' 
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Port & DB Name
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _portCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                                hintText: '5432',
                                prefixIcon: Icon(Icons.numbers_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value.trim()) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _dbNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Database Name',
                                hintText: 'smart_fish_feeder',
                                prefixIcon: Icon(Icons.storage_outlined),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty 
                                  ? 'Required' 
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Username
                      TextFormField(
                        controller: _userCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'e.g. fish_farmer',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty 
                            ? 'Please enter username' 
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.password_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Connection test result display
                if (_testResult != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _testSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _testSuccess ? AppColors.online : AppColors.offline,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _testSuccess ? Icons.check_circle_outline : Icons.error_outline,
                          color: _testSuccess ? AppColors.online : AppColors.offline,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _testResult!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _testSuccess ? const Color(0xFF15803D) : const Color(0xFF9F1239),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Test connection button
                OutlinedButton(
                  onPressed: _testingConnection ? null : _testConnection,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _testingConnection
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Text(
                          'Test Database Connection',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),

                const SizedBox(height: 12),
              ],

              // Save settings button
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save & Apply Settings'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
