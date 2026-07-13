import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// 8. COOLDOWN SAFETY LOCK SCREEN
// ─────────────────────────────────────────────
class CooldownLockScreen extends StatelessWidget {
  const CooldownLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final locked = state.cooldownActive;
    final mins = state.cooldownRemainingMinutes;

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SAFETY SYSTEM', style: AppTextStyles.screenLabel),
            Text('Cooldown Lock',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: locked
                ? StatusBadge.warning('Locked')
                : StatusBadge.success('Unlocked'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Big lock visual
            AppCard(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: locked
                          ? const Color(0xFFFEF9C3)
                          : const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      locked ? Icons.lock_outline : Icons.lock_open_outlined,
                      color: locked ? AppColors.warning : AppColors.online,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    locked ? 'Manual Feed Locked' : 'Cooldown Released',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: locked ? AppColors.warning : AppColors.online,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      locked
                          ? 'A cooldown period prevents back-to-back manual feeds that could overload fish and pollute pond water quality.'
                          : 'Manual feeds are unlocked. You can now trigger a manual feed from the dashboard.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 12,
                          height: 1.6),
                    ),
                  ),
                  if (locked) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '$mins min remaining',
                        style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),

            const SizedBox(height: 14),

            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COOLDOWN PARAMETERS', style: AppTextStyles.screenLabel),
                  SizedBox(height: 12),
                  InfoRow(label: 'Cooldown Duration', value: '30 minutes'),
                  Divider(height: 1),
                  InfoRow(
                      label: 'Trigger Reason',
                      value: 'Manual override at 10:38 AM'),
                  Divider(height: 1),
                  InfoRow(
                      label: 'Total Overrides Today', value: '1 of 3 allowed'),
                  Divider(height: 1),
                  InfoRow(label: 'Pollution Prevention', value: 'Active'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tilapia overfeeding raises ammonia levels and depletes oxygen. The cooldown prevents water quality degradation between manual feeds.',
                      style: TextStyle(
                          color: AppColors.info, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (locked)
              OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Override Cooldown?'),
                      content: const Text(
                          'This may affect water quality. Only override in an emergency.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            state.overrideCooldown();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.offline),
                          child: const Text('Override Anyway'),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.offline,
                  side: const BorderSide(color: AppColors.offline),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Emergency Override Cooldown',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 9. SYNC STATUS SCREEN
// ─────────────────────────────────────────────
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  bool _syncing = false;

  @override
  Widget build(BuildContext context) {
    final sync = context.read<AppState>().syncStatus;
    final fillPct = (sync.eepromFillPercent * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EEPROM & CLOUD', style: AppTextStyles.screenLabel),
            Text('Data Sync Status',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (sync.pendingUploads > 0)
              AlertBanner.warning(
                  '${sync.pendingUploads} feed events pending upload to server.'),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SYNC COUNTERS', style: AppTextStyles.screenLabel),
                  const SizedBox(height: 12),
                  InfoRow(
                      label: 'Pending Uploads',
                      value: '${sync.pendingUploads} events'),
                  const Divider(height: 1),
                  InfoRow(
                      label: 'Failed Retries',
                      value: '${sync.failedRetries} queued'),
                  const Divider(height: 1),
                  InfoRow(
                      label: 'Recovered Events',
                      value: '${sync.recoveredEvents} uploaded'),
                  const Divider(height: 1),
                  InfoRow(
                      label: 'Last Sync', value: _timeAgo(sync.lastSyncTime)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EEPROM MEMORY', style: AppTextStyles.screenLabel),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${sync.eepromUsedBytes} / ${sync.eepromTotalBytes} bytes',
                          style: AppTextStyles.bodySmall),
                      Text('$fillPct% used',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: sync.eepromFillPercent,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'EEPROM Health',
                    value: '',
                    trailing: StatusBadge(
                      label: sync.eepromHealthy ? 'Healthy' : 'Warning',
                      color: sync.eepromHealthy
                          ? AppColors.online
                          : AppColors.offline,
                      bgColor: sync.eepromHealthy
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _syncing
                  ? null
                  : () async {
                      final state = context.read<AppState>();
                      setState(() => _syncing = true);
                      // Find first online pond's serial
                      final serial = state.ponds.isNotEmpty
                          ? state.ponds.firstWhere(
                                (p) => p.isOnline,
                                orElse: () => state.ponds.first,
                              ).feederSerial
                          : 'SFF-001-KLA';
                      final result = await ApiService.instance.syncEeprom(serial);
                      if (!mounted) return;
                      setState(() => _syncing = false);
                      // Refresh sync status from API
                      await state.refreshSyncStatus();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result != null
                              ? 'Hardware re-sync command queued for $serial.'
                              : 'Device unreachable — will retry when online.'),
                          backgroundColor: result != null
                              ? AppColors.primary
                              : AppColors.warning,
                        ),
                      );
                    },
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync, size: 18),
              label: Text(_syncing ? 'Syncing...' : 'Force Hardware Re-sync'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ─────────────────────────────────────────────
// 10. EXPORT LOG SCREEN
// ─────────────────────────────────────────────
class ExportLogScreen extends StatefulWidget {
  const ExportLogScreen({super.key});

  @override
  State<ExportLogScreen> createState() => _ExportLogScreenState();
}

class _ExportLogScreenState extends State<ExportLogScreen> {
  String _format = 'CSV';
  bool _busy = false;
  DateTime _from = DateTime.now().subtract(const Duration(days: 17));
  DateTime _to   = DateTime.now();

  final Map<String, bool> _segments = {
    'Feed Event Logs': true,
    'Telemetry Sensor Readings': true,
    'Water Quality Telemetry': true,
    'Firmware Status Reports': false,
    'Unsynced Offline Events': true,
  };

  String get _fromLabel => DateFormat('MMM dd, yyyy').format(_from);
  String get _toLabel   => DateFormat('MMM dd, yyyy').format(_to);

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => isFrom ? _from = picked : _to = picked);
  }

  Future<void> _export() async {
    final state  = context.read<AppState>();
    final serial = state.ponds.isNotEmpty
        ? state.ponds.firstWhere((p) => p.isOnline, orElse: () => state.ponds.first).feederSerial
        : 'SFF-001-KLA';

    setState(() => _busy = true);

    final result = await ApiService.instance.exportLogs(
      serial: serial,
      from:   DateFormat('yyyy-MM-dd').format(_from),
      to:     DateFormat('yyyy-MM-dd').format(_to),
      format: _format.toLowerCase(),
    );

    if (!mounted) return;
    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result != null
            ? result['message'] as String? ??
                'Export queued as $_format! Download link sent to your email.'
            : 'Server unreachable — export will be processed when back online.'),
        backgroundColor: result != null ? AppColors.primary : AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DATA EXPORT PANEL', style: AppTextStyles.screenLabel),
            Text('Export Feed Log',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range — tappable, real date pickers
                  const Text('SELECT INTERVAL', style: AppTextStyles.screenLabel),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickDate(isFrom: true),
                          child: _DateBox(label: 'From', value: _fromLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickDate(isFrom: false),
                          child: _DateBox(label: 'To', value: _toLabel),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const Text('SEGMENTS TO EXPORT',
                      style: AppTextStyles.screenLabel),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: _segments.entries
                          .map((e) => SwitchListTile.adaptive(
                                dense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                title: Text(e.key,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                value: e.value,
                                activeTrackColor: AppColors.primary,
                                activeThumbColor: Colors.white,
                                onChanged: (v) =>
                                    setState(() => _segments[e.key] = v),
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text('DISTRIBUTE FORMATS',
                      style: AppTextStyles.screenLabel),
                  const SizedBox(height: 8),
                  Row(
                    children: ['CSV', 'PDF', 'Excel'].map((f) {
                      final selected = _format == f;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _format = f),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFF0FDF4)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                  width: selected ? 2 : 1),
                            ),
                            child: Text(
                              f,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textMedium,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  AlertBanner.info(
                      'Date range: $_fromLabel → $_toLabel  ·  Format: $_format'),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            color: Colors.white,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _export,
              icon: _busy
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_outlined, size: 18),
              label: Text(_busy
                  ? 'Compiling export...'
                  : 'Compile & Export Log as $_format'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String value;
  const _DateBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.screenLabel.copyWith(fontSize: 9)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MENU / SCREENS DIRECTORY SCREEN
// ─────────────────────────────────────────────
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const _screens = [
    _ScreenEntry('splash', '⚡ 1. Boot & Splash',
        'Hardware boot & synchronization loader sequence', 'General'),
    _ScreenEntry('/login', '🔐 2. Login',
        'Farmer sign-in with email & password', 'General'),
    _ScreenEntry('onboarding', '👋 3. Onboarding Welcome',
        'Platform welcome screen & initial intro slides', 'General'),
    _ScreenEntry(
        'dashboard',
        '📱 4. Feeder Main Dashboard',
        'Active schedules, live feed triggers, and telemetry logs',
        'Schedules & Control'),
    _ScreenEntry(
        'ponds',
        '🐟 5. Multi-Pond Live Space',
        'Overview scorecards of all active feed ponds in Uganda',
        'Schedules & Control'),
    _ScreenEntry(
        '/add-schedule',
        '➕ 6. Add Schedule',
        'Create new feed schedule with time, days, and portion',
        'Schedules & Control'),
    _ScreenEntry(
        'refill',
        '⚖️ 7. Refill Prediction',
        'Predictive analytics for hopper feed capacity level gauge',
        'Analytics'),
    _ScreenEntry('/analytics', '📊 8. Feeding Analytics',
        'Weekly feed summary with bar chart and insights', 'Analytics'),
    _ScreenEntry(
        'device',
        '🏥 9. Hardware Diagnostics',
        'WiFi RSSI strength, ping rates, servo & RTC DS3231 states',
        'Diagnostics'),
    _ScreenEntry(
        '/cooldown',
        '🔒 10. Cooldown Safety Lock',
        'Prevents water quality pollution from frequent overrides',
        'Diagnostics'),
    _ScreenEntry('/offline', '📡 11. Offline Mode',
        'RTC fallback active, buffered events, last sync info', 'Diagnostics'),
    _ScreenEntry('/water-alert', '💧 12. Water Quality Alert',
        'pH/temperature/DO alerts with auto-actions', 'Diagnostics'),
    _ScreenEntry('/notifications', '🔔 13. Notifications',
        'Today & yesterday alert timeline', 'General'),
    _ScreenEntry('/profile', '👤 14. Profile',
        'Account, my farms, system info, sign out', 'General'),
    _ScreenEntry('/qr-pair', '📷 15. QR Pairing Device',
        'Match physical node QR stickers to ponds', 'Provisioning'),
    _ScreenEntry('/calibration', '🎚 16. Calibration Wizard',
        'Map portion labels to servo angles (45°/90°/135°)', 'Provisioning'),
    _ScreenEntry(
        '/sync',
        '🔄 17. Data Sync Status',
        'Real-time EEPROM memory registers & server transaction handshakes',
        'Provisioning'),
    _ScreenEntry(
        '/export-log',
        '📄 18. Feed Log CSV Export',
        'Compile & download high-fidelity feeding history summaries',
        'Analytics'),
  ];

  static const _categories = [
    'General',
    'Provisioning',
    'Schedules & Control',
    'Diagnostics',
    'Analytics'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UGANDAN AGRI-FEEDER NODE',
                style: AppTextStyles.screenLabel
                    .copyWith(color: AppColors.accent)),
            const Text('Screens Directory',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: const Text('18 Screens',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Text(
              '✨ Seamless navigation active: select any screen below to navigate to it.',
              style:
                  TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: _categories.map((cat) {
                final entries =
                    _screens.where((s) => s.category == cat).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 16),
                      child: Text('// ${cat.toUpperCase()}',
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5)),
                    ),
                    ...entries.map((e) => _ScreenTile(entry: e)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenEntry {
  final String route;
  final String name;
  final String desc;
  final String category;
  const _ScreenEntry(this.route, this.name, this.desc, this.category);
}

class _ScreenTile extends StatelessWidget {
  final _ScreenEntry entry;
  const _ScreenTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to named routes or switch tabs
        if (entry.route.startsWith('/')) {
          Navigator.pushNamed(context, entry.route);
        } else {
          // For bottom nav tabs, pop to shell and switch
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(entry.desc,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white30, size: 14),
          ],
        ),
      ),
    );
  }
}
