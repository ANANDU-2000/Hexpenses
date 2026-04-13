import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has finished or skipped the demo onboarding.
abstract final class DemoGetStartedStorage {
  static const _key = 'mf_demo_get_started_completed';

  static Future<bool> hasCompleted() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key) ?? false;
  }

  static Future<void> setCompleted() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
  }
}
