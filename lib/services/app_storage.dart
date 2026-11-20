import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/settings.dart';
import '../logic/stats.dart';

/// Local, offline persistence (SharedPreferences). All methods are defensive:
/// a storage problem never crashes the app; the app simply behaves as if
/// nothing was stored.
class AppStorage {
  AppStorage(this._prefs);

  /// Null when SharedPreferences could not be opened (storage unavailable).
  final SharedPreferences? _prefs;

  static const String _kSettings = 'settings_v1';
  static const String _kHistory = 'history_v1';
  static const String _kRecent = 'recent_ids_v1';

  bool get isAvailable => _prefs != null;

  static Future<AppStorage> open() async {
    try {
      return AppStorage(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('AppStorage: could not open preferences: $e');
      return AppStorage(null);
    }
  }

  AppSettings loadSettings() {
    try {
      final String? raw = _prefs?.getString(_kSettings);
      if (raw != null) {
        final dynamic json = jsonDecode(raw);
        if (json is Map<String, dynamic>) return AppSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('AppStorage: bad settings, using defaults: $e');
    }
    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) =>
      _write(_kSettings, jsonEncode(settings.toJson()));

  Map<String, DayStats> loadHistory() {
    final Map<String, DayStats> out = <String, DayStats>{};
    try {
      final String? raw = _prefs?.getString(_kHistory);
      if (raw != null) {
        final dynamic json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          json.forEach((String key, dynamic value) {
            if (value is Map<String, dynamic>) {
              out[key] = DayStats.fromJson(value);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('AppStorage: bad history, starting empty: $e');
    }
    return out;
  }

  Future<void> saveHistory(Map<String, DayStats> history) {
    final Map<String, dynamic> json = <String, dynamic>{
      for (final MapEntry<String, DayStats> e in history.entries) e.key: e.value.toJson(),
    };
    return _write(_kHistory, jsonEncode(json));
  }

  List<int> loadRecent() {
    try {
      final String? raw = _prefs?.getString(_kRecent);
      if (raw != null) {
        final dynamic json = jsonDecode(raw);
        if (json is List<dynamic>) {
          return <int>[
            for (final dynamic v in json)
              if (v is int) v,
          ];
        }
      }
    } catch (e) {
      debugPrint('AppStorage: bad recent list, ignoring: $e');
    }
    return <int>[];
  }

  Future<void> saveRecent(List<int> ids) => _write(_kRecent, jsonEncode(ids));

  Future<void> _write(String key, String value) async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('AppStorage: write failed for $key: $e');
    }
  }
}
