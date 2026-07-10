import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const String _keyBase = 'api_base_url';
  static const String _keyToken = 'api_token';

  String baseUrl = 'http://127.0.0.1:8001'; // default to local Django backend for web/dev
  String? token; // device/app token (loaded from SharedPreferences via loadSettings)

  Map<String, String> _defaultHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString(_keyBase) ?? baseUrl;
    token = prefs.getString(_keyToken) ?? token;
  }

  Future<void> saveSettings({required String base, String? apiToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBase, base);
    if (apiToken != null) await prefs.setString(_keyToken, apiToken);
    baseUrl = base;
    token = apiToken ?? token;
  }

  Uri _uri(String path) => Uri.parse(baseUrl + path);

  Future<List<PondModel>> getPonds() async {
    try {
      final r = await http.get(_uri('/api/ponds/'), headers: _defaultHeaders()).timeout(Duration(seconds: 5));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as List<dynamic>;
      final List<PondModel> ponds = [];
      for (var i = 0; i < data.length; i++) {
        final item = data[i] as Map<String, dynamic>;
        final hopper = (item['hopper_percent'] ?? item['food_percent'] ?? 0).toDouble();
        ponds.add(PondModel(
          id: i + 1,
          name: item['name']?.toString() ?? 'Pond ${i + 1}',
          feederSerial: item['serial']?.toString() ?? item['feeder_serial']?.toString() ?? 'unknown',
          foodPercent: hopper,
          nextFeedTime: item['next_feed_time']?.toString() ?? 'Offline',
          waterTemp: (item['water_temp'] ?? 0).toDouble(),
          isOnline: true,
          lastSeen: DateTime.now(),
        ));
      }
      return ponds;
    } catch (e) {
      debugPrint('ApiService getPonds error: $e');
      return [];
    }
  }

  Future<List<FeedSchedule>> getSchedules() async {
    try {
      final r = await http.get(_uri('/api/schedules/'), headers: _defaultHeaders()).timeout(Duration(seconds: 5));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as List<dynamic>;
      final List<FeedSchedule> schedules = [];
      for (final item in data) {
        final m = item as Map<String, dynamic>;
        // Expect time like '08:00' or '08:00:00'
        String timeStr = (m['time'] ?? '00:00').toString();
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        schedules.add(FeedSchedule(
          id: m['id']?.toString() ?? UniqueKey().toString(),
          pondName: m['pond']?.toString() ?? m['pond_id']?.toString() ?? 'Unknown',
          time: TimeOfDay(hour: hour, minute: minute),
          durationSeconds: m['duration_seconds'] ?? 0,
          portionGrams: (m['amount_grams'] ?? m['portion_grams'] ?? 0).toDouble(),
          isEnabled: m['is_enabled'] ?? true,
          weekdays: List.filled(7, true),
        ));
      }
      return schedules;
    } catch (e) {
      debugPrint('ApiService getSchedules error: $e');
      return [];
    }
  }

  Future<List<FeedLog>> getFeedLogs() async {
    try {
      final r = await http.get(_uri('/api/feed-logs/'), headers: _defaultHeaders()).timeout(Duration(seconds: 5));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as List<dynamic>;
      final List<FeedLog> logs = [];
      for (final item in data) {
        final m = item as Map<String, dynamic>;
        logs.add(FeedLog(
          id: m['id']?.toString() ?? UniqueKey().toString(),
          pondName: m['pond']?.toString() ?? m['pond_name']?.toString() ?? 'Unknown',
          timestamp: DateTime.parse(m['timestamp'] ?? DateTime.now().toIso8601String()),
          portionGrams: (m['amount_grams'] ?? m['portion_grams'] ?? 0).toDouble(),
          trigger: 'manual',
          synced: true,
        ));
      }
      return logs;
    } catch (e) {
      debugPrint('ApiService getFeedLogs error: $e');
      return [];
    }
  }

  Future<bool> addPond(PondModel pond) async {
    try {
      final body = jsonEncode({
        'id': pond.name.toLowerCase().replaceAll(' ', '_'),
        'name': pond.name,
        'serial': pond.feederSerial,
        'hopper_percent': pond.foodPercent,
      });
      final r = await http.post(_uri('/api/ponds/'), headers: _defaultHeaders(), body: body).timeout(Duration(seconds: 5));
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService addPond error: $e');
      return false;
    }
  }

  Future<bool> addSchedule(FeedSchedule schedule) async {
    try {
      final body = jsonEncode({
        'id': schedule.id,
        'pond': schedule.pondName,
        'time': '${schedule.time.hour.toString().padLeft(2,'0')}:${schedule.time.minute.toString().padLeft(2,'0')}',
        'amount_grams': schedule.portionGrams,
        'is_enabled': schedule.isEnabled,
      });
      final r = await http.post(_uri('/api/schedules/'), headers: _defaultHeaders(), body: body).timeout(Duration(seconds: 5));
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService addSchedule error: $e');
      return false;
    }
  }

  Future<bool> addFeedLog(FeedLog log) async {
    try {
      final body = jsonEncode({
        'id': log.id,
        'pond': log.pondName,
        'serial': '',
        'amount_grams': log.portionGrams,
        'timestamp': log.timestamp.toIso8601String(),
      });
      final r = await http.post(_uri('/api/feed-logs/'), headers: _defaultHeaders(), body: body).timeout(Duration(seconds: 5));
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService addFeedLog error: $e');
      return false;
    }
  }

  Future<bool> updatePondHopperLevelBySerial(String serial, double level) async {
    try {
      final body = jsonEncode({'serial': serial, 'hopper_percent': level});
      final r = await http.post(_uri('/api/telemetry/'), headers: _defaultHeaders(), body: body).timeout(Duration(seconds: 5));
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService updatePondHopperLevel error: $e');
      return false;
    }
  }

  Future<bool> triggerFeed(String pondId, {double? amount}) async {
    try {
      final body = jsonEncode({'amount_grams': amount});
      final r = await http.post(_uri('/api/ponds/$pondId/trigger-feed/'), headers: _defaultHeaders(), body: body).timeout(Duration(seconds: 5));
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService triggerFeed error: $e');
      return false;
    }
  }
}
