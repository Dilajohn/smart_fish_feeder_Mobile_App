// ============================================================
// Smart Fish Feeder — Django REST API Service
// Handles all HTTP communication with the backend.
// Falls back gracefully when server is unreachable.
// ============================================================
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  // ── Base URL (override in Settings) ──────────────────────
  static const String _defaultBase = 'http://10.0.2.2:8000/api/v1';
  String _baseUrl = _defaultBase;
  String? _token;
  bool _isOnline = false;

  String  get baseUrl => _baseUrl;
  bool    get isOnline => _isOnline;
  String? get token    => _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url') ?? _defaultBase;
    _token   = prefs.getString('auth_token');
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  /// Called by ApiSettingsScreen to persist both URL and token at once.
  Future<void> saveSettings({required String base, String? apiToken}) async {
    _baseUrl = base;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', base);
    if (apiToken != null && apiToken.isNotEmpty) {
      _token = apiToken;
      await prefs.setString('auth_token', apiToken);
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  // ── Auth ───────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login/'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _token = data['token'] as String?;
        _isOnline = true;
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString('auth_token', _token!);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('API login error: $e');
      _isOnline = false;
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await http.post(Uri.parse('$_baseUrl/auth/logout/'), headers: _headers)
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
    _token = null;
    _isOnline = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ── Generic helpers ────────────────────────────────────────
  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      _isOnline = true;
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('GET $path error: $e'); _isOnline = false; }
    return null;
  }

  Future<List<dynamic>?> _getList(String path) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      _isOnline = true;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List<dynamic>) return decoded;
        if (decoded is Map<String, dynamic> && decoded['results'] is List<dynamic>) {
          return decoded['results'] as List<dynamic>;
        }
      }
    } catch (e) { debugPrint('GET $path error: $e'); _isOnline = false; }
    return null;
  }

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl$path'), headers: _headers, body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));
      _isOnline = true;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) return {};
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) { debugPrint('POST $path error: $e'); _isOnline = false; }
    return null;
  }

  Future<Map<String, dynamic>?> _patch(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl$path'), headers: _headers, body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));
      _isOnline = true;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) return {};
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) { debugPrint('PATCH $path error: $e'); _isOnline = false; }
    return null;
  }

  Future<bool> _delete(String path) async {
    try {
      final res = await http.delete(Uri.parse('$_baseUrl$path'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      _isOnline = true;
      return res.statusCode == 204;
    } catch (e) { debugPrint('DELETE $path error: $e'); _isOnline = false; return false; }
  }

  // ── Ping / health check ────────────────────────────────────
  Future<bool> ping() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/health/'), headers: _headers)
          .timeout(const Duration(seconds: 4));
      _isOnline = res.statusCode == 200;
      return _isOnline;
    } catch (_) { _isOnline = false; return false; }
  }

  // ── Ponds ──────────────────────────────────────────────────
  Future<List<dynamic>?> getPonds() => _getList('/ponds/');
  Future<Map<String, dynamic>?> createPond(Map<String, dynamic> data) => _post('/ponds/', data);
  Future<Map<String, dynamic>?> updatePond(int id, Map<String, dynamic> data) => _patch('/ponds/$id/', data);

  // ── Schedules ──────────────────────────────────────────────
  Future<List<dynamic>?> getSchedules({String? pondName}) =>
    _getList('/schedules/${pondName != null ? "?pond=$pondName" : ""}');
  Future<Map<String, dynamic>?> createSchedule(Map<String, dynamic> data) => _post('/schedules/', data);
  Future<Map<String, dynamic>?> toggleSchedule(String id, bool enabled) =>
    _patch('/schedules/$id/', {'is_enabled': enabled});
  Future<bool> deleteSchedule(String id) => _delete('/schedules/$id/');

  // ── Feed Logs ──────────────────────────────────────────────
  Future<List<dynamic>?> getFeedLogs({String? pondName, int limit = 30}) =>
    _getList('/feed-logs/?${pondName != null ? "pond=$pondName&" : ""}limit=$limit');
  Future<Map<String, dynamic>?> createFeedLog(Map<String, dynamic> data) => _post('/feed-logs/', data);

  // ── Device ─────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getDevice(String serial) => _get('/devices/$serial/');
  Future<Map<String, dynamic>?> getSyncStatus() => _get('/sync-status/');

  // ── Commands (hardware control) ────────────────────────────
  Future<Map<String, dynamic>?> sendManualFeed(String serial, {double portionGrams = 120}) =>
    _post('/devices/$serial/feed/', {'portion_grams': portionGrams});

  Future<Map<String, dynamic>?> sendFirmwareUpdate(String serial) =>
    _post('/devices/$serial/firmware-update/', {});

  Future<Map<String, dynamic>?> syncEeprom(String serial) =>
    _post('/devices/$serial/sync/', {});

  Future<Map<String, dynamic>?> getPendingCommands(String serial) =>
    _get('/devices/$serial/commands/');

  Future<Map<String, dynamic>?> ackCommand(String commandId) =>
    _post('/commands/$commandId/ack/', {});

  // ── Export ─────────────────────────────────────────────────
  Future<Map<String, dynamic>?> exportLogs({
    required String serial, required String from, required String to, required String format,
  }) => _get('/export/?serial=$serial&from=$from&to=$to&format=$format');

  // ── Telemetry (from device) ────────────────────────────────
  Future<Map<String, dynamic>?> pushTelemetry(Map<String, dynamic> data) =>
    _post('/telemetry/', data);

  // ── Public POST (unauthenticated — register, password-reset, verify-email) ──
  Future<Map<String, dynamic>?> postPublic(String path, Map<String, dynamic> body) =>
      _post(path, body);
}
