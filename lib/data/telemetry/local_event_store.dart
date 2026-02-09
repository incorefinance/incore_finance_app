import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Append-only local event store backed by SharedPreferences.
///
/// Stores compact JSON events for lightweight action tracking.
/// Capped at [_maxEvents] to prevent unbounded growth.
class LocalEventStore {
  static const String _key = 'local_events_v1';
  static const int _maxEvents = 200;

  /// Appends a timestamped event to the local store.
  Future<void> log(
    String name, {
    Map<String, Object?> props = const {},
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];

    final entry = jsonEncode({
      'name': name,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'props': props,
    });

    existing.add(entry);

    // Trim to last _maxEvents entries
    final trimmed = existing.length > _maxEvents
        ? existing.sublist(existing.length - _maxEvents)
        : existing;

    await prefs.setStringList(_key, trimmed);
  }

  /// Returns all stored events as decoded maps.
  Future<List<Map<String, dynamic>>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_key) ?? [];

    return entries
        .map((e) {
          try {
            return jsonDecode(e) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Removes all stored events.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
