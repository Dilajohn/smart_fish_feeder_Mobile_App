import 'package:flutter/material.dart';
import '../models/models.dart';
import 'database_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseService dbService = DatabaseService();
  bool dbOnline = false;

  AppState() {
    initDatabase();
  }

  // Asynchronously initialize database connection and load dynamic data
  Future<void> initDatabase() async {
    await dbService.loadSettings();
    if (dbService.usePostgres) {
      final connected = await dbService.connect();
      if (connected) {
        dbOnline = true;
        await refreshData();
        return;
      }
    }
    dbOnline = false;
    notifyListeners();
  }

  // Refresh all state variables from the database
  Future<void> refreshData() async {
    if (!dbOnline) return;

    try {
      final dbPonds = await dbService.getPonds();
      if (dbPonds.isNotEmpty) {
        _ponds = dbPonds;
        // Keep hopper level in sync with Pond A
        final pondA = _ponds.firstWhere((p) => p.name == 'Pond A', orElse: () => _ponds.first);
        _hopperLevel = pondA.foodPercent;
      }

      final dbSchedules = await dbService.getSchedules();
      if (dbSchedules.isNotEmpty) {
        _schedules = dbSchedules;
      }

      final dbLogs = await dbService.getFeedLogs();
      if (dbLogs.isNotEmpty) {
        _feedLogs = dbLogs;
      }

      final dbDevice = await dbService.getDeviceInfo('SFF-001-KLA');
      if (dbDevice != null) {
        _deviceInfo = dbDevice;
      }

      final dbSync = await dbService.getSyncStatus();
      if (dbSync != null) {
        _syncStatus = dbSync;
      }
    } catch (e) {
      debugPrint('Error refreshing data from PostgreSQL: $e');
      dbOnline = false;
    }
    notifyListeners();
  }

  // Force database reconnect and refresh
  Future<bool> reconnectDatabase() async {
    await dbService.disconnect();
    final connected = await dbService.connect();
    dbOnline = connected;
    if (connected) {
      await refreshData();
    } else {
      notifyListeners();
    }
    return connected;
  }

  // ── Ponds ──────────────────────────────────────────────────
  List<PondModel> _ponds = [
    PondModel(
      id: 1,
      name: 'Pond A',
      feederSerial: 'SFF-001-KLA',
      foodPercent: 67,
      nextFeedTime: '12:00 PM',
      waterTemp: 24.0,
      isOnline: true,
      lastSeen: DateTime.now().subtract(const Duration(seconds: 30)),
    ),
    PondModel(
      id: 2,
      name: 'Pond B',
      feederSerial: 'SFF-002-KLA',
      foodPercent: 0,
      nextFeedTime: 'Offline',
      waterTemp: 0,
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    PondModel(
      id: 3,
      name: 'Pond C',
      feederSerial: 'SFF-003-KLA',
      foodPercent: 19,
      nextFeedTime: '5:00 PM',
      waterTemp: 23.0,
      isOnline: true,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  List<PondModel> get ponds => _ponds;

  bool get hasOfflinePond => _ponds.any((p) => !p.isOnline);
  bool get hasCriticalFood => _ponds.any((p) => p.isOnline && p.isFoodLow);

  Future<void> addPond(PondModel pond) async {
    if (dbOnline) {
      final success = await dbService.addPond(pond);
      if (!success) return;
    }
    _ponds = [..._ponds, pond];
    notifyListeners();
  }

  // ── Schedules ──────────────────────────────────────────────
  List<FeedSchedule> _schedules = [
    const FeedSchedule(
      id: 'sch-001',
      pondName: 'Pond A',
      time: TimeOfDay(hour: 6, minute: 0),
      durationSeconds: 8,
      portionGrams: 120,
      isEnabled: true,
      weekdays: [true, true, true, true, true, true, true],
    ),
    const FeedSchedule(
      id: 'sch-002',
      pondName: 'Pond A',
      time: TimeOfDay(hour: 12, minute: 0),
      durationSeconds: 10,
      portionGrams: 150,
      isEnabled: true,
      weekdays: [true, true, true, true, true, true, true],
    ),
    const FeedSchedule(
      id: 'sch-003',
      pondName: 'Pond A',
      time: TimeOfDay(hour: 17, minute: 0),
      durationSeconds: 8,
      portionGrams: 120,
      isEnabled: false,
      weekdays: [true, true, true, true, true, false, false],
    ),
    const FeedSchedule(
      id: 'sch-004',
      pondName: 'Pond C',
      time: TimeOfDay(hour: 17, minute: 0),
      durationSeconds: 6,
      portionGrams: 90,
      isEnabled: true,
      weekdays: [true, true, true, true, true, true, true],
    ),
  ];

  List<FeedSchedule> get schedules => _schedules;

  Future<void> toggleSchedule(String id) async {
    bool? newStatus;
    _schedules = _schedules.map((s) {
      if (s.id == id) {
        newStatus = !s.isEnabled;
        return s.copyWith(isEnabled: newStatus);
      }
      return s;
    }).toList();

    if (dbOnline && newStatus != null) {
      await dbService.toggleSchedule(id, newStatus!);
    }
    notifyListeners();
  }

  Future<void> addSchedule(FeedSchedule schedule) async {
    if (dbOnline) {
      final success = await dbService.addSchedule(schedule);
      if (!success) return;
    }
    _schedules = [..._schedules, schedule];
    notifyListeners();
  }

  // ── Feed Logs ──────────────────────────────────────────────
  List<FeedLog> _feedLogs = [
    FeedLog(id: 'log-1', pondName: 'Pond A', timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)), portionGrams: 120, trigger: 'scheduled', synced: true),
    FeedLog(id: 'log-2', pondName: 'Pond A', timestamp: DateTime.now().subtract(const Duration(hours: 7)), portionGrams: 150, trigger: 'scheduled', synced: true),
    FeedLog(id: 'log-3', pondName: 'Pond C', timestamp: DateTime.now().subtract(const Duration(hours: 2)), portionGrams: 90, trigger: 'manual', synced: true),
    FeedLog(id: 'log-4', pondName: 'Pond A', timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)), portionGrams: 120, trigger: 'scheduled', synced: false),
    FeedLog(id: 'log-5', pondName: 'Pond C', timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)), portionGrams: 90, trigger: 'scheduled', synced: true),
  ];

  List<FeedLog> get feedLogs => _feedLogs;

  Future<void> addFeedLog(FeedLog log) async {
    if (dbOnline) {
      await dbService.addFeedLog(log);
    }
    _feedLogs = [log, ..._feedLogs];
    notifyListeners();
  }

  // ── Device Info ────────────────────────────────────────────
  DeviceInfo? _deviceInfo;
  DeviceInfo get deviceInfo => _deviceInfo ?? const DeviceInfo(
        serial: 'SFF-001-KLA',
        pondName: 'Pond A',
        firmwareVersion: 'v1.2.4',
        latestFirmware: 'v1.3.0',
        wifiRssi: -61,
        pingMs: 142,
        uptime: Duration(days: 3, hours: 14, minutes: 22),
        hardwareStatus: {
          'Servo Feed Motor': 'OK',
          'Ultrasonic Depth Sensor': 'OK',
          'DS3231 RTC Clock': 'Synced',
          'EEPROM Memory Log': 'Written',
          'ESP8266 WiFi Antenna': 'Connected',
        },
        firmwareUpdateAvailable: true,
      );

  // ── Sync Status ───────────────────────────────────────────
  SyncStatusModel? _syncStatus;
  SyncStatusModel get syncStatus => _syncStatus ?? SyncStatusModel(
        pendingUploads: 3,
        failedRetries: 1,
        recoveredEvents: 2,
        lastSyncTime: DateTime.now().subtract(const Duration(minutes: 4)),
        eepromHealthy: true,
        eepromUsedBytes: 3071,
        eepromTotalBytes: 4096,
      );

  // ── Hopper level (for refill prediction) ─────────────────
  double _hopperLevel = 67.0;
  double get hopperLevel => _hopperLevel;

  Future<void> setHopperLevel(double value) async {
    _hopperLevel = value;
    // Keep local pond percent in sync
    _ponds = _ponds.map((p) {
      if (p.name == 'Pond A') {
        return p.copyWith(foodPercent: value);
      }
      return p;
    }).toList();

    if (dbOnline) {
      await dbService.updatePondHopperLevel('Pond A', value);
    }
    notifyListeners();
  }

  // ── Firmware update state ─────────────────────────────────
  String _firmwareState = 'idle'; // idle | updating | updated
  String get firmwareState => _firmwareState;

  Future<void> triggerFirmwareUpdate() async {
    if (_firmwareState != 'idle') return;
    _firmwareState = 'updating';
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));
    _firmwareState = 'updated';
    notifyListeners();
  }

  void resetFirmwareState() {
    _firmwareState = 'idle';
    notifyListeners();
  }

  // ── Cooldown lock ─────────────────────────────────────────
  bool _cooldownActive = true;
  int _cooldownRemainingMinutes = 22;
  bool get cooldownActive => _cooldownActive;
  int get cooldownRemainingMinutes => _cooldownRemainingMinutes;

  void overrideCooldown() {
    _cooldownActive = false;
    _cooldownRemainingMinutes = 0;
    notifyListeners();
  }

  // ── Onboarding ────────────────────────────────────────────
  bool _onboardingDone = false;
  bool get onboardingDone => _onboardingDone;

  void completeOnboarding() {
    _onboardingDone = true;
    notifyListeners();
  }
}
