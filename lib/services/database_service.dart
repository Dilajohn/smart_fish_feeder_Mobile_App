import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class DatabaseService {
  // Database credentials and settings keys
  static const String _keyHost = 'pg_db_host';
  static const String _keyPort = 'pg_db_port';
  static const String _keyDbName = 'pg_db_name';
  static const String _keyUser = 'pg_db_user';
  static const String _keyPassword = 'pg_db_password';
  static const String _keyUsePg = 'pg_db_use_pg';

  String host = '10.0.2.2'; // Default: Android loopback to host localhost
  int port = 5432;
  String dbName = 'smart_fish_feeder';
  String username = 'postgres';
  String password = '';
  bool usePostgres = false;

  Connection? _connection;

  // Obfuscation helper to secure password in local storage
  String _obfuscate(String input) {
    return base64Encode(utf8.encode(input));
  }

  String _deobfuscate(String input) {
    if (input.isEmpty) return '';
    try {
      return utf8.decode(base64Decode(input));
    } catch (e) {
      return input;
    }
  }

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    host = prefs.getString(_keyHost) ?? '10.0.2.2';
    port = prefs.getInt(_keyPort) ?? 5432;
    dbName = prefs.getString(_keyDbName) ?? 'smart_fish_feeder';
    username = prefs.getString(_keyUser) ?? 'postgres';
    final savedPwd = prefs.getString(_keyPassword) ?? '';
    password = _deobfuscate(savedPwd);
    usePostgres = prefs.getBool(_keyUsePg) ?? false;
  }

  // Save settings to SharedPreferences
  Future<void> saveSettings({
    required String newHost,
    required int newPort,
    required String newDbName,
    required String newUsername,
    required String newPassword,
    required bool newUsePostgres,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHost, newHost);
    await prefs.setInt(_keyPort, newPort);
    await prefs.setString(_keyDbName, newDbName);
    await prefs.setString(_keyUser, newUsername);
    await prefs.setString(_keyPassword, _obfuscate(newPassword));
    await prefs.setBool(_keyUsePg, newUsePostgres);

    host = newHost;
    port = newPort;
    dbName = newDbName;
    username = newUsername;
    password = newPassword;
    usePostgres = newUsePostgres;

    if (_connection != null) {
      await disconnect();
    }
  }

  // Check if connection is alive
  bool get isConnected => _connection != null;

  // Establish connection to PostgreSQL
  Future<bool> connect() async {
    if (_connection != null) return true;
    if (!usePostgres) return false;

    try {
      _connection = await Connection.open(
        Endpoint(
          host: host,
          database: dbName,
          username: username,
          password: password.isEmpty ? null : password,
          port: port,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable, // Local server configuration
          connectTimeout: Duration(seconds: 4),
          queryTimeout: Duration(seconds: 4),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('PostgresSQL connection error: $e');
      _connection = null;
      return false;
    }
  }

  // Close PostgreSQL connection
  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (e) {
      debugPrint('PostgreSQL disconnect error: $e');
    } finally {
      _connection = null;
    }
  }

  // Helper method for secure database execution (parameterized queries)
  Future<Result?> _safeQuery(String sql, {Map<String, dynamic>? parameters}) async {
    final connected = await connect();
    if (!connected || _connection == null) return null;
    try {
      return await _connection!.execute(
        Sql.named(sql),
        parameters: parameters ?? {},
      );
    } catch (e) {
      debugPrint('PostgreSQL query error: $e');
      // If the connection is broken, release it
      if (e.toString().contains('closed') || e.toString().contains('socket')) {
        _connection = null;
      }
      return null;
    }
  }

  // ── Ponds Operations ───────────────────────────────────────

  Future<List<PondModel>> getPonds() async {
    final result = await _safeQuery(
      'SELECT id, name, feeder_serial, food_percent, next_feed_time, water_temp, is_online, last_seen FROM ponds ORDER BY id ASC',
    );
    if (result == null) return [];

    final List<PondModel> ponds = [];
    for (final row in result) {
      final map = row.toColumnMap();
      ponds.add(PondModel(
        id: map['id'] as int,
        name: map['name'] as String,
        feederSerial: map['feeder_serial'] as String,
        foodPercent: (map['food_percent'] as int).toDouble(),
        nextFeedTime: map['next_feed_time'] as String? ?? 'Offline',
        waterTemp: (map['water_temp'] as num).toDouble(),
        isOnline: map['is_online'] as bool,
        lastSeen: map['last_seen'] as DateTime,
      ));
    }
    return ponds;
  }

  Future<bool> addPond(PondModel pond) async {
    final result = await _safeQuery(
      'INSERT INTO ponds (name, feeder_serial, food_percent, next_feed_time, water_temp, is_online, last_seen) '
      'VALUES (:name, :feederSerial, :foodPercent, :nextFeedTime, :waterTemp, :isOnline, :lastSeen) '
      'ON CONFLICT (name) DO NOTHING',
      parameters: {
        'name': pond.name,
        'feederSerial': pond.feederSerial,
        'foodPercent': pond.foodPercent.toInt(),
        'nextFeedTime': pond.nextFeedTime,
        'waterTemp': pond.waterTemp,
        'isOnline': pond.isOnline,
        'lastSeen': pond.lastSeen,
      },
    );
    return result != null;
  }

  Future<bool> updatePondHopperLevel(String pondName, double level) async {
    final result = await _safeQuery(
      'UPDATE ponds SET food_percent = :level WHERE name = :name',
      parameters: {
        'level': level.toInt(),
        'name': pondName,
      },
    );
    return result != null;
  }

  // ── Schedules Operations ───────────────────────────────────

  Future<List<FeedSchedule>> getSchedules() async {
    final result = await _safeQuery(
      'SELECT id, pond_name, hour, minute, duration_seconds, portion_grams, is_enabled, weekdays FROM feed_schedules ORDER BY hour, minute ASC',
    );
    if (result == null) return [];

    final List<FeedSchedule> schedules = [];
    for (final row in result) {
      final map = row.toColumnMap();
      
      // Parse array of booleans safely
      final List<dynamic> pgWeekdays = map['weekdays'] as List<dynamic>? ?? [];
      final List<bool> weekdays = pgWeekdays.map((e) => e as bool).toList();

      schedules.add(FeedSchedule(
        id: map['id'] as String,
        pondName: map['pond_name'] as String,
        time: TimeOfDay(hour: map['hour'] as int, minute: map['minute'] as int),
        durationSeconds: map['duration_seconds'] as int,
        portionGrams: (map['portion_grams'] as int).toDouble(),
        isEnabled: map['is_enabled'] as bool,
        weekdays: weekdays.length == 7 ? weekdays : List.filled(7, true),
      ));
    }
    return schedules;
  }

  Future<bool> addSchedule(FeedSchedule schedule) async {
    final result = await _safeQuery(
      'INSERT INTO feed_schedules (id, pond_name, hour, minute, duration_seconds, portion_grams, is_enabled, weekdays) '
      'VALUES (:id, :pondName, :hour, :minute, :durationSeconds, :portionGrams, :isEnabled, :weekdays)',
      parameters: {
        'id': schedule.id,
        'pondName': schedule.pondName,
        'hour': schedule.time.hour,
        'minute': schedule.time.minute,
        'durationSeconds': schedule.durationSeconds,
        'portionGrams': schedule.portionGrams.toInt(),
        'isEnabled': schedule.isEnabled,
        'weekdays': schedule.weekdays,
      },
    );
    return result != null;
  }

  Future<bool> toggleSchedule(String id, bool isEnabled) async {
    final result = await _safeQuery(
      'UPDATE feed_schedules SET is_enabled = :isEnabled WHERE id = :id',
      parameters: {
        'isEnabled': isEnabled,
        'id': id,
      },
    );
    return result != null;
  }

  // ── Feed Logs Operations ───────────────────────────────────

  Future<List<FeedLog>> getFeedLogs() async {
    final result = await _safeQuery(
      'SELECT id, pond_name, timestamp, portion_grams, trigger_type, synced FROM feed_logs ORDER BY timestamp DESC LIMIT 30',
    );
    if (result == null) return [];

    final List<FeedLog> logs = [];
    for (final row in result) {
      final map = row.toColumnMap();
      logs.add(FeedLog(
        id: map['id'] as String,
        pondName: map['pond_name'] as String,
        timestamp: map['timestamp'] as DateTime,
        portionGrams: (map['portion_grams'] as num).toDouble(),
        trigger: map['trigger_type'] as String,
        synced: map['synced'] as bool,
      ));
    }
    return logs;
  }

  Future<bool> addFeedLog(FeedLog log) async {
    final result = await _safeQuery(
      'INSERT INTO feed_logs (id, pond_name, timestamp, portion_grams, trigger_type, synced) '
      'VALUES (:id, :pondName, :timestamp, :portionGrams, :trigger, :synced)',
      parameters: {
        'id': log.id,
        'pondName': log.pondName,
        'timestamp': log.timestamp,
        'portionGrams': log.portionGrams,
        'trigger': log.trigger,
        'synced': log.synced,
      },
    );
    return result != null;
  }

  // ── Device Info Operations ─────────────────────────────────

  Future<DeviceInfo?> getDeviceInfo(String serial) async {
    final result = await _safeQuery(
      'SELECT serial, pond_name, firmware_version, latest_firmware, wifi_rssi, ping_ms, uptime_seconds, hardware_status, firmware_update_available '
      'FROM device_info WHERE serial = :serial',
      parameters: {'serial': serial},
    );
    if (result == null || result.isEmpty) return null;

    final map = result.first.toColumnMap();
    final Map<String, dynamic> rawStatus = map['hardware_status'] as Map<String, dynamic>? ?? {};
    final Map<String, String> hardwareStatus = rawStatus.map((key, value) => MapEntry(key, value.toString()));

    return DeviceInfo(
      serial: map['serial'] as String,
      pondName: map['pond_name'] as String,
      firmwareVersion: map['firmware_version'] as String,
      latestFirmware: map['latest_firmware'] as String,
      wifiRssi: (map['wifi_rssi'] as int).toDouble(),
      pingMs: map['ping_ms'] as int,
      uptime: Duration(seconds: map['uptime_seconds'] as int),
      hardwareStatus: hardwareStatus,
      firmwareUpdateAvailable: map['firmware_update_available'] as bool,
    );
  }

  // ── Sync Status Operations ─────────────────────────────────

  Future<SyncStatusModel?> getSyncStatus() async {
    final result = await _safeQuery(
      'SELECT pending_uploads, failed_retries, recovered_events, last_sync_time, eeprom_healthy, eeprom_used_bytes, eeprom_total_bytes '
      'FROM sync_status LIMIT 1',
    );
    if (result == null || result.isEmpty) return null;

    final map = result.first.toColumnMap();
    return SyncStatusModel(
      pendingUploads: map['pending_uploads'] as int,
      failedRetries: map['failed_retries'] as int,
      recoveredEvents: map['recovered_events'] as int,
      lastSyncTime: map['last_sync_time'] as DateTime,
      eepromHealthy: map['eeprom_healthy'] as bool,
      eepromUsedBytes: map['eeprom_used_bytes'] as int,
      eepromTotalBytes: map['eeprom_total_bytes'] as int,
    );
  }
}
