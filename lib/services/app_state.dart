import 'package:flutter/material.dart';
import '../models/models.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  ApiService get apiService => ApiService.instance;

  bool _dbOnline = false;
  bool get dbOnline => _dbOnline;

  // Neon-backed flow: app talks to Django API only.
  bool get usingPostgres => false;

  AppState() {
    initDatabase();
  }

  Future<void> initDatabase() async {
    await ApiService.instance.init();
    await refreshFromApi();
  }

  Future<void> refreshData() async {
    await refreshFromApi();
  }

  List<PondModel> _ponds = [];
  List<PondModel> get ponds => _ponds;
  bool get hasOfflinePond => _ponds.any((p) => !p.isOnline);
  bool get hasCriticalFood => _ponds.any((p) => p.isOnline && p.isFoodLow);

  Future<void> addPond(PondModel pond) async {
    if (_dbOnline) {
      await ApiService.instance.createPond({
        'name': pond.name,
        'feeder_serial': pond.feederSerial,
        'food_percent': pond.foodPercent.toInt(),
        'next_feed_time': pond.nextFeedTime,
        'water_temp': pond.waterTemp,
        'is_online': pond.isOnline,
      });
    }
    await refreshFromApi();
  }

  List<FeedSchedule> _schedules = [];
  List<FeedSchedule> get schedules => _schedules;

  void toggleSchedule(String id) {
    _schedules = _schedules
        .map((s) => s.id == id ? s.copyWith(isEnabled: !s.isEnabled) : s)
        .toList();
    notifyListeners();
    final updated = _schedules.firstWhere((s) => s.id == id);
    ApiService.instance.toggleSchedule(id, updated.isEnabled);
  }

  Future<void> addSchedule(FeedSchedule s) async {
    var persisted = true;
    if (_dbOnline) {
      final result = await ApiService.instance.createSchedule({
        'id': s.id,
        'pond': s.pondName,
        'hour': s.time.hour,
        'minute': s.time.minute,
        'duration_seconds': s.durationSeconds,
        'portion_grams': s.portionGrams.toInt(),
        'is_enabled': s.isEnabled,
        'weekdays': s.weekdays,
      });
      persisted = result != null;
    }
    if (persisted || !_dbOnline) {
      _schedules = [..._schedules, s];
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    await ApiService.instance.deleteSchedule(id);
    _schedules = _schedules.where((s) => s.id != id).toList();
    notifyListeners();
  }

  List<FeedLog> _feedLogs = [];
  List<FeedLog> get feedLogs => _feedLogs;

  Future<void> addFeedLog(FeedLog log) async {
    _feedLogs = [log, ..._feedLogs];
    notifyListeners();
    try {
      await ApiService.instance.createFeedLog({
        'id': log.id,
        'pond_name': log.pondName,
        'portion_grams': log.portionGrams,
        'trigger_type': log.trigger,
        'synced': log.synced,
      });
    } catch (_) {}
  }

  double _hopperLevel = 0.0;
  double get hopperLevel => _hopperLevel;

  void setHopperLevel(double v) {
    _hopperLevel = v;
    _ponds = _ponds
        .map((p) => p.name == 'Pond A' ? p.copyWith(foodPercent: v) : p)
        .toList();
    notifyListeners();
    ApiService.instance.pushTelemetry({
      'device_serial': 'SFF-001-KLA',
      'food_level_pct': v,
    });
  }

  DeviceInfo? _deviceInfo;
  DeviceInfo get deviceInfo => _deviceInfo ??
      const DeviceInfo(
        serial: 'N/A',
        pondName: 'N/A',
        firmwareVersion: 'N/A',
        latestFirmware: 'N/A',
        wifiRssi: -100,
        pingMs: 0,
        uptime: Duration.zero,
        hardwareStatus: {},
        firmwareUpdateAvailable: false,
      );

  Future<void> refreshDeviceInfo(String serial) async {
    if (_dbOnline) {
      final data = await ApiService.instance.getDevice(serial);
      if (data != null) {
        _deviceInfo = DeviceInfo(
          serial: data['serial'] as String,
          pondName: data['pond_name'] as String,
          firmwareVersion: data['firmware_version'] as String,
          latestFirmware: data['latest_firmware'] as String,
          wifiRssi: (data['wifi_rssi'] as num).toDouble(),
          pingMs: _asInt(data['ping_ms']),
          uptime: Duration(seconds: _asInt(data['uptime_seconds'])),
          hardwareStatus: Map<String, String>.from(
              (data['hardware_status'] as Map?) ?? <String, String>{}),
          firmwareUpdateAvailable:
              data['firmware_update_available'] as bool? ?? false,
        );
        notifyListeners();
      }
    }
  }

  SyncStatusModel? _syncStatus;
  SyncStatusModel get syncStatus => _syncStatus ??
      SyncStatusModel(
        pendingUploads: 0,
        failedRetries: 0,
        recoveredEvents: 0,
        lastSyncTime: DateTime.now(),
        eepromHealthy: true,
        eepromUsedBytes: 0,
        eepromTotalBytes: 4096,
      );

  Future<void> refreshSyncStatus() async {
    if (_dbOnline) {
      final data = await ApiService.instance.getSyncStatus();
      if (data != null) {
        _syncStatus = SyncStatusModel(
          pendingUploads: _asInt(data['pending_uploads']),
          failedRetries: _asInt(data['failed_retries']),
          recoveredEvents: _asInt(data['recovered_events']),
          lastSyncTime: DateTime.tryParse(
                  data['last_sync_time'] as String? ?? '') ??
              DateTime.now(),
          eepromHealthy: data['eeprom_healthy'] as bool? ?? true,
          eepromUsedBytes: _asInt(data['eeprom_used_bytes']),
          eepromTotalBytes: _asInt(data['eeprom_total_bytes'], 4096),
        );
        notifyListeners();
      }
    }
  }

  String _firmwareState = 'idle';
  String get firmwareState => _firmwareState;

  Future<void> triggerFirmwareUpdate() async {
    if (_firmwareState != 'idle') return;
    _firmwareState = 'updating';
    notifyListeners();
    await ApiService.instance.sendFirmwareUpdate('SFF-001-KLA');
    await Future.delayed(const Duration(seconds: 3));
    _firmwareState = 'updated';
    notifyListeners();
  }

  void resetFirmwareState() {
    _firmwareState = 'idle';
    notifyListeners();
  }

  bool _cooldownActive = false;
  int _cooldownMins = 0;
  bool get cooldownActive => _cooldownActive;
  int get cooldownRemainingMinutes => _cooldownMins;

  void activateCooldown(int minutes) {
    _cooldownActive = true;
    _cooldownMins = minutes;
    notifyListeners();
  }

  void overrideCooldown() {
    _cooldownActive = false;
    _cooldownMins = 0;
    notifyListeners();
  }

  bool _onboardingDone = false;
  bool get onboardingDone => _onboardingDone;
  void completeOnboarding() {
    _onboardingDone = true;
    notifyListeners();
  }

  Future<void> refreshFromApi() async {
    final alive = await ApiService.instance.ping();
    _dbOnline = alive;

    if (alive) {
      final pondsData = await ApiService.instance.getPonds();
      if (pondsData != null) {
        _ponds = pondsData.map((d) => PondModel(
          id: _asInt(d['id']),
          name: d['name'] as String? ?? '',
          feederSerial: d['feeder_serial'] as String? ?? '',
          foodPercent: (d['food_percent'] as num? ?? 0).toDouble(),
          nextFeedTime: d['next_feed_time'] as String? ?? 'Offline',
          waterTemp: (d['water_temp'] as num? ?? 0).toDouble(),
          isOnline: d['is_online'] as bool? ?? false,
          lastSeen: DateTime.tryParse(d['last_seen'] as String? ?? '') ??
              DateTime.now(),
        )).toList();

        final pondA = _ponds
            .where((p) => p.name == 'Pond A')
            .cast<PondModel?>()
            .firstWhere((_) => true, orElse: () => _ponds.isNotEmpty ? _ponds.first : null);
        _hopperLevel = pondA?.foodPercent ?? 0;
      }

      final schedulesData = await ApiService.instance.getSchedules();
      if (schedulesData != null) {
        _schedules = schedulesData.map((d) {
          return FeedSchedule(
            id: d['id'] as String,
            pondName: d['pond'] as String? ?? d['pond_name'] as String? ?? '',
            time: TimeOfDay(
              hour: _asInt(d['hour']),
              minute: _asInt(d['minute']),
            ),
            durationSeconds: _asInt(d['duration_seconds']),
            portionGrams: (d['portion_grams'] as num? ?? 0).toDouble(),
            isEnabled: d['is_enabled'] as bool? ?? true,
            weekdays: List<bool>.from(
                d['weekdays'] as List? ?? List.filled(7, true)),
          );
        }).toList();
      }

      final logsData = await ApiService.instance.getFeedLogs(limit: 30);
      if (logsData != null) {
        _feedLogs = logsData.map((d) => FeedLog(
          id: d['id'] as String,
          pondName: d['pond_name'] as String? ?? '',
          timestamp: DateTime.tryParse(d['timestamp'] as String? ?? '') ??
              DateTime.now(),
          portionGrams: (d['portion_grams'] as num? ?? 0).toDouble(),
          trigger: d['trigger_type'] as String? ?? 'scheduled',
          synced: d['synced'] as bool? ?? true,
        )).toList();
      }

      await refreshSyncStatus();
    }
    notifyListeners();
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
