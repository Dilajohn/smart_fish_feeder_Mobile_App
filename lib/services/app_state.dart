import 'package:flutter/material.dart';
import '../models/models.dart';
import 'api_service.dart';
import 'database_service.dart';

class AppState extends ChangeNotifier {
  // ── Backend service instances ──────────────────────────────
  final DatabaseService dbService  = DatabaseService();

  // Expose the ApiService singleton so screens can access it
  ApiService get apiService => ApiService.instance;

  bool _dbOnline      = false;
  bool _usingPostgres = false;
  bool get dbOnline      => _dbOnline;
  bool get usingPostgres => _usingPostgres;

  // ── Initialise on startup ──────────────────────────────────
  AppState() { initDatabase(); }

  Future<void> initDatabase() async {
    await dbService.loadSettings();
    await ApiService.instance.init();

    if (dbService.usePostgres) {
      _usingPostgres = true;
      final connected = await dbService.connect();
      if (connected) {
        _dbOnline = true;
        await refreshData();
        return;
      }
    }

    // Fallback: REST API
    _usingPostgres = false;
    await refreshFromApi();
  }

  Future<bool> reconnectDatabase() async {
    await dbService.disconnect();
    final connected = await dbService.connect();
    _dbOnline = connected;
    if (connected) {
      await refreshData();
    } else {
      notifyListeners();
    }
    return connected;
  }

  // Refresh all state from whichever backend is active
  Future<void> refreshData() async {
    if (_usingPostgres) {
      await _loadFromPostgres();
    } else {
      await refreshFromApi();
    }
  }

  Future<void> _loadFromPostgres() async {
    try {
      final dbPonds = await dbService.getPonds();
      if (dbPonds.isNotEmpty) {
        _ponds = dbPonds;
        final pondA = _ponds.firstWhere(
            (p) => p.name == 'Pond A', orElse: () => _ponds.first);
        _hopperLevel = pondA.foodPercent;
      }
      final dbSchedules = await dbService.getSchedules();
      if (dbSchedules.isNotEmpty) _schedules = dbSchedules;

      final dbLogs = await dbService.getFeedLogs();
      if (dbLogs.isNotEmpty) _feedLogs = dbLogs;

      final dbDevice = await dbService.getDeviceInfo('SFF-001-KLA');
      if (dbDevice != null) _deviceInfo = dbDevice;

      final dbSync = await dbService.getSyncStatus();
      if (dbSync != null) _syncStatus = dbSync;
    } catch (e) {
      debugPrint('AppState PostgreSQL load error: $e');
      _dbOnline = false;
    }
    notifyListeners();
  }

  // ── Ponds ──────────────────────────────────────────────────
  // Fallback seed data shown while waiting for the first API response
  List<PondModel> _ponds = [
    PondModel(id:1, name:'Pond A', feederSerial:'SFF-001-KLA', foodPercent:67, nextFeedTime:'12:00 PM', waterTemp:24.0, isOnline:true,  lastSeen:DateTime.now()),
    PondModel(id:2, name:'Pond B', feederSerial:'SFF-002-KLA', foodPercent:0,  nextFeedTime:'Offline',  waterTemp:0,    isOnline:false, lastSeen:DateTime.now().subtract(const Duration(hours:8))),
    PondModel(id:3, name:'Pond C', feederSerial:'SFF-003-KLA', foodPercent:19, nextFeedTime:'5:00 PM',  waterTemp:23.0, isOnline:true,  lastSeen:DateTime.now().subtract(const Duration(minutes:2))),
  ];
  List<PondModel> get ponds => _ponds;
  bool get hasOfflinePond  => _ponds.any((p) => !p.isOnline);
  bool get hasCriticalFood => _ponds.any((p) => p.isOnline && p.isFoodLow);

  Future<void> addPond(PondModel pond) async {
    if (_dbOnline) {
      if (_usingPostgres) {
        await dbService.addPond(pond);
      } else {
        await ApiService.instance.createPond({
          'name': pond.name, 'feeder_serial': pond.feederSerial,
          'food_percent': pond.foodPercent.toInt(),
          'next_feed_time': pond.nextFeedTime,
          'water_temp': pond.waterTemp, 'is_online': pond.isOnline,
        });
      }
    }
    _ponds = [..._ponds, pond];
    notifyListeners();
  }

  // ── Schedules ──────────────────────────────────────────────
  List<FeedSchedule> _schedules = [
    const FeedSchedule(id:'sch-001', pondName:'Pond A', time:TimeOfDay(hour:6,  minute:0),  durationSeconds:8,  portionGrams:120, isEnabled:true,  weekdays:[true,true,true,true,true,true,true]),
    const FeedSchedule(id:'sch-002', pondName:'Pond A', time:TimeOfDay(hour:12, minute:0),  durationSeconds:10, portionGrams:150, isEnabled:true,  weekdays:[true,true,true,true,true,true,true]),
    const FeedSchedule(id:'sch-003', pondName:'Pond A', time:TimeOfDay(hour:17, minute:0),  durationSeconds:8,  portionGrams:120, isEnabled:false, weekdays:[true,true,true,true,true,false,false]),
    const FeedSchedule(id:'sch-004', pondName:'Pond C', time:TimeOfDay(hour:17, minute:0),  durationSeconds:6,  portionGrams:90,  isEnabled:true,  weekdays:[true,true,true,true,true,true,true]),
  ];
  List<FeedSchedule> get schedules => _schedules;

  void toggleSchedule(String id) {
    _schedules = _schedules.map((s) => s.id == id ? s.copyWith(isEnabled: !s.isEnabled) : s).toList();
    notifyListeners();
    final updated = _schedules.firstWhere((s) => s.id == id);
    if (_usingPostgres) {
      dbService.toggleSchedule(id, updated.isEnabled);
    } else {
      ApiService.instance.toggleSchedule(id, updated.isEnabled);
    }
  }

  Future<void> addSchedule(FeedSchedule s) async {
    bool persisted = true;
    if (_dbOnline) {
      if (_usingPostgres) {
        persisted = await dbService.addSchedule(s);
      } else {
        final result = await ApiService.instance.createSchedule({
          'id': s.id, 'pond': s.pondName,
          'hour': s.time.hour, 'minute': s.time.minute,
          'duration_seconds': s.durationSeconds,
          'portion_grams': s.portionGrams.toInt(),
          'is_enabled': s.isEnabled, 'weekdays': s.weekdays,
        });
        persisted = result != null;
      }
    }
    if (persisted || !_dbOnline) {
      _schedules = [..._schedules, s];
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    if (_usingPostgres) {
      await dbService.deleteSchedule(id);
    } else {
      await ApiService.instance.deleteSchedule(id);
    }
    _schedules = _schedules.where((s) => s.id != id).toList();
    notifyListeners();
  }

  // ── Feed Logs ──────────────────────────────────────────────
  List<FeedLog> _feedLogs = [
    FeedLog(id:'log-1', pondName:'Pond A', timestamp:DateTime.now().subtract(const Duration(hours:1, minutes:15)), portionGrams:120, trigger:'scheduled', synced:true),
    FeedLog(id:'log-2', pondName:'Pond A', timestamp:DateTime.now().subtract(const Duration(hours:7)),             portionGrams:150, trigger:'scheduled', synced:true),
    FeedLog(id:'log-3', pondName:'Pond C', timestamp:DateTime.now().subtract(const Duration(hours:2)),             portionGrams:90,  trigger:'manual',    synced:true),
    FeedLog(id:'log-4', pondName:'Pond A', timestamp:DateTime.now().subtract(const Duration(days:1, hours:1)),     portionGrams:120, trigger:'scheduled', synced:false),
  ];
  List<FeedLog> get feedLogs => _feedLogs;

  Future<void> addFeedLog(FeedLog log) async {
    _feedLogs = [log, ..._feedLogs];
    notifyListeners();
    try {
      if (_usingPostgres) {
        await dbService.addFeedLog(log);
      } else {
        await ApiService.instance.createFeedLog({
          'id': log.id, 'pond_name': log.pondName,
          'portion_grams': log.portionGrams,
          'trigger_type': log.trigger, 'synced': log.synced,
        });
      }
    } catch (_) {}
  }

  // ── Hopper level ───────────────────────────────────────────
  double _hopperLevel = 67.0;
  double get hopperLevel => _hopperLevel;

  void setHopperLevel(double v) {
    _hopperLevel = v;
    _ponds = _ponds.map((p) => p.name == 'Pond A' ? p.copyWith(foodPercent: v) : p).toList();
    notifyListeners();
    if (_usingPostgres) {
      dbService.updatePondHopperLevel('Pond A', v);
    } else {
      ApiService.instance.pushTelemetry({'device_serial': 'SFF-001-KLA', 'food_level_pct': v});
    }
  }

  // ── Device Info (live from API or DB, fallback to defaults) ─
  DeviceInfo? _deviceInfo;
  DeviceInfo get deviceInfo => _deviceInfo ?? const DeviceInfo(
    serial:'SFF-001-KLA', pondName:'Pond A',
    firmwareVersion:'v1.2.4', latestFirmware:'v1.3.0',
    wifiRssi:-61, pingMs:142,
    uptime:Duration(days:3, hours:14, minutes:22),
    hardwareStatus:{
      'Servo Feed Motor':'OK', 'Ultrasonic Depth Sensor':'OK',
      'DS3231 RTC Clock':'Synced', 'EEPROM Memory Log':'Written',
      'ESP32 WiFi Antenna':'Connected',
    },
    firmwareUpdateAvailable:true,
  );

  Future<void> refreshDeviceInfo(String serial) async {
    if (_dbOnline && !_usingPostgres) {
      final data = await ApiService.instance.getDevice(serial);
      if (data != null) {
        _deviceInfo = DeviceInfo(
          serial:                  data['serial'] as String,
          pondName:                data['pond_name'] as String,
          firmwareVersion:         data['firmware_version'] as String,
          latestFirmware:          data['latest_firmware'] as String,
          wifiRssi:                (data['wifi_rssi'] as num).toDouble(),
          pingMs:                  data['ping_ms'] as int,
          uptime:                  Duration(seconds: data['uptime_seconds'] as int),
          hardwareStatus:          Map<String,String>.from(data['hardware_status'] as Map),
          firmwareUpdateAvailable: data['firmware_update_available'] as bool,
        );
        notifyListeners();
      }
    }
  }

  // ── Sync Status (live from API, fallback to defaults) ───────
  SyncStatusModel? _syncStatus;
  SyncStatusModel get syncStatus => _syncStatus ?? SyncStatusModel(
    pendingUploads:0, failedRetries:0, recoveredEvents:0,
    lastSyncTime:DateTime.now().subtract(const Duration(minutes:4)),
    eepromHealthy:true, eepromUsedBytes:0, eepromTotalBytes:4096,
  );

  Future<void> refreshSyncStatus() async {
    if (_dbOnline && !_usingPostgres) {
      final data = await ApiService.instance.getSyncStatus();
      if (data != null) {
        _syncStatus = SyncStatusModel(
          pendingUploads:  data['pending_uploads'] as int,
          failedRetries:   data['failed_retries'] as int,
          recoveredEvents: data['recovered_events'] as int,
          lastSyncTime:    DateTime.parse(data['last_sync_time'] as String),
          eepromHealthy:   data['eeprom_healthy'] as bool,
          eepromUsedBytes: data['eeprom_used_bytes'] as int,
          eepromTotalBytes:data['eeprom_total_bytes'] as int,
        );
        notifyListeners();
      }
    }
  }

  // ── Firmware ───────────────────────────────────────────────
  String _firmwareState = 'idle';
  String get firmwareState => _firmwareState;

  Future<void> triggerFirmwareUpdate() async {
    if (_firmwareState != 'idle') return;
    _firmwareState = 'updating'; notifyListeners();
    await ApiService.instance.sendFirmwareUpdate('SFF-001-KLA');
    await Future.delayed(const Duration(seconds: 3));
    _firmwareState = 'updated'; notifyListeners();
  }

  void resetFirmwareState() { _firmwareState = 'idle'; notifyListeners(); }

  // ── Cooldown ───────────────────────────────────────────────
  bool _cooldownActive = false;
  int  _cooldownMins   = 0;
  bool get cooldownActive => _cooldownActive;
  int  get cooldownRemainingMinutes => _cooldownMins;

  void activateCooldown(int minutes) {
    _cooldownActive = true;
    _cooldownMins   = minutes;
    notifyListeners();
  }

  void overrideCooldown() { _cooldownActive = false; _cooldownMins = 0; notifyListeners(); }

  // ── Onboarding ────────────────────────────────────────────
  bool _onboardingDone = false;
  bool get onboardingDone => _onboardingDone;
  void completeOnboarding() { _onboardingDone = true; notifyListeners(); }

  // ── Remote refresh (REST API path) ─────────────────────────
  Future<void> refreshFromApi() async {
    final alive = await ApiService.instance.ping();
    _dbOnline = alive;
    if (alive) {
      final pondsData = await ApiService.instance.getPonds();
      if (pondsData != null && pondsData.isNotEmpty) {
        _ponds = pondsData.map((d) => PondModel(
          id:           d['id'] as int,
          name:         d['name'] as String,
          feederSerial: d['feeder_serial'] as String,
          foodPercent:  (d['food_percent'] as num).toDouble(),
          nextFeedTime: d['next_feed_time'] as String? ?? 'Offline',
          waterTemp:    (d['water_temp'] as num? ?? 0).toDouble(),
          isOnline:     d['is_online'] as bool? ?? false,
          lastSeen:     DateTime.tryParse(d['last_seen'] as String? ?? '') ?? DateTime.now(),
        )).toList();
        final pondA = _ponds.firstWhere(
            (p) => p.name == 'Pond A', orElse: () => _ponds.first);
        _hopperLevel = pondA.foodPercent;
      }

      final schedulesData = await ApiService.instance.getSchedules();
      if (schedulesData != null && schedulesData.isNotEmpty) {
        _schedules = schedulesData.map((d) {
          return FeedSchedule(
            id:              d['id'] as String,
            pondName:        d['pond'] as String? ?? d['pond_name'] as String? ?? '',
            time:            TimeOfDay(hour: d['hour'] as int, minute: d['minute'] as int),
            durationSeconds: d['duration_seconds'] as int,
            portionGrams:    (d['portion_grams'] as num).toDouble(),
            isEnabled:       d['is_enabled'] as bool,
            weekdays:        List<bool>.from(d['weekdays'] as List? ?? List.filled(7, true)),
          );
        }).toList();
      }

      final logsData = await ApiService.instance.getFeedLogs(limit: 30);
      if (logsData != null && logsData.isNotEmpty) {
        _feedLogs = logsData.map((d) => FeedLog(
          id:           d['id'] as String,
          pondName:     d['pond_name'] as String,
          timestamp:    DateTime.tryParse(d['timestamp'] as String? ?? '') ?? DateTime.now(),
          portionGrams: (d['portion_grams'] as num).toDouble(),
          trigger:      d['trigger_type'] as String? ?? 'scheduled',
          synced:       d['synced'] as bool? ?? true,
        )).toList();
      }

      await refreshSyncStatus();
    }
    notifyListeners();
  }
}
