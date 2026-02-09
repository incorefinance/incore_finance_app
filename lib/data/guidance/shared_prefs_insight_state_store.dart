import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/guidance/insight_id.dart';
import 'insight_state_store.dart';

/// SharedPreferences implementation of [InsightStateStore].
class SharedPrefsInsightStateStore implements InsightStateStore {
  static const _keyPrefix = 'insight_dismissed_until_';

  String _keyFor(InsightId id) => '$_keyPrefix${id.name}';

  @override
  Future<DateTime?> getDismissedUntil(InsightId id) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyFor(id));

    if (stored == null) return null;

    try {
      final dismissedUntil = DateTime.parse(stored);
      // Return null if dismissal has expired
      if (dismissedUntil.isBefore(DateTime.now())) {
        return null;
      }
      return dismissedUntil;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> dismissForDays(InsightId id, int days) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissUntil = DateTime.now().add(Duration(days: days));
    await prefs.setString(_keyFor(id), dismissUntil.toIso8601String());
  }
}
