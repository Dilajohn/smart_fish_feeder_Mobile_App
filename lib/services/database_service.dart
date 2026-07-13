import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Direct PostgreSQL client — optional alternative to the REST API.
/// Enable via the DB Settings screen (usePostgres = true).
class DatabaseService {
  // SharedPreferences keys
  static const String _keyHost     = 'pg_db_host';
  static const String _keyPort     = 'pg_db_port';
  static const String _keyDbName   = 'pg_db_name';
  static const String _keyUser     = 'pg_db_user';
  static const String _keyPassword = 'pg_db_password';
  static const String _keyUsePg    = 'pg_db_use_pg';

  String host       = '10.0.2.2'; // Android emulator loopback to host localhost
  int    port       = 5432;
  String dbName     = 'smart_fish_feeder';
  String username   = 'postgres';
  String password   = '';
  bool   usePostgres = false;

  Connection? _connection;

  // ── Password obfuscation (base64 — not encryption, just avoids plain-text) ──
  String _obfuscate(String input) => base64Encode(utf8.encode(input));

  String _deobfuscate(String input) {
    if (input.isEmpty) return '';
    try { return utf8.decode(base64Decode(input)); } catch (_) { return input; }
  }

  // ── Persist / restore settings ─────────────────────────────
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    host       = prefs.getString(_keyHost)    ?? '10.0.2.2';
    port       = prefs.getInt(_keyPort)       ?? 5432;
    dbName     = prefs.getString(_keyDbName)  ?? 'smart_fish_feeder';
    username   = prefs.getString(_keyUser)    ?? 'postgres';
    password   = _deobfuscate(prefs.getString(_keyPassword) ?? '');
    usePostgres= prefs.getBool(_keyUsePg)     ?? false;
  }

  Future<void> saveSettings({
    required String newHost,
    required int    newPort,
    required String newDbName,
    required String newUsername,
    required String newPassword,
    required bool   newUsePostgres,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHost,     newHost);
    await prefs.setInt(_keyPort,        newPort);
    await prefs.setString(_keyDbName,   newDbName);
    await prefs.setString(_keyUser,     newUsername);
    await prefs.setString(_keyPassword, _obfuscate(newPassword));
    await prefs.setBool(_keyUsePg,      newUsePostgres);

    host        = newHost;
    port        = newPort;
    dbName      = newDbName;
    username    = newUsername;
    password    = newPassword;
    usePostgres = newUsePostgres;

    if (_connection != null) await disconnect();
  }

  // ── Connection lifecycle ────────────────────────────────────
  bool get isConnected => _connection != null;

  Future<bool> connect() async {
    if (_connection != null) return true;
    if (!usePostgres) return false;
    try {
      _connection = await Connection.open(
        Endpoint(
          host: host, database: dbName, username: username,
          password: password.isEmpty ? null : password, port: port,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
          connectTimeout: Duration(seconds: 4),
          queryTimeout:   Duration(seconds: 4),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('PostgreSQL connection error: $e');
      _connection = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    try { await _connection?.close(); } catch (_) {} finally { _connection = null; }
  }

  // ── Safe parameterised query helper ───────────────────────
  Future<Result?> _safeQuery(String sql, {Map<String, dynamic>? parameters}) async {
    final connected = await connect();
    if (!connected || _connection == null) return null;
    try {
      return await _connection!.execute(Sql.named(sql), parameters: parameters ?? {});
    } catch (e) {
      debugPrint('PostgreSQL query error: $e');
      if (e.toString().contains('closed') || e.toString().contains('socket')) {
        _connection = null;
      }
      return null;
    }
  }

  // ── Ponds ──────────────────────────────────────────────────
  Future<List<PondModel>> getPonds() async {
    final result = await _safeQuery(
      'SELECT id, name, feeder_serial, food_percent, next_feed_time, '
      'water_temp, is_online, last_seen FROM ponds ORDER BY id ASC',
    );
    if (result == null) return [];
    return result.map((row) {
      final m = row.toColumnMap();
      return PondModel(
        id:           m['id'] as int,
        name:         m['name'] as String,
        feederSerial: m['feeder_serial'] as String,
        foodPercent:  (m['food_percent'] as num).toDouble(),
        nextFeedTime: m['next_feed_time'] as String? ?? 'Offline',
        waterTemp:    (m['water_temp'] as num).toDouble(),
        isOnline:     m['is_online'] as bool,
        lastSeen:     m['last_seen'] as DateTime,
      );
    }).toList();
  }

  Future<bool> addPond(PondModel pond) async {
    final result = await _safeQuery(
      'INSERT INTO ponds (name, feeder_serial, food_percent, next_feed_time, '
      'water_temp, is_online, last_seen) '
      'VALUES (:name, :feederSerial, :foodPercent, :nextFeedTime, :waterTemp, :isOnline, :lastSeen) '
      'ON CONFLICT (name) DO NOTHING',
      parameters: {
        'name': pond.name, 'feederSerial': pond.feederSerial,
        'foodPercent': pond.foodPercent.toInt(), 'nextFeedTime': pond.nextFeedTime,
        'waterTemp': pond.waterTemp, 'isOnline': pond.isOnline, 'lastSeen': pond.lastSeen,
      },
    );
    return result != null;
  }

  Future<bool> updatePondHopperLevel(String pondName, double level) async {
    final result = await _safeQuery(
      'UPDATE ponds SET food_percent = :level WHERE name = :name',
      parameters: {'level': level.toInt(), 'name': pondName},
    );
    return result != null;
  }

  // ── Schedules ──────────────────────────────────────────────
  Future<List<FeedSchedule>> getSchedules() async {
    final result = await _safeQuery(
      'SELECT id, pond_name, hour, minute, duration_seconds, portion_grams, '
      'is_enabled, weekdays FROM feed_schedules ORDER BY hour, minute ASC',
    );
    if (result == null) return [];
    return result.map((row) {
      final m = row.toColumnMap();
      final pgWeekdays = m['weekdays'] as List<dynamic>? ?? [];
      final weekdays   = pgWeekdays.map((e) => e as bool).toList();
      return FeedSchedule(
        id:              m['id'] as String,
        pondName:        m['pond_name'] as String,
        time:            TimeOfDay(hour: m['hour'] as int, minute: m['minute'] as int),
        durationSeconds: m['duration_seconds'] as int,
        portionGrams:    (m['portion_grams'] as num).toDouble(),
        isEnabled:       m['is_enabled'] as bool,
        weekdays:        weekdays.length == 7 ? weekdays : List.filled(7, true),
      );
    }).toList();
  }

  Future<bool> addSchedule(FeedSchedule schedule) async {
    final result = await _safeQuery(
      'INSERT INTO feed_schedules '
      '(id, pond_name, hour, minute, duration_seconds, portion_grams, is_enabled, weekdays) '
      'VALUES (:id, :pondName, :hour, :minute, :durationSeconds, :portionGrams, :isEnabled, :weekdays)',
      parameters: {
        'id': schedule.id, 'pondName': schedule.pondName,
        'hour': schedule.time.hour, 'minute': schedule.time.minute,
        'durationSeconds': schedule.durationSeconds,
        'portionGrams': schedule.portionGrams.toInt(),
        'isEnabled': schedule.isEnabled, 'weekdays': schedule.weekdays,
      },
    );
    return result != null;
  }

  Future<bool> toggleSchedule(String id, bool isEnabled) async {
    final result = await _safeQuery(
      'UPDATE feed_schedules SET is_enabled = :isEnabled WHERE id = :id',
      parameters: {'isEnabled': isEnabled, 'id': id},
    );
    return result != null;
  }

  Future<bool> deleteSchedule(String id) async {
    final result = await _safeQuery(
      'DELETE FROM feed_schedules WHERE id = :id',
      parameters: {'id': id},
    );
    return result != null;
  }

  // ── Feed Logs ──────────────────────────────────────────────
  Future<List<FeedLog>> getFeedLogs() async {
    final result = await _safeQuery(
      'SELECT id, pond_name, timestamp, portion_grams, trigger_type, synced '
      'FROM feed_logs ORDER BY timestamp DESC LIMIT 30',
    );
    if (result == null) return [];
    return result.map((row) {
      final m = row.toColumnMap();
      return FeedLog(
        id:           m['id'] as String,
        pondName:     m['pond_name'] as String,
        timestamp:    m['timestamp'] as DateTime,
        portionGrams: (m['portion_grams'] as num).toDouble(),
        trigger:      m['trigger_type'] as String,
        synced:       m['synced'] as bool,
      );
    }).toList();
  }

  Future<bool> addFeedLog(FeedLog log) async {
    final result = await _safeQuery(
      'INSERT INTO feed_logs (id, pond_name, timestamp, portion_grams, trigger_type, synced) '
      'VALUES (:id, :pondName, :timestamp, :portionGrams, :trigger, :synced)',
      parameters: {
        'id': log.id, 'pondName': log.pondName, 'timestamp': log.timestamp,
        'portionGrams': log.portionGrams, 'trigger': log.trigger, 'synced': log.synced,
      },
    );
    return result != null;
  }

  // ── Device Info ────────────────────────────────────────────
  Future<DeviceInfo?> getDeviceInfo(String serial) async {
    final result = await _safeQuery(
      'SELECT serial, pond_name, firmware_version, latest_firmware, wifi_rssi, '
      'ping_ms, uptime_seconds, hardware_status, firmware_update_available '
      'FROM device_info WHERE serial = :serial',
      parameters: {'serial': serial},
    );
    if (result == null || result.isEmpty) return null;
    final m = result.first.toColumnMap();
    final rawStatus = m['hardware_status'] as Map<String, dynamic>? ?? {};
    final hardwareStatus = rawStatus.map((k, v) => MapEntry(k, v.toString()));
    return DeviceInfo(
      serial:                  m['serial'] as String,
      pondName:                m['pond_name'] as String,
      firmwareVersion:         m['firmware_version'] as String,
      latestFirmware:          m['latest_firmware'] as String,
      wifiRssi:                (m['wifi_rssi'] as num).toDouble(),
      pingMs:                  m['ping_ms'] as int,
      uptime:                  Duration(seconds: m['uptime_seconds'] as int),
      hardwareStatus:          hardwareStatus,
      firmwareUpdateAvailable: m['firmware_update_available'] as bool,
    );
  }

  // ── Sync Status ────────────────────────────────────────────
  Future<SyncStatusModel?> getSyncStatus() async {
    final result = await _safeQuery(
      'SELECT pending_uploads, failed_retries, recovered_events, last_sync_time, '
      'eeprom_healthy, eeprom_used_bytes, eeprom_total_bytes FROM sync_status LIMIT 1',
    );
    if (result == null || result.isEmpty) return null;
    final m = result.first.toColumnMap();
    return SyncStatusModel(
      pendingUploads:  m['pending_uploads'] as int,
      failedRetries:   m['failed_retries'] as int,
      recoveredEvents: m['recovered_events'] as int,
      lastSyncTime:    m['last_sync_time'] as DateTime,
      eepromHealthy:   m['eeprom_healthy'] as bool,
      eepromUsedBytes: m['eeprom_used_bytes'] as int,
      eepromTotalBytes:m['eeprom_total_bytes'] as int,
    );
  }
}
